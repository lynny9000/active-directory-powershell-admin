# Create Organisation Units 
# New-ADOrganizationalUnit -Name "Sales" -Path "DC=lynny,DC=local"
# New-ADOrganizationalUnit -Name "HR" -Path "DC=lynny,DC=local"
# New-ADOrganizationalUnit -Name "IT" -Path "DC=lynny,DC=local"

<#
# Create Groups
New-ADGroup `
-Name "Sales-Users" `
-GroupScope Global `
-Path "OU=Sales,DC=lynny,DC=local"

New-ADGroup `
-Name "HR-Users" `
-GroupScope Global `
-Path "OU=HR,DC=lynny,DC=local"

New-ADGroup `
-Name "IT-Users" `
-GroupScope Global `
-Path "OU=IT,DC=lynny,DC=local"
#>

<#
# Onboard three Users, one to each Group
New-ADUser `
-Name "Emiliano Martinez" `
-GivenName "Emiliano" `
-Surname "Martinez" `
-SamAccountName "emartinez" `
-UserPrincipalName "emartinez@lynny.local" `
-Path "OU=Sales,DC=lynny,DC=local" `
-AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
-Enabled $true

Add-ADGroupMember `
-Identity "Sales-Users" `
-Members "emartinez"

New-ADUser `
-Name "Pau Torres" `
-GivenName "Pau" `
-Surname "Torres" `
-SamAccountName "ptorres" `
-UserPrincipalName "ptorres@lynny.local" `
-Path "OU=HR-Users",DC=lynny,DC=local" `
-AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
-Enabled $true

Add-ADGroupMember `
-Identity "HR-Users" `
-Members "ptorres"

New-ADUser `
-Name "John McGinn" `
-GivenName "John" `
-Surname "McGinn" `
-SamAccountName "jmcginn" `
-UserPrincipalName "jmcginn@lynny.local" `
-Path "OU=IT,DC=lynny,DC=local" `
-AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
-Enabled $true

Add-ADGroupMember `
-Identity "IT-Users" `
-Members "jmcginn"
#>

<#
#Offboard User/s to the Offboarded User Group
New-ADOrganizationalUnit `
Name "Offboarded Users" `
Path "DC=lynny,DC=local"

Disable-ADAccount `
-Identity "emartinez"

Move-ADObject `
-Identity (Get-ADUser "emartinez").DistinguishedName `
-TargetPath "OU=Offboarded Users,DC=lynny,DC=local"
#>


<#
#Bulk Onboarding Usersfrom a CSV file

# Loop through each user record in the CSV file
$users = Import-Csv "C:\Scripts\users.csv"

# Generate username using first initial + surname
foreach ($user in $users) {

    $username = (
        $user.FirstName.Substring(0,1) +
        $user.LastName
    ).ToLower()

    # Create full display name
    $fullname = "$($user.FirstName) $($user.LastName)"

    # Create new Active Directory user account
    New-ADUser `
    -Name $fullname `
    -GivenName $user.FirstName `
    -Surname $user.LastName `
    -SamAccountName $username `
    -UserPrincipalName "$username@lynny.local" `
    -Path $user.OU `
    -AccountPassword (ConvertTo-SecureString "Password123!" -AsPlainText -Force) `
    -Enabled $true

    # Add the new user to the correct departmental security group
    Add-ADGroupMember `
    -Identity $user.Group `
    -Members $username
}#>

<#
# User password issues

# Reset the user's password to a temporary password
Set-ADAccountPassword `
-Identity "owatkins" `
-NewPassword (ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force) `
-Reset

# Unlock the account if it has been locked due to failed login attempts
Unlock-ADAccount `
-Identity "owatkins"

# Force the user to change their password the next time they log in
Set-ADUser `
-Identity "owatkins" `
-ChangePasswordAtLogon $true

# Checks if user exists, account enbabled, account locked and password last set status
Get-ADUser owatkins -Properties Enabled,LockedOut,PasswordLastSet
#>

#Exports Active Directory user fields for account review and basic auditing
<#
Get-ADUser `
-Filter * `
-Properties Enabled,Department,Title,UserPrincipalName,LastLogonDate,PasswordLastSet,PasswordExpired,LockedOut,WhenCreated `
# The pipeline | passes AD user objects into Select-Object
# Select-Object chooses which fields are included in the report
| Select-Object `
    Name,
    SamAccountName,
    UserPrincipalName,
    Enabled,
    Department,
    Title,
    LastLogonDate,
    PasswordLastSet,
    PasswordExpired,
    LockedOut,
    WhenCreated,
    DistinguishedName `
| Export-Csv `
"C:\Scripts\ad-user-report.csv" `
-NoTypeInformation
#>

<#
# Exports members of key department AD groups to a CSV file for access review
# AD groups to use in the report
$groups = @(
    "Sales-Users",
    "HR-Users",
    "IT-Users"
)
# Loops through each group in the list
$report = foreach ($group in $groups) {

    Get-ADGroupMember -Identity $group | ForEach-Object {

        # For each group member retrieve full AD user details
        Get-ADUser $_.SamAccountName -Properties Department,Title,Enabled | Select-Object `
        
        # Creates custom column called GroupName, so each row lists group user came from
        @{Name="GroupName";Expression={$group}},
        Name,
        SamAccountName,
        Department,
        Title,
        Enabled
    }
}

