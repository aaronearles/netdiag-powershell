function Format-NetDiagResponse {
    <#
    .SYNOPSIS
    Formats NetDiag API responses as PowerShell objects.

    .DESCRIPTION
    Converts the JSON response from NetDiag API into properly typed PowerShell objects
    with appropriate property names and formatting.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Response,

        [Parameter(Mandatory)]
        [string]$Tool
    )

    if (-not $Response.success) {
        Write-Error "NetDiag $Tool query failed: $($Response.error)"
        return
    }

    switch ($Tool) {
        'whois' {
            # Detect if this is a filtered response (few fields = fields parameter was used)
            $IsFiltered = $Response.parsed.PSObject.Properties.Count -lt 10

            if ($IsFiltered) {
                # For filtered responses, provide direct property access to each field
                $Output = [PSCustomObject]@{
                    PSTypeName = 'NetDiag.Whois.Filtered'
                    Target     = $Response.target
                    Cached     = $Response.cached
                    Timestamp  = [DateTime]$Response.timestamp
                }

                # Add each parsed field as a top-level property for easy access
                foreach ($prop in $Response.parsed.PSObject.Properties) {
                    $Output | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value -Force
                }

                return $Output
            }
            else {
                # Full response includes everything
                [PSCustomObject]@{
                    PSTypeName  = 'NetDiag.Whois'
                    Target      = $Response.target
                    Parsed      = $Response.parsed
                    Raw         = $Response.raw
                    Cached      = $Response.cached
                    Timestamp   = [DateTime]$Response.timestamp
                }
            }
        }
        'dns' {
            [PSCustomObject]@{
                PSTypeName   = 'NetDiag.DNS'
                Hostname     = $Response.hostname
                Type         = $Response.type
                Records      = $Response.records
                RecordCount  = if ($Response.records) { $Response.records.Count } else { 0 }
                QueryTimeMs  = $Response.query_time_ms
                Cached       = $Response.cached
                Timestamp    = [DateTime]$Response.timestamp
            }
        }
        'ping' {
            [PSCustomObject]@{
                PSTypeName        = 'NetDiag.Ping'
                Target            = $Response.target
                PacketsSent       = $Response.packets_sent
                PacketsReceived   = $Response.packets_received
                PacketLossPercent = $Response.packet_loss_percent
                DurationMs        = $Response.time_ms
                RTT               = [PSCustomObject]@{
                    MinMs    = $Response.rtt.min
                    AvgMs    = $Response.rtt.avg
                    MaxMs    = $Response.rtt.max
                    StdDevMs = $Response.rtt.stddev
                }
                ResolvedIP        = $Response.resolved_ip
                Cached            = $Response.cached
                Timestamp         = [DateTime]$Response.timestamp
            }
        }
        'port' {
            [PSCustomObject]@{
                PSTypeName     = 'NetDiag.Port'
                Host           = $Response.host
                Port           = $Response.port
                Open           = $Response.open
                ResolvedIP     = $Response.resolved_ip
                ResponseTimeMs = $Response.response_time_ms
                Cached         = $Response.cached
                Timestamp      = [DateTime]$Response.timestamp
            }
        }
        'ssl' {
            # Convert certificate object to proper PowerShell object
            $Cert = $Response.certificate

            # Build Subject object with available properties
            $SubjectProps = @{}
            if ($Cert.subject.common_name) { $SubjectProps.CommonName = $Cert.subject.common_name }
            if ($Cert.subject.organization) { $SubjectProps.Organization = $Cert.subject.organization }
            if ($Cert.subject.country) { $SubjectProps.Country = $Cert.subject.country }

            # Build Issuer object with available properties
            $IssuerProps = @{}
            if ($Cert.issuer.common_name) { $IssuerProps.CommonName = $Cert.issuer.common_name }
            if ($Cert.issuer.organization) { $IssuerProps.Organization = $Cert.issuer.organization }
            if ($Cert.issuer.country) { $IssuerProps.Country = $Cert.issuer.country }

            # Build Key object
            $KeyProps = @{}
            if ($Cert.key.algorithm) { $KeyProps.Algorithm = $Cert.key.algorithm }
            if ($Cert.key.size) { $KeyProps.Size = $Cert.key.size }

            [PSCustomObject]@{
                PSTypeName  = 'NetDiag.SSL'
                Hostname    = $Response.hostname
                Port        = $Response.port
                Certificate = [PSCustomObject]@{
                    Subject = [PSCustomObject]$SubjectProps
                    Issuer  = [PSCustomObject]$IssuerProps
                    Validity = [PSCustomObject]@{
                        NotBefore     = if ($Cert.validity.not_before) { [DateTime]$Cert.validity.not_before } else { $null }
                        NotAfter      = if ($Cert.validity.not_after) { [DateTime]$Cert.validity.not_after } else { $null }
                        DaysRemaining = $Cert.validity.days_remaining
                        Expired       = $Cert.validity.expired
                        Valid         = $Cert.validity.valid
                    }
                    SubjectAltNames    = $Cert.subject_alt_names
                    Key                = [PSCustomObject]$KeyProps
                    SignatureAlgorithm = $Cert.signature_algorithm
                    SerialNumber       = $Cert.serial_number
                    Version            = $Cert.version
                    SelfSigned         = $Cert.self_signed
                }
                Warnings    = $Response.warnings
                ChainValid  = $Response.chain_valid
                Cached      = $Response.cached
                Timestamp   = [DateTime]$Response.timestamp
            }
        }
    }
}
