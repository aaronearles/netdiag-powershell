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

    # Helper function to recursively convert hashtables to PSCustomObjects
    function ConvertTo-PSCustomObjectRecursive {
        param([object]$InputObject)

        if ($null -eq $InputObject) {
            return $null
        }

        if ($InputObject -is [System.Collections.IDictionary]) {
            $output = [PSCustomObject]@{}
            foreach ($key in $InputObject.Keys) {
                # Use -Force to handle case-sensitive duplicate keys (country vs Country)
                $output | Add-Member -MemberType NoteProperty -Name $key -Value (ConvertTo-PSCustomObjectRecursive $InputObject[$key]) -Force
            }
            return $output
        }
        elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $output = @()
            foreach ($item in $InputObject) {
                $output += ConvertTo-PSCustomObjectRecursive $item
            }
            return $output
        }
        else {
            return $InputObject
        }
    }

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

        # Manually parse JSON to handle large responses with case-sensitive keys
        # Use -AsHashtable to preserve case (normalized fields like "Country" vs "country")
        if ($WebResponse.Content) {
            $ResponseHash = $WebResponse.Content | ConvertFrom-Json -AsHashtable
        } else {
            $ResponseHash = $WebResponse | ConvertFrom-Json -AsHashtable
        }

        # Recursively convert hashtable to PSCustomObject for better property access
        $Response = ConvertTo-PSCustomObjectRecursive $ResponseHash

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
