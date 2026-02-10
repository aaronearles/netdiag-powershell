function Get-NetDiagServer {
    <#
    .SYNOPSIS
    Gets the current NetDiag server URL.

    .DESCRIPTION
    Displays the currently configured NetDiag server URL and the source of the configuration
    (environment variable, config file, module variable, or default).

    .EXAMPLE
    Get-NetDiagServer
    #>
    [CmdletBinding()]
    param()

    $ServerUrl = Get-NetDiagServerUrl
    $Source = 'Default'

    if ($env:NETDIAG_SERVER) {
        $Source = 'Environment Variable'
    }
    elseif (Test-Path (Join-Path $env:USERPROFILE '.netdiag\config.json')) {
        $Source = 'Config File'
    }
    elseif ($script:NetDiagServer) {
        $Source = 'Module Variable (Session)'
    }

    [PSCustomObject]@{
        ServerUrl = $ServerUrl
        Source    = $Source
    }
}
