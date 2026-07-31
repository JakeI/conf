param(
    [string]$uri
)

$ErrorActionPreference = "Stop"

trap {
    Write-Host ""
    Write-Host "ERROR:"
    Write-Host $_
    Read-Host "Press any key to close"
    exit 1
}

# ============================================================
# Configuration
# ============================================================

# Vault name -> filesystem path
$vaults = @{
    "vault" = "D:\val\note\vault"
    # "work" = "D:\work\vault"
    # "personal" = "C:\Users\Jochen\Documents\personal"
}


# Application definitions
#
# exe:
#   executable path
#
# extensions:
#   file extensions handled by this app when no app= is given
#
$apps = @{
    "inkscape" = @{
        exe = "C:\Program Files\Inkscape\bin\inkscape.exe"
        extensions = @(".svg")
    }

    "xournalpp" = @{
        exe = "C:\Program Files\Xournal++\bin\xournalpp.exe"
        extensions = @(".xopp")
    }

    "gimp" = @{
        exe = "C:\Program Files\GIMP 3\bin\gimp.exe"
        extensions = @(".png", ".jpg", ".jpeg")
    }
}


# ============================================================
# Parse URI
# ============================================================

try {
    $parsedUri = [System.Uri]$uri
}
catch {
    Write-Output "Invalid URI:"
    Write-Output $uri
    Read-Host "Press any key to close"
    exit 1
}


$query = @{}

$parsedUri.Query.TrimStart("?").Split("&") | ForEach-Object {
    if ($_ -match "=") {
        $key, $value = $_ -split "=", 2
        $query[$key] = [System.Uri]::UnescapeDataString($value)
    }
}


$file = $query["file"]
$vaultName = $query["vault"]
$appName = $query["app"]


if (-not $file) {
    Write-Output "Error: no file specified"
    Read-Host "Press any key to close"
    exit 1
}


# ============================================================
# Resolve path
# ============================================================

if ($vaultName) {

    if (-not $vaults.ContainsKey($vaultName)) {
        Write-Output "Error: unknown vault '$vaultName'"
        Write-Output "Known vaults:"
        $vaults.Keys | ForEach-Object { Write-Output " - $_" }

        Read-Host "Press any key to close"
        exit 1
    }

    $file = Join-Path $vaults[$vaultName] $file
}


$file = [System.IO.Path]::GetFullPath($file)


Write-Output "File:"
Write-Output " $file"


if (-not (Test-Path $file)) {
    Write-Output ""
    Write-Output "Error: file does not exist"

    Read-Host "Press any key to close"
    exit 1
}


# ============================================================
# Select application
# ============================================================


# Explicit app selection
if ($appName) {

    if (-not $apps.ContainsKey($appName)) {
        Write-Output "Error: unknown application '$appName'"
        Write-Output "Known applications:"
        $apps.Keys | ForEach-Object { Write-Output " - $_" }

        Read-Host "Press any key to close"
        exit 1
    }

    $app = $apps[$appName]
}


# Automatic selection by extension
else {

    $extension = [System.IO.Path]::GetExtension($file).ToLower()

    $found = $apps.GetEnumerator() | Where-Object {
        $_.Value.extensions -contains $extension
    }


    if ($found.Count -eq 0) {
        Write-Output "No application found for extension '$extension'"
        Read-Host "Press any key to close"
        exit 1
    }


    if ($found.Count -gt 1) {
        Write-Output "Multiple applications found:"
        $found | ForEach-Object {
            Write-Output " - $($_.Key)"
        }

        Read-Host "Press any key to close"
        exit 1
    }


    $app = $found[0].Value
}



# ============================================================
# Launch
# ============================================================

Write-Output ""
Write-Output "Opening with:"
Write-Output " $($app.exe)"


Start-Process `
    -FilePath $app.exe `
    -ArgumentList @($file)

