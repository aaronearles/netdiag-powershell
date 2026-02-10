# NetDiag PowerShell Module

PowerShell client for the NetDiag network diagnostic tools API. Provides a unified command-line interface for whois, DNS, ping, port check, and SSL certificate inspection tools.

## Features

- **Unified CLI**: Single `netdiag` command with subcommands for each tool
- **5 Diagnostic Tools**:
  - Whois lookups (IPv4, IPv6, domains, ASN)
  - DNS queries (A, AAAA, MX, TXT, NS, CNAME, SOA, ANY)
  - Ping tests (ICMP with RTT statistics)
  - Port connectivity checks (TCP)
  - SSL certificate inspection
- **Normalized Whois Fields**: Consistent field names across all Regional Internet Registries (ARIN, APNIC, RIPE, etc.)
- **Smart Output Formatting**: Filtered queries return flat structure with direct property access
- **PowerShell Native**: Returns proper PowerShell objects for pipeline operations
- **Flexible Configuration**: Multiple ways to configure server URL
- **PowerShell 5.1+ Compatible**: Works on Windows PowerShell and PowerShell Core

## Installation

### Option 1: Install from Git Repository

```powershell
# Clone the repository
git clone https://github.com/aaronearles/netdiag-powershell.git

# Import the module
Import-Module .\netdiag-powershell\NetDiag.psd1
```

### Option 2: Install to PowerShell Modules Directory

```powershell
# Clone to your PowerShell modules directory
$ModulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\NetDiag"
git clone https://github.com/aaronearles/netdiag-powershell.git $ModulePath

# Import the module (or restart PowerShell for auto-loading)
Import-Module NetDiag
```

### Option 3: Manual Installation

1. Download/clone the repository
2. Copy the `netdiag-powershell` folder to one of your PowerShell module paths:
   - User: `$env:USERPROFILE\Documents\PowerShell\Modules\`
   - System: `C:\Program Files\PowerShell\Modules\`
3. Rename folder to `NetDiag`
4. Import: `Import-Module NetDiag`

## Configuration

Configure the NetDiag server URL using one of these methods (in order of precedence):

### 1. Environment Variable (Highest Priority)

```powershell
$env:NETDIAG_SERVER = "http://dockerint01:3000"
```

### 2. Config File

```powershell
Set-NetDiagServer -Url "http://dockerint01:3000" -Persist
```

Creates `~/.netdiag/config.json` for persistence across sessions.

### 3. Session Variable

```powershell
Set-NetDiagServer -Url "http://dockerint01:3000"
```

Sets for current session only.

### 4. Default

If no configuration is found, defaults to `http://dockerint01:3000`.

### Check Current Configuration

```powershell
Get-NetDiagServer
```

## Usage

### Whois Lookup

Query whois information for IP addresses, domains, or ASN:

```powershell
# IP address lookup
netdiag whois -Target 8.8.8.8

# IPv6 lookup
netdiag whois -Target 2001:4860:4860::8888

# Domain lookup
netdiag whois -Target google.com

# ASN lookup
netdiag whois -Target AS15169

# Filter specific fields (uses standardized field names)
netdiag whois -Target 8.8.8.8 -Fields Organization,CIDR,Country
```

**Full Output:**
```
Target    : 8.8.8.8
Parsed    : @{NetRange=8.8.8.0 - 8.8.8.255; IPRange=8.8.8.0 - 8.8.8.255; CIDR=8.8.8.0/24;
            NetName=LVLT-GOGL-8-8-8; NetworkName=LVLT-GOGL-8-8-8; Organization=Google LLC;
            Country=US; ...}
Raw       : # ARIN WHOIS data...
Cached    : False
Timestamp : 2/10/2026 10:00:00 AM
```

**Filtered Output (with -Fields parameter):**
```
Target       : 8.8.8.8
Organization : Google LLC
CIDR         : 8.8.8.0/24
Country      : US
Cached       : False
Timestamp    : 2/10/2026 10:00:00 AM
```

Note: The API normalizes whois fields across different Regional Internet Registries (RIRs). You can use standardized field names like `Organization`, `IPRange`, `CIDR`, `Country` that work consistently regardless of whether the data comes from ARIN, APNIC, RIPE, etc. Both original and normalized field names are available in full responses.

### DNS Lookup

Query DNS records:

```powershell
# A record (IPv4)
netdiag dns -Hostname google.com

# Specify record type
netdiag dns -Hostname google.com -Type AAAA

# MX records
netdiag dns -Hostname google.com -Type MX

# TXT records
netdiag dns -Hostname google.com -Type TXT

# All records
netdiag dns -Hostname google.com -Type ANY
```

**Output:**
```
Hostname    : google.com
Type        : A
Records     : {142.250.185.46}
RecordCount : 1
Raw         : 142.250.185.46
Cached      : False
Timestamp   : 2/10/2026 10:00:00 AM
```

### Ping Test

Perform ICMP ping tests:

```powershell
# Default ping (4 packets)
netdiag ping -PingTarget 8.8.8.8

# Custom packet count
netdiag ping -PingTarget google.com -Count 10

# Use hostname
netdiag ping -PingTarget cloudflare.com -Count 5
```

**Output:**
```
Target            : 8.8.8.8
PacketsSent       : 4
PacketsReceived   : 4
PacketLossPercent : 0
TimeMs            : 3042
RTT               : @{Min=14.2; Avg=15.1; Max=16.8; StdDev=1.2}
Cached            : False
Timestamp         : 2/10/2026 10:00:00 AM
```

### Port Check

Test TCP port connectivity:

