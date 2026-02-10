function Set-NetDiagServer {
    <#
    .SYNOPSIS
    Sets the NetDiag server URL.

    .DESCRIPTION
    Configures the NetDiag server URL. Can save to a config file for persistence
    across sessions, or set in the current session only.

    .PARAMETER Url
    The base URL of the NetDiag server (e.g., http://dockerint01:3000)

    .PARAMETER Persist
    Save the URL to a config file (~/.netdiag/config.json) for use in future sessions

    .EXAMPLE
    Set-NetDiagServer -Url "http://dockerint01:3000"

    .EXAMPLE
    Set-NetDiagServer -Url "http://localhost:3000" -Persist
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter()]
        [switch]$Persist
    )

    # Validate URL format
    try {
        $Uri = [System.Uri]$Url
        if ($Uri.Scheme -notin @('http', 'https')) {
            throw "URL must use http or https scheme"
        }
    }
    catch {
        Write-Error "Invalid URL: $_"
        return
    }

    # Remove trailing slash
    $Url = $Url.TrimEnd('/')

    # Set in current session
    $script:NetDiagServer = $Url
    Write-Verbose "Set NetDiag server to: $Url"

    # Save to config file if requested
    if ($Persist) {
        $ConfigDir = Join-Path $env:USERPROFILE '.netdiag'
        $ConfigPath = Join-Path $ConfigDir 'config.json'

        try {
            # Create directory if it doesn't exist
            if (-not (Test-Path $ConfigDir)) {
                New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
            }

            # Save config
            $Config = @{ ServerUrl = $Url }
            $Config | ConvertTo-Json | Set-Content -Path $ConfigPath -Force

            Write-Host "NetDiag server URL saved to: $ConfigPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to save config file: $_"
        }
    }
    else {
        Write-Host "NetDiag server set to: $Url (session only)" -ForegroundColor Green
    }
}
