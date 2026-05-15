# Active Directory PowerShell Admin

A Windows Server Active Directory runbook that uses PowerShell to complete common sysadmin tasks

## Features

* Creates Active Directory Organisational Units
* Creates departmental security groups
* Onboards users manually
* Onboards users from a CSV file
* Adds users to department groups
* Offboards users by disabling accounts and moving them to an offboarded OU
* Resets passwords and unlocks accounts
* Exports Active Directory user reports
* Exports group membership reports
* Creates Group Policy Objects
* Links GPOs to department and workstation OUs
* Blocks USB storage access on workstation computers
* Blocks Control Panel access for non-IT users
* Creates departmental SMB file shares
* Applies share permissions using AD security groups
* Applies NTFS folder permissions using `icacls`
* Creates GPO placeholders for mapped department drives

## How it works

The script is written as a PowerShell runbook for a small Active Directory domain with three departments

* Sales
* HR
* IT

Each department has

* An Organisational Unit
* A security group
* Test user accounts
* A departmental file share
* A mapped drive GPO design

The script demonstrates how common Active Directory administration tasks can be automated with PowerShell

## Files

* `setup-domain-controller.ps1` - one-time setup script used to create the AD forest, install DNS and promote the server to a domain controller
* `ad-admin-runbook.ps1` - main runbook containing common Active Directory administration tasks
* `users.csv` - sample CSV file used for bulk user onboarding

## Notes

* Built for a Windows Server Active Directory lab
* Uses the Active Directory PowerShell module
* Uses the Group Policy PowerShell module
* Uses SMB shares for network folder access
* Uses `icacls` for NTFS permissions
* Designed for learning sysadmin and helpdesk-style AD administration
* Sections are commented out so they can be run individually
* Lab passwords are examples only and should not be used in production
