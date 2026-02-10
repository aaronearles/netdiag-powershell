# Testing the NetDiag PowerShell Module

This guide helps you test the NetDiag PowerShell module locally.

## Prerequisites

1. **NetDiag Server Running**: Ensure the netdiag-server is running and accessible
   ```bash
   # From netdiag-server directory
   docker compose up -d

   # Verify it's running
   curl http://dockerint01:3000/health
   # or
   curl http://localhost:3000/health
   ```

2. **PowerShell 5.1+**: Check your version
   ```powershell
   $PSVersionTable.PSVersion
   ```

## Quick Start Testing

### 1. Import the Module

From the netdiag-powershell directory:

```powershell
# Import the module
Import-Module .\NetDiag.psd1 -Force -Verbose

# Verify it loaded
Get-Module NetDiag

# Check available commands
Get-Command -Module NetDiag
```

Expected output:
```
CommandType     Name                Version    Source
-----------     ----                -------    ------
Function        Get-NetDiagServer   1.0.0      NetDiag
Function        Invoke-NetDiag      1.0.0      NetDiag
Function        Set-NetDiagServer   1.0.0      NetDiag
```

### 2. Configure Server URL

```powershell
# If testing locally
Set-NetDiagServer -Url "http://localhost:3000"

# If testing against dockerint01
Set-NetDiagServer -Url "http://dockerint01:3000"

# Verify configuration
Get-NetDiagServer
```

### 3. Test Each Tool

#### Whois Tests

```powershell
# Test IPv4 lookup
netdiag whois -Target 8.8.8.8

# Test domain lookup
netdiag whois -Target google.com

# Test with field filtering
netdiag whois -Target 8.8.8.8 -Fields NetRange,Organization,Country

# Test IPv6
netdiag whois -Target 2001:4860:4860::8888

# Test ASN
netdiag whois -Target AS15169

# Test JSON output
netdiag whois -Target 8.8.8.8 -AsJson
```

#### DNS Tests

```powershell
# Test A record
netdiag dns -Hostname google.com

# Test other record types
netdiag dns -Hostname google.com -Type AAAA
netdiag dns -Hostname google.com -Type MX
netdiag dns -Hostname google.com -Type TXT
netdiag dns -Hostname google.com -Type NS

# Test with verbose
netdiag dns -Hostname google.com -Verbose
```

#### Ping Tests

```powershell
# Test basic ping
netdiag ping -PingTarget 8.8.8.8

# Test with custom count
netdiag ping -PingTarget 8.8.8.8 -Count 10

# Test with hostname
netdiag ping -PingTarget google.com -Count 5

# Check RTT stats
$Result = netdiag ping -PingTarget 8.8.8.8
$Result.RTT
```

#### Port Tests

```powershell
# Test open port
netdiag port -Host google.com -Port 443

# Test another port
netdiag port -Host google.com -Port 80

# Test closed port (should show Open: False)
netdiag port -Host google.com -Port 9999

# Check response time
$Result = netdiag port -Host google.com -Port 443
$Result.ResponseTimeMs
```

#### SSL Tests

```powershell
# Test SSL certificate
netdiag ssl -SSLHostname google.com

# Check certificate details
$Result = netdiag ssl -SSLHostname google.com
$Result.Certificate.Subject
$Result.Certificate.Issuer
$Result.Certificate.Validity

# Test custom port
netdiag ssl -SSLHostname example.com -SSLPort 8443
```

### 4. Test PowerShell Pipeline

```powershell
# Test multiple hosts
@('google.com', 'github.com', 'microsoft.com') | ForEach-Object {
    Write-Host "Testing: $_" -ForegroundColor Cyan
    netdiag dns -Hostname $_
}

# Check multiple ports
@(443, 80, 22) | ForEach-Object {
    $Result = netdiag port -Host google.com -Port $_
    [PSCustomObject]@{
        Port = $_.Port
        Open = $Result.Open
        ResponseTime = $Result.ResponseTimeMs
    }
}

# Filter results
$Ping1 = netdiag ping -PingTarget 8.8.8.8 -Count 4
$Ping2 = netdiag ping -PingTarget 1.1.1.1 -Count 4

@($Ping1, $Ping2) | Where-Object { $_.PacketLossPercent -eq 0 } |
    Select-Object Target, PacketsReceived, @{N='AvgRTT';E={$_.RTT.AvgMs}}
```