$report | Export-Csv `
"C:\Scripts\ad-group-membership-report.csv" `
-NoTypeInformation
#>

<#
# Group policy configurations 

# Creates a workstation OU to store domain-joined PCs to restrict polices on those PC's such as block USB access
New-ADOrganizationalUnit `
    -Name "Workstations" `
    -Path "DC=lynny,DC=local"

# PC based policy linked to the Workstations OU so it applies to PC's, not individual users
New-GPO `
    -Name "Workstations - Block USB Storage"

New-GPLink `
    -Name "Workstations - Block USB Storage" `
    -Target "OU=Workstations,DC=lynny,DC=local"

# This registry policy setting blocks USB's
# HKLM means the policy applies at PC level
Set-GPRegistryValue `
    -Name "Workstations - Block USB Storage" `
    -Key "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" `
    -ValueName "Deny_All" `
    -Type DWord `
    -Value 1

# Moves PC's into the Workstations OU. Excludes domain controllers so server objects are not moved accidentally
Get-ADComputer `
    -Filter * `
| Where-Object {
    $_.DistinguishedName -notlike "*OU=Domain Controllers*"
} `
| ForEach-Object {
    Move-ADObject `
        -Identity $_.DistinguishedName `
        -TargetPath "OU=Workstations,DC=lynny,DC=local"
}

# Creates a user-based GPO that blocks access to Control Panel and PC Settings. The GPO is linked to Sales and HR only, so IT users are excluded
New-GPO `
    -Name "Non-IT Users - Disable Control Panel"

#GPLink attaches the policy to the OU
New-GPLink `
    -Name "Non-IT Users - Disable Control Panel" `
    -Target "OU=Sales,DC=lynny,DC=local"

New-GPLink `
    -Name "Non-IT Users - Disable Control Panel" `
    -Target "OU=HR,DC=lynny,DC=local"

# HKCU means this setting applies to users
Set-GPRegistryValue `
    -Name "Non-IT Users - Disable Control Panel" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" `
    -Type DWord `
    -Value 1
#>

<#
# Creates shared folders and assign access using AD security groups
New-Item -Path "C:\Shares" -ItemType Directory -Force
New-Item -Path "C:\Shares\Sales" -ItemType Directory -Force
New-Item -Path "C:\Shares\HR" -ItemType Directory -Force
New-Item -Path "C:\Shares\IT" -ItemType Directory -Force

# Creates an SMB network share so users can access the folder over the network
New-SmbShare `
    -Name "Sales" `
    -Path "C:\Shares\Sales" `
    -FullAccess "LYNNY\Domain Admins" `
    -ChangeAccess "LYNNY\Sales-Users"

New-SmbShare `
    -Name "HR" `
    -Path "C:\Shares\HR" `
    -FullAccess "LYNNY\Domain Admins" `
    -ChangeAccess "LYNNY\HR-Users"

New-SmbShare `
    -Name "IT" `
    -Path "C:\Shares\IT" `
    -FullAccess "LYNNY\Domain Admins" `
    -ChangeAccess "LYNNY\IT-Users"
#>

<#
# Creates GPOs for departmental mapped drives

# New-GPO creates a new group policy object
New-GPO `
    -Name "Sales - Map Department Drive"

# New-GPLink links the GPO to an OU so it applies to users or computers in that OU
New-GPLink `
    -Name "Sales - Map Department Drive" `
    -Target "OU=Sales,DC=lynny,DC=local"

New-GPO `
    -Name "HR - Map Department Drive"

New-GPLink `
    -Name "HR - Map Department Drive" `
    -Target "OU=HR,DC=lynny,DC=local"

New-GPO `
    -Name "IT - Map Department Drive"

New-GPLink `
    -Name "IT - Map Department Drive" `
    -Target "OU=IT,DC=lynny,DC=local"
#>

<#
# NTFS folder permissions. Sets folder-level permissions so only the correct department group can access each folder

# Disable inherited permissions on each department folder
icacls "C:\Shares\Sales" /inheritance:r
icacls "C:\Shares\HR" /inheritance:r
icacls "C:\Shares\IT" /inheritance:r

# Grant full control to Domain Admins
icacls "C:\Shares\Sales" /grant "LYNNY\Domain Admins:(OI)(CI)F"
icacls "C:\Shares\HR" /grant "LYNNY\Domain Admins:(OI)(CI)F"
icacls "C:\Shares\IT" /grant "LYNNY\Domain Admins:(OI)(CI)F"

# Grant modify access to the correct department group only
icacls "C:\Shares\Sales" /grant "LYNNY\Sales-Users:(OI)(CI)M"
icacls "C:\Shares\HR" /grant "LYNNY\HR-Users:(OI)(CI)M"
icacls "C:\Shares\IT" /grant "LYNNY\IT-Users:(OI)(CI)M"
#>
