param (
    [string]$ComputerName, # Target computer name
    [string]$PrinterName, # Printer model
    [string]$PrinterSuffix, # Printer description
    [string]$PrinterIP, 
    [string]$DriversRepository = "\\network-share\Printers\Drivers", # 
    [switch]$ListSupportedPrinters, 
    [string]$UserName,
    [switch]$Share,
    [switch]$ShareOnly
)

function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0,[int] $LinesAfter = 0, [switch]$NoNewLine) {
    $DefaultColor = $Color[0];
    if ($LinesBefore -ne 0) {
        for ($i = 0; $i -lt $LinesBefore; $i++) {
            Write-Host "`n" -NoNewline;
        }
    } # Add empty line before  

    if ($StartTab -ne 0) {
        for ($i = 0; $i -lt $StartTab; $i++) {
            Write-Host "`t" -NoNewLine;
        }
    }  # Add TABS before text 

    if ($Color.Count -ge $Text.Count) {
        for ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine;
        } 
    } else {
        for ($i = 0; $i -lt $Color.Length ; $i++) {
            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine;
        }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine;
        }
    }
    if (!($NoNewLine)) {
        Write-Host;
    }
    if ($LinesAfter -ne 0) {
        for ($i = 0; $i -lt $LinesAfter; $i++) {
            Write-Host "`n";
        }
    }  # Add empty line after   
}

Clear-Host;
Write-Color -Text ":::::::::::::::::::::::::::: ", "Printer Install Script", " ::::::::::::::::::::::::::::" -Color Blue, White, Blue;

# List supported printers
if ($ListSupportedPrinters) {
    Write-Color -Text "==> ", "Supported printers" -Color Green, White
    $SupportedPrinters = Get-ChildItem -Directory -Path $DriversRepository | Select-Object Name | ForEach-Object {$_.Name};
    foreach($Printer in $SupportedPrinters) {
        Write-Color -Text "--> ", "$Printer" -Color Blue, Green;
        $SupportedSystems = Get-ChildItem -Directory -Path "$DriversRepository\$Printer" | Select-Object Name | ForEach-Object {$_.Name}; 
        foreach($System in $SupportedSystems) {
            Write-Color -Text "    ", "$System", " (" -Color Blue, White, Red -NoNewLine;
            [string[]]$SupportedArch = Get-ChildItem -Directory -Path "$DriversRepository\$Printer\$System" | Select-Object Name | ForEach-Object {$_.Name}; 
            if ($SupportedArch.Count -eq 2) {
                Write-Color -Text "$($SupportedArch[0])/" -Color Red -NoNewLine;  
                Write-Color -Text "$($SupportedArch[1]))" -Color Red;     
            } else {
                Write-Color -Text "$($SupportedArch[0]))" -Color Red;   
            }
        }  
    }
    return;
}
# Config
$LocalDriversRepository = "Temp"; # Relative to C: drive on target computer
$Port_Name = "$PrinterName($PrinterIP)"; #CHANGE THIS

$ComputerArch = ""; # Auto
$DriverName = ""; # Auto
$DriverInfName = ""; # Auto
$PrinterDriverInRepositoryPath = $DriversRepository+"\$PrinterName"; # Auto

