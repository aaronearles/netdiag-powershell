function Invoke-NetDiag {
    <#
    .SYNOPSIS
    Invoke network diagnostic tools via the NetDiag HTTP API.

    .DESCRIPTION
    Provides access to network diagnostic tools (whois, DNS, ping, port check, SSL certificate)
    through a unified command-line interface. The tool parameter specifies which diagnostic to run.

    .PARAMETER Tool
    The diagnostic tool to run: whois, dns, ping, port, or ssl

    .PARAMETER Target
    Target IP address, hostname, or domain for whois/ping operations

    .PARAMETER Fields
    Specific fields to return from whois lookup (comma-separated)

    .PARAMETER Hostname
    Hostname for DNS or SSL certificate lookups

    .PARAMETER Type
    DNS record type (A, AAAA, MX, TXT, NS, CNAME, SOA, ANY)

    .PARAMETER Host
    Host for port connectivity check

    .PARAMETER Port
    Port number to check (1-65535)

    .PARAMETER Count
    Number of ping packets to send (1-10, default: 4)

    .PARAMETER SSLPort
    Port for SSL certificate check (default: 443)

    .PARAMETER AsJson
    Return raw JSON response instead of PowerShell objects

    .EXAMPLE
    Invoke-NetDiag whois -Target 8.8.8.8

    .EXAMPLE
    netdiag dns -Hostname google.com -Type MX

    .EXAMPLE
    netdiag ping -Target 8.8.8.8 -Count 4

    .EXAMPLE
    netdiag port -Host google.com -Port 443

    .EXAMPLE
    netdiag ssl -Hostname google.com
    #>
    [CmdletBinding(DefaultParameterSetName = 'Whois')]
    [Alias('netdiag')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateSet('whois', 'dns', 'ping', 'port', 'ssl')]
        [string]$Tool,

        # Whois parameters
        [Parameter(Mandatory, ParameterSetName = 'Whois', Position = 1)]
        [string]$Target,

        [Parameter(ParameterSetName = 'Whois')]
        [string[]]$Fields,

        # DNS parameters
        [Parameter(Mandatory, ParameterSetName = 'DNS')]
        [string]$Hostname,

        [Parameter(ParameterSetName = 'DNS')]
        [ValidateSet('A', 'AAAA', 'MX', 'TXT', 'NS', 'CNAME', 'SOA', 'ANY')]
        [string]$Type = 'A',

        # Ping parameters
        [Parameter(Mandatory, ParameterSetName = 'Ping')]
        [string]$PingTarget,

        [Parameter(ParameterSetName = 'Ping')]
        [ValidateRange(1, 10)]
        [int]$Count = 4,

        # Port parameters
        [Parameter(Mandatory, ParameterSetName = 'Port')]
        [string]$Host,

        [Parameter(Mandatory, ParameterSetName = 'Port')]
        [ValidateRange(1, 65535)]
        [int]$Port,

        # SSL parameters
        [Parameter(Mandatory, ParameterSetName = 'SSL')]
        [string]$SSLHostname,

        [Parameter(ParameterSetName = 'SSL')]
        [ValidateRange(1, 65535)]
        [int]$SSLPort = 443,

        # Common parameters
        [Parameter()]
        [switch]$AsJson
    )

    # Determine parameter set and build URI/query
    switch ($Tool) {
        'whois' {
            $Uri = "/api/whois/$Target"
            $Query = @{}
            if ($Fields) {
                $Query['fields'] = $Fields -join ','
            }
        }
        'dns' {
            $Uri = "/api/dns/$Hostname"
            $Query = @{ type = $Type }
        }
        'ping' {
            $Uri = "/api/ping/$PingTarget"
            $Query = @{ count = $Count }
        }
        'port' {
            $Uri = "/api/port/$Host/$Port"
            $Query = @{}
        }
        'ssl' {
            $Uri = "/api/ssl/$SSLHostname"
            $Query = @{}
            if ($SSLPort -ne 443) {
                $Query['port'] = $SSLPort
            }
        }
    }

    # Make the request
    $Response = Invoke-NetDiagRequest -Uri $Uri -QueryParameters $Query

    if ($null -eq $Response) {
        return
    }

    # Return raw JSON if requested
    if ($AsJson) {
        return ($Response | ConvertTo-Json -Depth 10)
    }

    # Return formatted PowerShell object
    Format-NetDiagResponse -Response $Response -Tool $Tool
}
