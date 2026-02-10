@{
    # Script module or binary module file associated with this manifest
    RootModule = 'NetDiag.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'a3d8f9c2-4b7e-4a1c-9f8d-2e5b6c7a9d4e'

    # Author of this module
    Author = 'Aaron Earles'

    # Company or vendor of this module
    CompanyName = ''

    # Copyright statement for this module
    Copyright = '(c) 2026. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell client for the NetDiag network diagnostic tools API. Provides access to whois, DNS, ping, port check, and SSL certificate inspection tools.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Invoke-NetDiag',
        'Set-NetDiagServer',
        'Get-NetDiagServer'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @('netdiag')

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Network', 'Diagnostics', 'Whois', 'DNS', 'Ping', 'SSL', 'Port')

            # A URL to the license for this module
            LicenseUri = ''

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/aaronearles/netdiag-powershell'

            # ReleaseNotes of this module
            ReleaseNotes = @'
# Version 1.0.0

Initial release:
- Invoke-NetDiag cmdlet with support for 5 diagnostic tools
  - whois: IP, domain, ASN lookups
  - dns: DNS record queries (A, AAAA, MX, TXT, NS, CNAME, SOA, ANY)
  - ping: ICMP ping with RTT statistics
  - port: TCP port connectivity checks
  - ssl: SSL/TLS certificate inspection
- Set-NetDiagServer and Get-NetDiagServer for configuration
- Multiple configuration sources (environment variable, config file, session variable)
- PowerShell 5.1+ compatible
'@
        }
    }
}
