# Read parameters from environment variables to avoid quoting issues
$DomainUser = $env:DOMAIN_USER
$DomainPassword = $env:DOMAIN_PASSWORD
$ComputerName = $env:COMPUTER_NAME
$DomainName = $env:DOMAIN_NAME

if ([string]::IsNullOrEmpty($DomainUser) -or [string]::IsNullOrEmpty($DomainPassword) -or [string]::IsNullOrEmpty($ComputerName) -or [string]::IsNullOrEmpty($DomainName)) {
    Write-Output "ERROR: Required environment variables not set (DOMAIN_USER, DOMAIN_PASSWORD, COMPUTER_NAME, DOMAIN_NAME)"
    exit 1
}

try {
    # Parse domain name to get DC components (e.g., murphyslab.local -> DC=murphyslab,DC=local)
    $dcPath = "DC=" + ($DomainName -replace "\.", ",DC=")

    # Create DirectoryEntry with credentials
    $ldapPath = "LDAP://$DomainName/$dcPath"
    $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapPath, $DomainUser, $DomainPassword)

    # Search for the computer object
    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.SearchRoot = $directoryEntry
    $searcher.Filter = "(&(objectClass=computer)(cn=$ComputerName))"
    $searcher.SearchScope = "Subtree"

    $result = $searcher.FindOne()

    if ($result -ne $null) {
        # Get the computer object's parent container
        $computerObject = $result.GetDirectoryEntry()
        $computerDN = $computerObject.distinguishedName

        # Delete the computer object
        $computerObject.DeleteTree()
        $computerObject.CommitChanges()

        Write-Output "Successfully deleted computer object '$ComputerName' (DN: $computerDN) from Active Directory"
        exit 0
    }
    else {
        Write-Output "Computer object '$ComputerName' not found in Active Directory (may have been already deleted)"
        exit 0
    }
}
catch {
    Write-Output "ERROR: Failed to delete computer object from AD: $_"
    Write-Output "This will cause issues when recreating the server with the same name."
    exit 1
}