Write-Color -Text "==> ", "Script settings" -Color Green, White
Write-Color -Text "--> ", "DriversRepository -> ", $DriversRepository -Color Blue, White, Red -StartTab 1;
Write-Color -Text "--> ", "LocalDriversRepository -> ", "C:\$LocalDriversRepository" -Color Blue, White, Red -StartTab 1;
Write-Color -Text "--> ", "Printer name -> ", $PrinterName -Color Blue, White, Red -StartTab 1;
Write-Color -Text "--> ", "Printer IP -> ", $PrinterIP -Color Blue, White, Red -StartTab 1;
Write-Color -Text "--> ", "Printer port name -> ", $Port_Name -Color Blue, White, Red -StartTab 1;
Write-Color -Text "--> ", "Target computer -> ", $ComputerName -Color Blue, White, Red -StartTab 1;
if ($UserName) {
    Write-Color -Text "--> ", "Target computer username -> ", $UserName -Color Blue, White, Red -StartTab 1;   
}
if ($Share -or $ShareOnly) {
    # Share scan folder
    if (!($UserName)) {
        # If UserName is null then exit script
        return;
    }

    Write-Color -Text "==> ", "Sharing scan folder" -Color Green, White;

    # If user not exists on target computer then exit script
    if (!(Test-Path "\\$ComputerName\c$\Users\$UserName")) {
        Write-Color -Text "--> ", "Sorry. '$UserName' not exists on $ComputerName" -Color Blue, Red -StartTab 1;
        Write-Color -Text "--> ", "Press any key to exit..." -Color Blue, White -StartTab 1;
        Read-Host;
        return;
    } else {
        Write-Color -Text "--> ", "$UserName exists on $ComputerName." -Color Blue, Green -StartTab 1;   
    }

    # If scan folder already exists on target computer then exit script
    if (Test-Path "\\$ComputerName\c$\Users\$UserName\skany") {
        Write-Color -Text "--> ", "Sorry. Scan folder already exists on $ComputerName" -Color Blue, Red -StartTab 1;
        Write-Color -Text "--> ", "Press any key to exit..." -Color Blue, White -StartTab 1;
        Read-Host;
        return;   
    }

    Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $UserProfile = "C:\Users\$using:UserName";
        New-Item -Path $UserProfile -Name "skany" -ItemType Directory | Out-Null;
        New-SmbShare -Name "skany" -Path "$UserProfile\skany";
        Revoke-SmbShareAccess -Name "skany" -AccountName Wszyscy -Force;
        Grant-SmbShareAccess -Name "skany" -AccountName admin -AccessRight Full -Force;
        Grant-SmbShareAccess -Name "skany" -AccountName Administratorzy -AccessRight Full -Force;
        Grant-SmbShareAccess -Name "skany" -AccountName $using:UserName -AccessRight Full -Force;
        $Acl = Get-ACL "$UserProfile\skany";
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("admin","full","ContainerInherit,Objectinherit","none","Allow");
        $Acl.AddAccessRule($AccessRule);
        Set-Acl "$UserProfile\skany" $Acl;
        # Firewall
        Set-NetFirewallRule -Name 'FPS-LLMNR-In-UDP' -Profile Any;
        Set-NetFirewallRule -Name 'FPS-LLMNR-Out-UDP' -Profile Any;
        Set-NetFirewallRule -DisplayName 'Udostępnianie plików*'-Profile any;
        Set-NetFirewallRule -DisplayName '*SMB*'-Profile any; 
    }
    Write-Color -Text "--> ", "Scan folder was shared succesfully" -Color Blue, Green -StartTab 1;
    if ($ShareOnly) {
        return;
    }
}

Write-Color -Text "==> ", "Test paths..." -Color Green, White;
# Check if source folder exists
if (!(Test-Path -Path $DriversRepository)) {
    Write-Color -Text "--> ", "DriversRepository does not exists." -Color Blue, Red -StartTab 1;
    Write-Color -Text "--> ", "Press any key to exit..." -Color Blue, White -StartTab 1;
    Read-Host;
    return;
} else {
    Write-Color -Text "--> ", "DriversRepository exists." -Color Blue, Green -StartTab 1;
}


# Check if printers is supported by this script
Write-Color -Text "==> ", "Checking if printer is supported..." -Color Green, White;
#$SupportedPrinters = Get-ChildItem -Directory -Path $DriversRepository | Select-Object Name | ForEach-Object {$_.Name}
$SupportedPrinters = Get-ChildItem -Directory -Path $DriversRepository | Select-Object Name | ForEach-Object {$_.Name}
if (!($PrinterName -in $SupportedPrinters)) {
    Write-Color -Text "--> ", "Sorry. '$PrinterName' is not supported." -Color Blue, Red -StartTab 1;
    Write-Color -Text "--> ", "Press any key to exit..." -Color Blue, White -StartTab 1;
    Read-Host
    return;     
} else {
    Write-Color -Text "--> ", "Printer is supported." -Color Blue, Green -StartTab 1;
}

# Get computer arch
Write-Color -Text "==> ", "Get target computer arch..." -Color Green, White;
$ComputerArchTemp = (Get-WmiObject Win32_OperatingSystem -computername $ComputerName).OSArchitecture;
if ($ComputerArchTemp -like "*64*") {
    $ComputerArch = "x64";
} else {
   $ComputerArch = "x86";
}
Write-Color -Text "--> ", "Target computer architecture: ", "$ComputerArch" -Color Blue, White, Red -StartTab 1;

# Get operating system version
Write-Color -Text "==> ", "Get target operating system version..." -Color Green, White;
$ComputerVersionTemp = (Get-WmiObject Win32_OperatingSystem -computername $ComputerName).Caption;
if ($ComputerVersionTemp -like "*Windows 7*") {
    $ComputerOSVersion = "Windows 7";
} else {
   $ComputerOSVersion = "Windows 10";
}
Write-Color -Text "--> ", "Target operating system version: ", "$ComputerOSVersion" -Color Blue, White, Red -StartTab 1;

