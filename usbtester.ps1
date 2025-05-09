# Define the text content
$TextContent = @"
##################################
Hello World!
##################################
"@

# Define the output text file path
$TextFilePath = "$env:TEMP\hello_world.txt"

# Save the text to a file
$TextContent | Out-File -Path $TextFilePath -Encoding UTF8

# Get screen resolution
$ScreenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$ScreenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Define the output JPG file path
$ImagePath = "$env:TEMP\hello_world.jpg"

# Load necessary assemblies
try {
    Add-Type -AssemblyName System.Drawing.Common
    Add-Type -AssemblyName System.Windows.Forms
} catch {
    Write-Warning "Could not load necessary assemblies. Please ensure .NET is installed."
    pause
    exit
}

# Create a drawing surface
$Bitmap = New-Object System.Drawing.Bitmap($ScreenWidth, $ScreenHeight)
$Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)

# Set background color (optional)
$BackgroundColor = [System.Drawing.SolidBrush]::White
$Graphics.FillRectangle($BackgroundColor, 0, 0, $ScreenWidth, $ScreenHeight)

# Define font and brush for text
$Font = New-Object System.Drawing.Font("Arial", 36)
$Brush = New-Object System.Drawing.SolidBrush("Black")

# Calculate text position to center it
$StringFormat = New-Object System.Drawing.StringFormat
$StringFormat.Alignment = [System.Drawing.StringAlignment]::Center
$StringFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
$Rectangle = New-Object System.Drawing.RectangleF(0, 0, $ScreenWidth, $ScreenHeight)

# Draw the text
$Graphics.DrawString($TextContent, $Font, $Brush, $Rectangle, $StringFormat)

# Save the bitmap as a JPG
$Bitmap.Save($ImagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Clean up resources
$Font.Dispose()
$Brush.Dispose()
$Graphics.Dispose()
$Bitmap.Dispose()

# Display the image
Start-Process $ImagePath

# Pause the script to allow reading the output
pause
