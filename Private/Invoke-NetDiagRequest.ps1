function Invoke-NetDiagRequest {
    <#
    .SYNOPSIS
    Makes an HTTP request to the NetDiag API.

    .DESCRIPTION
    Internal helper function to make requests to the NetDiag API with error handling.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter()]
        [hashtable]$QueryParameters = @{}
    )

    try {
        $ServerUrl = Get-NetDiagServerUrl
        $FullUri = "$ServerUrl$Uri"

        # Add query parameters if provided
        if ($QueryParameters.Count -gt 0) {
            $QueryString = ($QueryParameters.GetEnumerator() | ForEach-Object {
                "$($_.Key)=$([System.Uri]::EscapeDataString($_.Value))"
            }) -join '&'
            $FullUri += "?$QueryString"
        }

        Write-Verbose "Making request to: $FullUri"

        # Make the request (PowerShell 5.1 compatible)
        # Use Invoke-WebRequest and manually parse JSON for reliability with large responses
        $WebResponse = Invoke-WebRequest -Uri $FullUri -Method Get -ErrorAction Stop

        # Manually parse JSON to handle large responses
        if ($WebResponse.Content) {
            $Response = $WebResponse.Content | ConvertFrom-Json
        } else {
            $Response = $WebResponse | ConvertFrom-Json
        }

        return $Response
    }
    catch {
        $ErrorMessage = "Failed to connect to NetDiag server at $ServerUrl"
        if ($_.Exception.Message) {
            $ErrorMessage += ": $($_.Exception.Message)"
        }

        Write-Error $ErrorMessage
        return $null
    }
}
