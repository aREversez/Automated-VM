param(
    [string]$autounattendPath = ".\ISOs\autounattend.xml",
    [string]$outputISOPath = ".\ISOs\unattend.iso",
    [string]$TempFolder = ".\ISOs\TempUnattend",
    [string]$oscdimgPath = ".\Tools\Oscdimg\oscdimg.exe",
    [string]$masaioPath = ".\ISOs\MAS_AIO.cmd"
)

# --- Step 1: Credentials
$Username = Read-Host "Enter Windows username"
$Password = Read-Host "Enter Windows password" -AsSecureString
$PasswordPlain = [System.Net.NetworkCredential]::new("", $Password).Password
Write-Host "Updating autounattend.xml with Username=$Username and Password=*****"

# --- Step 2: Update copied XML and add MAS_AIO
# Create temp folder and copy XML into it
if (Test-Path $TempFolder) {
    Remove-Item $TempFolder -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $TempFolder | Out-Null
Copy-Item $autounattendPath -Destination $TempFolder
Copy-Item $masaioPath -Destination $TempFolder

# Define replacements: "oldValue" = "newValue"
$replacements = @{
    "Your_Username" = $Username
    "Your_Password" = $PasswordPlain
}

# Read the file as raw text
$fileContent = Get-Content -Path "$TempFolder\autounattend.xml" -Raw

# Perform replacements
foreach ($pair in $replacements.GetEnumerator()) {
    $fileContent = $fileContent -replace [regex]::Escape($pair.Key), $pair.Value
}

# Write the modified content back WITHOUT BOM
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$TempFolder\autounattend.xml", $fileContent, $Utf8NoBomEncoding)
Write-Output "Replacements completed successfully in $TempFolder\autounattend.xml"

# --- Step 3: Create unattend.iso using oscdimg
if (Test-Path $oscdimgPath) {
    & $oscdimgPath -n -m -d "$TempFolder" "$outputISOPath"
    Write-Output "unattend.iso has been created at $outputISOPath."
} else {
    Write-Error "oscdimg.exe not found at $oscdimgPath. Cannot create unattend.iso."
}