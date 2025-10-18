param(
    [string]$VMsDir = ".\VMs",
    [string]$WinISO = ".\ISOs\Win11.iso",
    [string]$WinISOabs = (Resolve-Path $WinISO).Path,
    [string]$UnattendXML = ".\ISOs\autounattend.xml",
    [string]$UnattendISO = ".\ISOs\unattend.iso",
    [string]$VMToolsISO = "C:\Program Files (x86)\VMware\VMware Workstation\windows.iso",
    [string]$TempFolder = ".\ISOs\TempUnattend",
    [string]$UnattendXMLCOPY = ".\ISOs\TempUnattend\autounattend.xml",
    [string]$OSCDIMG = ".\Tools\Oscdimg\oscdimg.exe",
    [string]$MAS_AIO = ".\ISOs\MAS_AIO.cmd",
    [int]$CPUs = 2,
    [int]$MemoryMB = 4096,
    [int]$DiskGB = 64
)

# --- Define Constants ---
$VMWARE_PATH = "C:\Program Files (x86)\VMware\VMware Workstation"
$VDISK_MANAGER = "$VMWARE_PATH\vmware-vdiskmanager.exe"

# --- Step 1: Credentials
$Username = Read-Host "Enter Windows username"
$Password = Read-Host "Enter Windows password" -AsSecureString
$PasswordPlain = [System.Net.NetworkCredential]::new("", $Password).Password
Write-Host "Updating autounattend.xml with Username=$Username and Password=*****"

# --- Step 2: Update copied XML and add MAS_AIO
# Create temp folder and copy XML into it
if (Test-Path $TempFolder) { Remove-Item $TempFolder -Recurse -Force }
New-Item -ItemType Directory -Force -Path $TempFolder | Out-Null
Copy-Item $UnattendXML -Destination $TempFolder
Copy-Item $MAS_AIO -Destination $TempFolder

# Define replacements: "oldValue" = "newValue"
$replacements = @{
    "Your_Username" = $Username
    "Your_Password" = $PasswordPlain
}

# Read the file as raw text
$fileContent = Get-Content -Path $UnattendXMLCOPY -Raw

# Perform replacements
foreach ($pair in $replacements.GetEnumerator()) {
    $fileContent = $fileContent -replace [Regex]::Escape($pair.Key), $pair.Value
}

# Write the modified content back WITHOUT BOM
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText($UnattendXMLCOPY, $fileContent, $Utf8NoBomEncoding)
Write-Output "Replacements completed successfully in $UnattendXMLCOPY"

# --- Step 3: Create unattend.iso using oscdimg
if (Test-Path $OSCDIMG) {
    Start-Process -FilePath $OSCDIMG -ArgumentList '-n -m -d "$TempFolder" "$UnattendISO"' -WindowStyle Hidden -Wait
}
Write-Output "unattend.iso has been created."

# --- Step 4: Create VM folder (unchanged) ---
$VMName = $Username
$VMPath = Join-Path $VMsDir $VMName
if (Test-Path $VMPath) {
    $VMName = "$Username-" + (Get-Date -Format "yyyyMMddHHmmss")
    $VMPath = Join-Path $VMsDir $VMName
}
New-Item -ItemType Directory -Force -Path $VMPath | Out-Null

# --- Step 5: Create virtual disk (Single-file, SATA adapter) ---
Write-Host "Creating $DiskGB GB single-file disk (type 0)..."

# Creating a monolithic disk (-t 0)
& $VDISK_MANAGER -c -s ${DiskGB}GB -a sata -t 0 "$VMPath\$VMName.vmdk"

# --- Step 6: Build VMX file for VMware Workstation 25H2 (virtualHW 22) ---
$UnattendISOabs = (Resolve-Path $UnattendISO).Path

$vmxContent = @"
.encoding = "UTF-8"
config.version = "8"
virtualHW.version = "22"
virtualHW.productCompatibility = "hosted"
displayName = "$VMName"
guestOS = "windows11-64"
memsize = "$MemoryMB"
numvcpus = "$CPUs"

# --- Firmware and TPM ---
firmware = "efi"
managedVM.autoAddVTPM = "software"

# --- Disable legacy devices ---
floppy0.present = "FALSE"

# --- PCI Bridges (required for virtualHW 22) ---
pciBridge0.present = "TRUE"
pciBridge4.present = "TRUE"
pciBridge4.virtualDev = "pcieRootPort"
pciBridge4.functions = "8"
pciBridge5.present = "TRUE"
pciBridge5.virtualDev = "pcieRootPort"
pciBridge5.functions = "8"
pciBridge6.present = "TRUE"
pciBridge6.virtualDev = "pcieRootPort"
pciBridge6.functions = "8"
pciBridge7.present = "TRUE"
pciBridge7.virtualDev = "pcieRootPort"
pciBridge7.functions = "8"

# --- VMCI and HPET (required for virtualHW 22) ---
vmci0.present = "TRUE"
hpet0.present = "TRUE"

# --- Power Management ---
powerType.powerOff = "soft"
powerType.powerOn = "soft"
powerType.suspend = "soft"
powerType.reset = "soft"

# --- SATA storage controller ---
sata0.present = "TRUE"
sata0:0.present = "TRUE"
sata0:0.fileName = "$VMName.vmdk"
sata0:1.present = "TRUE"
sata0:1.fileName = "$WinISOabs"
sata0:1.deviceType = "cdrom-image"
sata0:2.present = "TRUE"
sata0:2.fileName = "$UnattendISOabs"
sata0:2.deviceType = "cdrom-image"
sata0:3.present = "TRUE"
sata0:3.fileName = "$VMToolsISO"
sata0:3.deviceType = "cdrom-image"

# --- USB Controllers ---
usb.present = "TRUE"
ehci.present = "TRUE"
usb_xhci.present = "TRUE"

# --- Network ---
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = "e1000e"

# --- Sound ---
sound.present = "TRUE"
sound.fileName = "-1"
sound.autoDetect = "TRUE"
sound.virtualDev = "hdaudio"

# --- Tools and Sync ---
tools.syncTime = "FALSE"
tools.upgrade.policy = "manual"
"@

$vmxFile = "$VMPath\\$VMName.vmx"
$vmxContent | Out-File -Encoding UTF8 $vmxFile

Write-Host "VMX configuration generated with virtualHW.version 22 for VMware Workstation 25H2"

# --- Step 7: Open VM in GUI and prompt user to complete setup ---
Write-Host "--- VM Creation Complete ---"
Write-Host "VM $VMName has been created at: $VMPath"
Write-Host "The VMX file will now open in VMware Workstation Pro."

# Open the VMX file in the GUI.
Start-Process "$vmxFile"

Write-Host "----------------------------------------------------------------------------------------------------------------"
Write-Host "MANUAL STEPS REQUIRED:"
Write-Host "Click 'Power on this virtual machine', then quickly click into the VM window and **press any key** to start the Windows installation."
Write-Host "----------------------------------------------------------------------------------------------------------------"
