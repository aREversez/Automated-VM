# Automated-VM

The project enables users to automatically create Windows 10/11 VM machines and install system.

## Quick start

1. Download the repository as a ZIP file and unzip it.
2. Copy your Windows Disk Image (ISO) to the ISOs folder and rename the iso file `Win11.iso`.
3. Run `VM_Creation.ps1` via PowerShell: `powershell -ExecutionPolicy Bypass -File .\VM_Creation.ps1`

4. Input your Windows username and password.
5. After creation, click 'Power on this virtual machine', then quickly click into the VM window and **press any key** to start the Windows installation.
6. Wait until the system is installed, customized, and activated.

## Customization

### PowerShell Script

The script automates the creation of Windows VM machine. But please note that the script does not include any unnecessary settings for basic VM creation.

If you need to enable options like `Accelerate 3D graphics` or add more Network Adapters, you can manually do that via VMware GUI after VM creation.

Also, it is possible to include those settings in the script. For example, you can change default Network Adaptor from NAT to Bridged by removing `ethernet0.connectionType = "nat"` or you can add another Network Adaptor such as VMnet19 by adding these lines: 

```PowerShell
ethernet1.present = "TRUE"
ethernet1.connectionType = "custom"
ethernet1.virtualDev = "e1000e"
ethernet1.vnet = "VMnet19"
ethernet1.displayName = "VMnet19"
```

### autounattend.xml

The workflow uses answer file, namely **autounattend.xml** or **unattend.xml**, an XML-based file that automates and customizes an operating system installation by pre-defining answers to the setup prompts, such as how to partition disks, user account information, and product keys.

For more information about the autounattend.xml, please visit [Windows answer files](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/update-windows-settings-and-scripts-create-your-own-answer-file-sxs?view=windows-11).

The provided autounattend.xml in the repository is generated via [schneegans.de](https://schneegans.de/windows/unattend-generator/). The XML file includes system activation script, namely MAS_AIO.cmd, which will be run after the system installation. If you do not need this, you can remove these lines at the end of the xml file:

```PowerShell
    {
		$masPath = $null;
		foreach ($letter in 'DEFGHIJKLMNOPQRSTUVWXYZ'.ToCharArray()) {
			$testPath = "${letter}:\MAS_AIO.cmd";
			if (Test-Path $testPath) {
				$masPath = $testPath;
				break;
			}
		}
		if ($masPath) {
			Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$masPath`" /Z-Windows" -Wait -NoNewWindow;
			"Activation complete.";
		} else {
			"MAS_AIO.cmd not found on any removable drive.";
    	}
	};
```
