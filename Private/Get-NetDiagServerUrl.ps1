function Get-NetDiagServerUrl {
    <#
    .SYNOPSIS
    Gets the NetDiag server URL from configuration.

    .DESCRIPTION
    Checks for server URL in this order:
    1. $env:NETDIAG_SERVER environment variable
    2. Config file at ~/.netdiag/config.json
    3. Module-level variable set by Set-NetDiagServer
    4. Default: http://dockerint01:3000
    #>
    [CmdletBinding()]
    param()

    # Check environment variable first
    if ($env:NETDIAG_SERVER) {
        Write-Verbose "Using server URL from environment variable: $env:NETDIAG_SERVER"
        return $env:NETDIAG_SERVER.TrimEnd('/')
    }

    # Check config file
    $ConfigPath = Join-Path $env:USERPROFILE '.netdiag\config.json'
    if (Test-Path $ConfigPath) {
        try {
            $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            if ($Config.ServerUrl) {
                Write-Verbose "Using server URL from config file: $($Config.ServerUrl)"
                return $Config.ServerUrl.TrimEnd('/')
            }
        }
        catch {
            Write-Warning "Failed to read config file at $ConfigPath: $_"
        }
    }

    # Check module-level variable
    if ($script:NetDiagServer) {
        Write-Verbose "Using server URL from module variable: $script:NetDiagServer"
        return $script:NetDiagServer.TrimEnd('/')
    }

    # Use default
    Write-Verbose "Using default server URL: $script:DefaultServer"
    return $script:DefaultServer
}
