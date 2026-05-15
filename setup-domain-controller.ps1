# Domain controller setup (one-time) for a fresh Windows Server installation

# Creates the Active Directory forest, installs DNS, creates the lynny.local domain and promotes the server to a domain controller
# Do not run this on an existing domain controller

Import-Module ADDSDeployment

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "lynny.local" `
    -DomainNetbiosName "LYNNY" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\Windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\Windows\SYSVOL" `
    -Force:$true