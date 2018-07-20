
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
    [parameter()] [switch] $AddDomainAdmins,
    [parameter()] [switch] $DisableInheritance,   
    [parameter()] [switch] $RemoveCurrentACLs,
    [parameter(Mandatory=$true)] $Folder
)

$Userfolders = Get-ChildItem $Folder
$Failed = 0
$Success = 0

Foreach ($Folder in $Userfolders) {
    Write-host "Setting permissions on $Folder"

$Username = $env:userdomain + '\' + $Folder.BaseName
$ACL = Get-ACL $Folder.FullName

if ($DisableInheritance) {
    $ACL.SetAccessRuleProtection($true,$true)
}

if ($RemoveCurrentACLs) {
    $ACL.Access | Foreach-Object { $ACL.RemoveAccessRule($_) | out-null}
}

# Adds Permissions for User
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($Username,"FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($AccessRule)

## Adds Permissions for domain admin group
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:userdomain\Domain Admins","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($AccessRule)

## Adds Permissions for system group
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($AccessRule)

## Adds Permissions for Administrators group
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","ContainerInherit, ObjectInherit", "None", "Allow")
$ACL.SetAccessRule($AccessRule)

Try {
Set-ACL $Folder.FullName $ACL -ErrorAction Stop
$Success++
}
Catch {
$Failed++
}


}

Write-Output "Successfull ACLs Modified: $Success"
Write-Output "Failed ACLs Modified: $Failed"


