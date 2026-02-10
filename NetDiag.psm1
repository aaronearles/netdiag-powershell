# NetDiag PowerShell Module
# Network diagnostic tools client for the NetDiag HTTP API

# Module-level variables
$script:NetDiagServer = $null
$script:DefaultServer = "http://dockerint01:3000"

# Get the module directory
$script:ModuleRoot = $PSScriptRoot

# Import private functions
$PrivateFunctions = Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PrivateFunctions) {
    . $Function.FullName
}

# Import public functions
$PublicFunctions = Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1" -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    . $Function.FullName
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName -Alias 'netdiag'