### 5. Test Error Handling

```powershell
# Test invalid target
netdiag whois -Target "invalid!@#$"

# Test invalid DNS record type (should fail validation)
# This will error at parameter validation level
# netdiag dns -Hostname google.com -Type INVALID

# Test unreachable host
netdiag port -Host 192.0.2.1 -Port 80

# Test with verbose to see errors
$VerbosePreference = 'Continue'
netdiag whois -Target invalid-host
$VerbosePreference = 'SilentlyContinue'
```

## Automated Test Script

Save this as `Test-NetDiag.ps1`:

```powershell
# Test-NetDiag.ps1
# Automated test script for NetDiag module

param(
    [string]$ServerUrl = "http://localhost:3000"
)

# Import module
Import-Module .\NetDiag.psd1 -Force

# Configure server
Set-NetDiagServer -Url $ServerUrl

Write-Host "`n=== Testing NetDiag Module ===" -ForegroundColor Green

# Test 1: Whois
Write-Host "`n[TEST] Whois lookup..." -ForegroundColor Cyan
$Whois = netdiag whois -Target 8.8.8.8
if ($Whois.Target -eq "8.8.8.8") {
    Write-Host "✓ Whois test passed" -ForegroundColor Green
} else {
    Write-Host "✗ Whois test failed" -ForegroundColor Red
}

# Test 2: DNS
Write-Host "`n[TEST] DNS lookup..." -ForegroundColor Cyan
$DNS = netdiag dns -Hostname google.com -Type A
if ($DNS.Records.Count -gt 0) {
    Write-Host "✓ DNS test passed" -ForegroundColor Green
} else {
    Write-Host "✗ DNS test failed" -ForegroundColor Red
}

# Test 3: Ping
Write-Host "`n[TEST] Ping test..." -ForegroundColor Cyan
$Ping = netdiag ping -PingTarget 8.8.8.8 -Count 4
if ($Ping.PacketsSent -eq 4) {
    Write-Host "✓ Ping test passed" -ForegroundColor Green
} else {
    Write-Host "✗ Ping test failed" -ForegroundColor Red
}

# Test 4: Port
Write-Host "`n[TEST] Port check..." -ForegroundColor Cyan
$Port = netdiag port -Host google.com -Port 443
if ($Port.Port -eq 443) {
    Write-Host "✓ Port test passed (Open: $($Port.Open))" -ForegroundColor Green
} else {
    Write-Host "✗ Port test failed" -ForegroundColor Red
}

# Test 5: SSL
Write-Host "`n[TEST] SSL certificate..." -ForegroundColor Cyan
$SSL = netdiag ssl -SSLHostname google.com
if ($SSL.Certificate.Subject) {
    Write-Host "✓ SSL test passed" -ForegroundColor Green
    Write-Host "  Certificate: $($SSL.Certificate.Subject.common_name)" -ForegroundColor Gray
    Write-Host "  Valid until: $($SSL.Certificate.Validity.NotAfter)" -ForegroundColor Gray
} else {
    Write-Host "✗ SSL test failed" -ForegroundColor Red
}

Write-Host "`n=== All tests complete ===" -ForegroundColor Green
```

Run it:
```powershell
.\Test-NetDiag.ps1
```

## Troubleshooting

### Module Not Loading

```powershell
# Check if files exist
Get-ChildItem -Recurse

# Try importing with verbose
Import-Module .\NetDiag.psd1 -Force -Verbose

# Check for syntax errors
Test-ModuleManifest .\NetDiag.psd1
```

### Connection Errors

```powershell
# Test server connectivity
Test-NetConnection dockerint01 -Port 3000

# Check server configuration
Get-NetDiagServer

# Test with curl
curl http://dockerint01:3000/health
```

### Get Detailed Errors

```powershell
# Enable verbose output
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Continue'

# Run command
netdiag whois -Target 8.8.8.8

# Reset preferences
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'
```

## Expected Results

All tests should return:
- `success: true` in the API response
- Proper PowerShell objects with type names (NetDiag.Whois, NetDiag.DNS, etc.)
- `Cached: False` on first run, `Cached: True` on subsequent identical queries
- Timestamps in local time
- Proper error messages for invalid inputs

## Next Steps

Once all tests pass:
1. Push to GitHub repository
2. Document any environment-specific issues
3. Create installation guide for corporate environment
4. Consider adding Pester tests for CI/CD