```powershell
# Check HTTPS port
netdiag port -Host google.com -Port 443

# Check SSH port
netdiag port -Host 8.8.8.8 -Port 22

# Check custom port
netdiag port -Host example.com -Port 8080
```

**Output:**
```
Host           : google.com
Port           : 443
Open           : True
ResolvedIP     : 142.250.185.46
ResponseTimeMs : 42
Cached         : False
Timestamp      : 2/10/2026 10:00:00 AM
```

### SSL Certificate

Inspect SSL/TLS certificates:

```powershell
# Check HTTPS certificate
netdiag ssl -SSLHostname google.com

# Custom port
netdiag ssl -SSLHostname example.com -SSLPort 8443
```

**Output:**
```
Hostname    : google.com
Port        : 443
Certificate : @{Subject=@{common_name=*.google.com}; Issuer=@{common_name=GTS CA 1C3};
              Validity=@{NotBefore=1/13/2026; NotAfter=4/7/2026; DaysRemaining=57}}
Warnings    : {Certificate expires in 57 days}
ChainValid  : True
Cached      : False
Timestamp   : 2/10/2026 10:00:00 AM
```

## PowerShell Pipeline Examples

Leverage PowerShell's pipeline capabilities:

```powershell
# Check multiple hosts
@('google.com', 'github.com', 'microsoft.com') | ForEach-Object {
    netdiag dns -Hostname $_
}

# Check port connectivity for multiple ports
443, 80, 22 | ForEach-Object {
    netdiag port -Host google.com -Port $_
}

# Export SSL certificate info to CSV
$Cert = netdiag ssl -SSLHostname google.com
$Cert.Certificate.Validity | Export-Csv -Path certs.csv -NoTypeInformation

# Filter and format whois results
$result = netdiag whois -Target 8.8.8.8
$result.Parsed.Organization
$result.Parsed.CIDR

# Filter whois with specific fields (returns flat structure)
$result = netdiag whois -Target 8.8.8.8 -Fields Organization,CIDR,Country
$result.Organization
$result.CIDR

# Check multiple IPs and filter reachable ones
@('8.8.8.8', '1.1.1.1', '208.67.222.222') | ForEach-Object {
    netdiag ping -PingTarget $_ -Count 4
} | Where-Object { $_.PacketLossPercent -eq 0 } | Select-Object Target, @{N='AvgRTT';E={$_.RTT.Avg}}
```

## Advanced Usage

### JSON Output

Get raw JSON response:

```powershell
netdiag whois -Target 8.8.8.8 -AsJson
```

### Verbose Output

See detailed request information:

```powershell
netdiag dns -Hostname google.com -Verbose
```

### Error Handling

```powershell
try {
    $Result = netdiag port -Host invalid-host -Port 443
    if ($Result.Open) {
        Write-Host "Port is open"
    }
}
catch {
    Write-Warning "Request failed: $_"
}
```

## Cmdlet Reference

### Invoke-NetDiag (alias: netdiag)

Main command for all diagnostic tools.

**Parameters:**
- `-Tool` - Tool to run: whois, dns, ping, port, ssl
- `-Target` - Target for whois/ping (IP, domain, ASN)
- `-Fields` - Fields to return from whois
- `-Hostname` - Hostname for DNS/SSL
- `-Type` - DNS record type (A, AAAA, MX, TXT, NS, CNAME, SOA, ANY)
- `-PingTarget` - Target for ping
- `-Count` - Ping packet count (1-10)
- `-Host` - Host for port check
- `-Port` - Port number (1-65535)
- `-SSLHostname` - Hostname for SSL check
- `-SSLPort` - SSL port (default: 443)
- `-AsJson` - Return raw JSON

### Set-NetDiagServer

Configure the NetDiag server URL.

**Parameters:**
- `-Url` (required) - Server URL
- `-Persist` - Save to config file

**Examples:**
```powershell
Set-NetDiagServer -Url "http://dockerint01:3000"
Set-NetDiagServer -Url "http://localhost:3000" -Persist
```

### Get-NetDiagServer

Display current server configuration.

**Example:**
```powershell
Get-NetDiagServer
```

## Troubleshooting

### Module Not Found

```powershell
# Check module path
$env:PSModulePath -split ';'

# Import with full path
Import-Module C:\path\to\NetDiag.psd1
```

### Connection Failed

```powershell
# Check server configuration
Get-NetDiagServer

# Test connectivity
Test-NetConnection dockerint01 -Port 3000

# Set correct server URL
Set-NetDiagServer -Url "http://dockerint01:3000"
```

### Enable Verbose Logging

```powershell
$VerbosePreference = 'Continue'
netdiag whois -Target 8.8.8.8
```

## Requirements

- PowerShell 5.1 or higher
- Network access to NetDiag server
- NetDiag server running and accessible

## Project Structure

```
netdiag-powershell/
├── NetDiag.psd1              # Module manifest
├── NetDiag.psm1              # Main module file
├── Public/
│   ├── Invoke-NetDiag.ps1    # Main cmdlet
│   ├── Set-NetDiagServer.ps1 # Configuration
│   └── Get-NetDiagServer.ps1 # Configuration
├── Private/
│   ├── Get-NetDiagServerUrl.ps1    # Helper
│   ├── Invoke-NetDiagRequest.ps1   # HTTP client
│   └── Format-NetDiagResponse.ps1  # Response formatter
└── README.md
```

## Related Projects

- [netdiag-server](https://github.com/aaronearles/netdiag-server) - HTTP API server
- [netdiag-python](https://github.com/aaronearles/netdiag-python) - Python client (coming soon)

## License

MIT

## Author

Aaron Earles
