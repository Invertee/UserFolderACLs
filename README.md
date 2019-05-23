#### User Folder ACL Script

Fixes permissions on user data folders on file servers and adds permissions to folders with corresponding usernames from AD. By default it also adds permissions for the SYSTEM, Domain Admins and Administrator group, but can also add additional groups if required. Can also folders containing roaming profile folders (with the .v2-v6 suffix. )

On completion it will generate a HTML report in the same folder detailing any error.

##### Install (Requires PowerShellGet)

> Install-Script -Name UserFolderACLs

#### Usage

For best results, run from an admin powershell session:

```>
PS C:\users\admin> UserFolderACLs.ps1 -Folder "E:\UserData\Staff\" -AdditionalDomainGroups "File Administrators","IT Managers"
WARNING: You are about to change permissions on 16 folders, continue?

Confirm
Continue with this operation?
[Y] Yes  [A] Yes to All  [H] Halt Command  [S] Suspend  [?] Help (default is "Y"): y

amber permissions complete. 4 files proccessed.
craig permissions complete. 5 files proccessed.
dennis permissions complete. 8 files proccessed.
Setting permissions for folder: lee
```

Any issues applying permissions will show up in a log file with the file you're applying permissions to.

#### Options
* -AdditionalDomainGroups "Group1","Group2"
* -DontAddAdmins  - Don't add admin groups.
* -DontDisableInheritance - Leaves folder inheritance enabled.
* -DontRemoveCurrentACLs  - Only adds new ACLs, doesn't remove old ones.
* -DontChangeOwner - Doesn't set folder owner to the folder username.