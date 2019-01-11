
<#PSScriptInfo

.VERSION 0.1

.GUID 822e92d8-2cbd-4db1-9c78-ccbe1a200acd

.AUTHOR Sam Petch

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 

.DESCRIPTION 
 Sets ACLs on userdata held on a file server with the corresponding user. 

#> 
Param(
    [parameter(Mandatory=$true)] $Folder,
    [parameter()] [array] $AdditionalDomainGroups,
    [parameter()] [switch] $DontAddAdmins,
    [parameter()] [switch] $DontDisableInheritance,   
    [parameter()] [switch] $DontRemoveCurrentACLs,
    [parameter()] [switch] $DontChangeOwner
)

#$ErrorActionPreference = 'Stop'
$Directory = $Folder
$Userfolders = Get-ChildItem $Folder -Directory
$Failed = 0
$Success = 0
$Count = $Userfolders.Count
Write-Warning "You are about to change permissions on $Count folders, continue?" -WarningAction Inquire

Foreach ($Folder in $Userfolders) {
    Write-Host " "
    Write-host "Setting permissions on $Folder... " -NoNewline

    $Username = $env:userdomain + '\' + $Folder.BaseName
    $ACL = Get-ACL $Folder.FullName

    Try {
        if (!($DontChangeOwner)) {
        $ACL.SetOwner([System.Security.Principal.NTAccount]"$Username")
        }

        if (!($DontDisableInheritance)) {
            $ACL.SetAccessRuleProtection($true,$false)
        }

        if (!($DontRemoveCurrentACLs)) {
            $ACL.Access | Foreach-Object { $ACL.RemoveAccessRule($_) | Out-Null}
            Set-ACL $Folder.FullName $ACL -ErrorAction Stop
            $ACL = Get-ACL $Folder.FullName
        }

        if ($AdditionalDomainGroups) {
            Foreach ($Group in $AdditionalDomainGroups) 
            {
                $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:userdomain\$Group","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
                $ACL.SetAccessRule($AccessRule)
            }
        }

        # Adds Permissions for User
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Username,"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
        $ACL.SetAccessRule($AccessRule)

        if (!($DontAddAdmins)) {
            ## Adds Permissions for domain admin group
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:userdomain\Domain Admins","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
            $ACL.SetAccessRule($AccessRule)

            ## Adds Permissions for Administrators group
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
            $ACL.SetAccessRule($AccessRule)
        }

        ## Adds Permissions for system group
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
        $ACL.SetAccessRule($AccessRule)

        Set-ACL $Folder.FullName $ACL -ErrorAction Stop

        $Inner = Get-ChildItem $Folder.FullName -Recurse
        $InnerCount = $Inner.Count
        Write-Host -NoNewline "$InnerCount Items."
        Try {
            Foreach ($InnerItem in $Inner) 
            {
                Set-Acl $InnerItem.FullName $ACL 
            }
            $Success++
        } catch {
            $InnerItem + " - " + $error[0].Exception.Message | Out-File "$Directory\ACLErrors.log" -Append
        }
    } Catch 
    {
        $Failed++
        $Folder.FullName + " - " + $error[0].Exception.Message | Out-File "$Directory\ACLErrors.log" -Append
    }

}
Write-Host ""
Write-Host "Successfull ACLs Modified: $Success"
Write-Host "Failed ACLs Modified: $Failed"


