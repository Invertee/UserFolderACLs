#### User Folder ACL Script

Fixes permissions on user data folders on file servers and adds permissions to folders with corresponding usernames from AD. By default it also adds permissions for the SYSTEM, Domain Admins and Administrator group, but can also add additional groups if required. 

##### Install (Requires PowerShellGet)

> Install-Script -Name UserFolderACLs

#### Usage

For best results, run from an admin powershell session:

```>PS C:\windows\system32> UserFolderACLs -Folder "E:\Users\" -AdditionalDomainGroups "IT Managers","File Administrators"

WARNING: You are about to change permissions on 19 folders, continue?  
Setting permissions on adam. 251 Items...  
Setting permissions on beverly. 488 Items...    
Setting permissions on dee. 937 Items...
```

Any issues applying permissions will show up in a log file with the file you're applying permissions to.

#### Options
* -AdditionalDomainGroups "Group1","Group2"
* -DontAddAdmins  - Don't add admin groups.
* -DontDisableInheritance - Leaves folder inheritance enabled.
* -DontRemoveCurrentACLs  - Only adds new ACLs, doesn't remove old ones.
* -DontChangeOwner - Doesn't set folder owner to the folder username.