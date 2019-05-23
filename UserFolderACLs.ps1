
<#PSScriptInfo

.VERSION 0.3

.GUID 822e92d8-2cbd-4db1-9c78-ccbe1a200acd

.AUTHOR Sam Petch

.COMPANYNAME 

.COPYRIGHT 

.TAGS 

.LICENSEURI 

.PROJECTURI https://github.com/Invertee/UserFolderACLs

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
    [parameter()] [array]  $AdditionalDomainGroups,
    [parameter()] [switch] $DontAddAdmins,
    [parameter()] [switch] $DontDisableInheritance,   
    [parameter()] [switch] $DontRemoveCurrentACLs,
    [parameter()] [switch] $DontChangeOwner
)

$key = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name 'LongPathsEnabled' -ErrorAction SilentlyContinue
if (!($key) -or ($key.LongPathsEnabled -eq 0) ) {
    Write-Warning "Support for long file paths is disabled. Consider turning this on:
    https://www.intel.com/content/www/us/en/programmable/support/support-resources/knowledge-base/ip/2018/how-do-i-extend-windows-server-2016-file-path-support-from-260-t.html"
}

#$ErrorActionPreference = 'Stop'
$Directory = $Folder
$Userfolders = Get-ChildItem $Folder -Directory
$results = @()
Write-Warning "You are about to change permissions on $($Userfolders.Count) folders, continue?" -WarningAction Inquire

Foreach ($Folder in $Userfolders) {

    Write-host "`nSetting permissions for folder: $Folder" -NoNewline
    $Failed = 0
    $Success = 0

    $Username = $env:userdomain + '\' + $Folder.BaseName
    if ($Username -match '.v[1-8]') { $Username = $Username -replace '.{3}$' } 
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
        Try {
            Foreach ($InnerItem in $Inner) 
            {
                Set-Acl $InnerItem.FullName $ACL
                $Success++
                Write-host "`r$Folder - Applying files processed $success files" -NoNewline -ForegroundColor Green
            }
            write-host "`r$Folder permissions complete. $success files proccessed." -NoNewline -ForegroundColor Green
        } catch {
            $derror = "$InnerItem - " + $_.Exception.Message  
        }
    } Catch 
    {
        if ($_ -match 'Some or all identity references could not be translated') {
            write-host "`rFolder $Folder failed. - Can't match folder with username" -NoNewline -ForegroundColor red
        }
        if ($_ -match 'privilege which is required for this operation.') {
            write-host "`r Folder $Folder failed. - Access is denied" -NoNewline -ForegroundColor red
        }
        $derror = "$InnerItem - " + $_.Exception.Message  
    }

    $folderResult = [PSCustomObject]@{
        Folder     = $Folder.Fullname
        "Successful Files  " = $Success
        "Errors" = $derror
    }

    $results += $folderResult
}

$results | ConvertTo-Html -CssUri 'https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css' | Out-File -FilePath "$Directory\ACLReport.html"