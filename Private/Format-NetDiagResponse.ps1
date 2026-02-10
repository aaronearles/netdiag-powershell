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
            [PSCustomObject]@{
                PSTypeName  = 'NetDiag.Whois'
                Target      = $Response.target
                Parsed      = $Response.parsed
                Raw         = $Response.raw
                Cached      = $Response.cached
                Timestamp   = [DateTime]$Response.timestamp
            }
        }
        'dns' {
            [PSCustomObject]@{
                PSTypeName   = 'NetDiag.DNS'
                Hostname     = $Response.hostname
                Type         = $Response.type
                Records      = $Response.records
                RecordCount  = $Response.record_count
                Raw          = $Response.raw
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
                DurationMs        = $Response.duration_ms
                RTT               = [PSCustomObject]@{
                    MinMs    = $Response.rtt.min_ms
                    AvgMs    = $Response.rtt.avg_ms
                    MaxMs    = $Response.rtt.max_ms
                    StdDevMs = $Response.rtt.stddev_ms
                }
                Raw               = $Response.raw
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
            [PSCustomObject]@{
                PSTypeName  = 'NetDiag.SSL'
                Hostname    = $Response.hostname
                Port        = $Response.port
                Certificate = [PSCustomObject]@{
                    Subject = [PSCustomObject]$Cert.subject
                    Issuer  = [PSCustomObject]$Cert.issuer
                    Validity = [PSCustomObject]@{
                        NotBefore     = [DateTime]$Cert.validity.not_before
                        NotAfter      = [DateTime]$Cert.validity.not_after
                        DaysRemaining = $Cert.validity.days_remaining
                        Expired       = $Cert.validity.expired
                        Valid         = $Cert.validity.valid
                    }
                    SubjectAltNames     = $Cert.subject_alt_names
                    Key                 = [PSCustomObject]$Cert.key
                    SignatureAlgorithm  = $Cert.signature_algorithm
                    SerialNumber        = $Cert.serial_number
                    Version             = $Cert.version
                    SelfSigned          = $Cert.self_signed
                }
                Warnings    = $Response.warnings
                ChainValid  = $Response.chain_valid
                Cached      = $Response.cached
                Timestamp   = [DateTime]$Response.timestamp
            }
        }
    }
}
