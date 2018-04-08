# PrinterInstall
Script for remote installation of network printers

## Parameters
* `-ComputerName` - target computer
* `-PrinterName` - name of printer that we want to install. It has to be equal to name of printer in drivers repository
* `-PrinterSuffix` - suffix that will be visible in printer name on target computer. The installed printer will have a name made of `PrinterName`+`PrinterSuffix`
* `-PrinterIP` - IP of printer that we will be installing
* `-DriversRepository` - Path to drivers repository
* `-ListSupportedPrinters` - that switch will only list printers that we can install. That list is based on the content in `DriversRepository`
* -`UserName` - name of user on target computer if we want to create network share on it
* `-Share` - Switch that will create network share on target computer
* `-ShareOnly` - Switch that will skip printer install and only create network share
## Examples
### TODO

## How to create drivers repository
1. In `DriversRepository` create new folder with 'PrinterName'.
2. Next in that folder you have to create folders with names equal to supported system and arch. Like that:
* Xerox7835
    * Windows 7
     * x86
     * x64
    * Windows 10
     * x86
     * x64
3. Now download printer drivers and put it in corresponding directory in our printer folder in 'DriversRepository'
4. After that create `Driver.ini` file in printer directory which must contain that:
`
Name = name of printer driver from ini file
Inix86 = name of inf file with driver for x86 printer installation
Inix64 = name of inf file with driver for x64 printer installation
`