# Check if computer is supported
$SupportedSystems = Get-ChildItem -Directory -Path "$DriversRepository\$PrinterName" | Select-Object Name | ForEach-Object {$_.Name}
if (!($ComputerOSVersion -in $SupportedSystems)) {
    Write-Color -Text "--> ", "Sorry. '$ComputerOSVersion' is not supported." -Color Blue, Red -StartTab 1;
    Write-Color -Text "--> ", "Press any key to exit..." -Color Blue, White -StartTab 1;
    Read-Host
    return;     
} else {
    Write-Color -Text "--> ", "Target computer system is supported." -Color Blue, Green -StartTab 1;
}

# Get driver settings
Write-Color -Text "==> ", "Get printer driver settings..." -Color Green, White;
if (!(Test-Path -Path "$PrinterDriverInRepositoryPath\Driver.ini")) {
    Write-Color -Text "--> ", "Cannot get printer driver settings" -Color Blue, Red -StartTab 1;
    Write-Color -Text "--> ", "Press any key to exit..." -Color Blue, White -StartTab 1; 
    Read-Host
    return;         
} else {
    Get-Content "$PrinterDriverInRepositoryPath\Driver.ini" | foreach-object -begin {$Settings=@{}} -process { $k = [regex]::split($_,'='); if(($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True)) { $Settings.Add($k[0], $k[1]) } }
    $DriverName = $Settings["Name"];
    $DriverInfName = $Settings["Inf$ComputerArch"];
    Write-Color -Text "--> ", "Printer driver name -> ", $DriverName -Color Blue, White, Red -StartTab 1;
    Write-Color -Text "--> ", "Printer driver inf -> ", $DriverInfName -Color Blue, White, Red -StartTab 1;
}

# Copy printer drivers to target computer
Write-Color -Text "==> ", "Copying files..." -Color Green, White;
Write-Color -Text "--> ", "Coping files from '$PrinterDriverInRepositoryPath\$ComputerOSVersion\$ComputerArch' to '\\$ComputerName\c$\$LocalDriversRepository'. It may take a while." -Color Blue, White -StartTab 1;
Copy-Item -Path "$PrinterDriverInRepositoryPath\$ComputerOSVersion\$ComputerArch" -Destination "\\$ComputerName\c$\$LocalDriversRepository\$PrinterName\$ComputerOSVersion\$ComputerArch" -Recurse


# Starting printer installation
Write-Color -Text "==> ", "Starting printer installation..." -Color Green, White;
$Result = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    if ((Test-Path "C:\$using:LocalDriversRepository\$using:PrinterName\$using:ComputerOSVersion\$using:ComputerArch") -eq $true) {
        #Install Printer Driver
        $driverclass = [WMIClass]"Win32_PrinterDriver"
        $driverobj = $driverclass.createinstance()
        $driverobj.Name = "$using:DriverName"
        $driverobj.DriverPath = "C:\$using:LocalDriversRepository\$using:PrinterName\$using:ComputerOSVersion\$using:ComputerArch"
        $driverobj.Infname = "C:\$using:LocalDriversRepository\$using:PrinterName\$using:ComputerOSVersion\$using:ComputerArch\$using:DriverInfName"
        $newdriver = $driverclass.AddPrinterDriver($driverobj)
        $newdriver = $driverclass.Put()
        #Install Printer Port
        $Port = ([wmiclass]"win32_tcpipprinterport").createinstance()
        $Port.Name = "$using:Port_Name"
        $Port.HostAddress = "$using:PrinterIP"
        $Port.Protocol = "1"
        $Port.PortNumber = "9100"
        $Port.SNMPEnabled = $true
        $Port.Description = "C_$using:PrinterIP"
        $Port.Put()
        #Install Printer
        $Printer = ([wmiclass]"win32_Printer").createinstance()
        $Printer.Name = "$using:PrinterName $using:PrinterSuffix"
        Write-Host "DriverName: $using:DriverName"
        $Printer.DriverName = "$using:DriverName"
        $Printer.DeviceID = "$using:PrinterName $using:PrinterSuffix"
        $Printer.Shared = $false
        $Printer.PortName = "$using:Port_Name"
        $Port.Description = "$using:Port_Name"
        $Printer.Put()
        return $true;
    }
    else {return $false}
}

if ($Result) {
    Write-Color -Text "--> ", "Printer install was successfull" -Color Blue, Green -StartTab 1;
} else {
    Write-Color -Text "--> ", "Printer install failed" -Color Blue, Red -StartTab 1;
}
