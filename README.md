# Automated-VM

The project enables user to automatically create Windows 10/11 VM machines and install system.

## Quick start

1. Download the repository as a ZIP file and unzip it.
2. Copy your Windows Disk Image (ISO) to the ISOs folder and rename the iso file `Win11.iso`.
3. Run `VM_Creation.ps1` via PowerShell: `powershell -ExecutionPolicy Bypass -File .\VM_Creation.ps1`

4. Input your Windows username and password.
5. After creation, click 'Power on this virtual machine', then quickly click into the VM window and **press any key** to start the Windows installation.
6. Wait until the system is installed, customized, and activated.