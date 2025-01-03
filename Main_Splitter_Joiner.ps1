# Adds necessary .NET types
Add-Type -AssemblyName PresentationFramework
# Loads Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Form to host dialogs but make it invisible
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.ShowInTaskbar = $false
$form.Opacity = 0
$form.Size = New-Object System.Drawing.Size(1, 1)

# Function to split a file
function Split-File {
    param (
        [string]$FilePath,
        [int]$ChunkSize
    )

    if (-Not (Test-Path -Path $FilePath)) {
        Write-Output "File not found!"
        return
    }

    $BaseName = [System.IO.Path]::GetFileName($FilePath)
    $FileDir = [System.IO.Path]::GetDirectoryName($FilePath)
    $FileStream = [System.IO.File]::OpenRead($FilePath)
    $Buffer = New-Object byte[] $ChunkSize
    $ChunkNum = 0

    while ($ReadBytes = $FileStream.Read($Buffer, 0, $Buffer.Length)) {
        $ChunkFileName = "$FileDir\$BaseName.part$ChunkNum"
        $ChunkStream = [System.IO.File]::OpenWrite($ChunkFileName)
        $ChunkStream.Write($Buffer, 0, $ReadBytes)
        $ChunkStream.Close()
        $ChunkNum++
    }

    $FileStream.Close()
    Write-Output "File split into $ChunkNum chunks."
}

# Function to join files
function Join-Files {
    param (
        [string]$BaseName,
        [string]$OutputFile
    )

    $FileDir = [System.IO.Path]::GetDirectoryName($OutputFile)
    $PartFiles = Get-ChildItem -Path $FileDir -Filter "$BaseName.part*" | Sort-Object Name

    if ($PartFiles.Count -eq 0) {
        Write-Output "No part files found!"
        return
    }

    $OutputStream = [System.IO.File]::OpenWrite($OutputFile)

    foreach ($PartFile in $PartFiles) {
        $PartStream = [System.IO.File]::OpenRead($PartFile.FullName)
        $Buffer = New-Object byte[] $PartStream.Length
        $ReadBytes = $PartStream.Read($Buffer, 0, $Buffer.Length)
        $OutputStream.Write($Buffer, 0, $ReadBytes)
        $PartStream.Close()
    }

    $OutputStream.Close()
    Write-Output "Files joined into $OutputFile."
}

# Function to handle file splitting operation
function Handle-SplitFile {
    param (
        [string]$FilePath,
        [int]$ChunkSize
    )

    if (-Not (Test-Path -Path $FilePath)) {
        Write-Output "File not found!"
        return
    }

    $BaseName = [System.IO.Path]::GetFileName($FilePath)
    $FileDir = [System.IO.Path]::GetDirectoryName($FilePath)
    $FileStream = [System.IO.File]::OpenRead($FilePath)
    $Buffer = New-Object byte[] $ChunkSize
    $ChunkNum = 0

    while ($ReadBytes = $FileStream.Read($Buffer, 0, $Buffer.Length)) {
        $ChunkFileName = "$FileDir\$BaseName.part$ChunkNum"
        $ChunkStream = [System.IO.File]::OpenWrite($ChunkFileName)
        $ChunkStream.Write($Buffer, 0, $ReadBytes)
        $ChunkStream.Close()
        $ChunkNum++
    }

    $FileStream.Close()
    Write-Output "File split into $ChunkNum chunks."
}

# Function to handle file joining operations
function Handle-JoinFiles {
    param (
        [string]$BaseName,
        [string]$OutputFile
    )

    $FileDir = [System.IO.Path]::GetDirectoryName($BaseName)
    $BaseFileName = [System.IO.Path]::GetFileName($BaseName) -replace "\.part\d+$", ""
    $PartFiles = Get-ChildItem -Path $FileDir -Filter "$BaseFileName.part*" | Sort-Object Name

    if ($PartFiles.Count -eq 0) {
        Write-Output "No part files found!"
        return
    }

    try {
        $OutputStream = [System.IO.File]::OpenWrite($OutputFile)

        foreach ($PartFile in $PartFiles) {
            $PartStream = [System.IO.File]::OpenRead($PartFile.FullName)
            $Buffer = New-Object byte[] $PartStream.Length
            $ReadBytes = $PartStream.Read($Buffer, 0, $Buffer.Length)
            $OutputStream.Write($Buffer, 0, $ReadBytes)
            $PartStream.Close()
            
            # Closes and removes the part files
            Remove-Item -Path $PartFile.FullName -Force
        }

        $OutputStream.Close()
        Write-Output "Files joined into $OutputFile and part files removed."
    }
    catch {
        Write-Error "Error during join operation: $_"
        if ($OutputStream) {
            $OutputStream.Close()
        }
    }
}

function Encrypt-File {
    param (
        [string]$InputFile,
        [string]$Password
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Password)) {
            throw "Password cannot be empty"
        }

    $fileBytes = [System.IO.File]::ReadAllBytes($InputFile)
        if ($fileBytes.Length -ge 16) {
            $headerBytes = $fileBytes[0..15]
            $header = [System.Text.Encoding]::UTF8.GetString($headerBytes)
            if ($header -eq "ENCRYPTED_HEADER") {
                throw "File is already encrypted!"
            }
        }

    # This generates a 32-byte key and 16-byte IV from the password
    $Key = [System.Text.Encoding]::UTF8.GetBytes($Password.PadRight(32, '0').Substring(0, 32))
    $IV = New-Object byte[] 16
    [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($IV)

    # Initialize AES encryption
    $Aes = [System.Security.Cryptography.Aes]::Create()
    $Aes.Key = $Key
    $Aes.IV = $IV
    $Encryptor = $Aes.CreateEncryptor()

    # Reads the file content into memory
    $FileContent = [System.IO.File]::ReadAllBytes($InputFile)

    # Creates a memory stream to hold the encrypted data
    $EncryptedData = New-Object System.IO.MemoryStream

    # Writes the custom header to the encrypted data
    $Header = "ENCRYPTED_HEADER"
    $HeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($Header)
    $EncryptedData.Write($HeaderBytes, 0, $HeaderBytes.Length)

    # Writes the IV to the encrypted data
    $EncryptedData.Write($IV, 0, $IV.Length)

    # Encrypts the file content and write to the memory stream
    $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($EncryptedData, $Encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $CryptoStream.Write($FileContent, 0, $FileContent.Length)
    $CryptoStream.Close()

    # This overwrites the original file with the encrypted data
    [System.IO.File]::WriteAllBytes($InputFile, $EncryptedData.ToArray())
    $EncryptedData.Close()

    Write-Output "File is encrypted."
    }
    catch {
        throw "Encryption failed: $($_.Exception.Message)"
    }
}

# Function to decrypt a file in place
function Decrypt-File {
    param (
        [string]$InputFile,
        [string]$Password
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Password)) {
            throw "Password cannot be empty"
        }

        # Opens the input file for reading
        $FileStream = [System.IO.File]::Open($InputFile, 'Open', 'Read')

        # Reads the first bytes for the header
        $HeaderBytes = New-Object byte[] 16
        $BytesRead = $FileStream.Read($HeaderBytes, 0, $HeaderBytes.Length)
        
        # Checks if we could read enough bytes for the header
        if ($BytesRead -lt 16) {
            $FileStream.Close()
            throw "File is not encrypted (invalid file size)"
        }

        # Converts the header bytes to a string and check if it matches the signature
        $Header = [System.Text.Encoding]::UTF8.GetString($HeaderBytes)
        if ($Header -ne "ENCRYPTED_HEADER") {
            $FileStream.Close()
            throw "File is not encrypted."
        }

        # Reads the IV (next 16 bytes after the header)
        $IV = New-Object byte[] 16
        $BytesRead = $FileStream.Read($IV, 0, $IV.Length)
        
        if ($BytesRead -lt 16) {
            $FileStream.Close()
            throw "File is not encrypted (invalid IV)"
        }

        $Key = [System.Text.Encoding]::UTF8.GetBytes($Password.PadRight(32, '0').Substring(0, 32))
        $Aes = [System.Security.Cryptography.Aes]::Create()
        $Aes.Key = $Key
        $Aes.IV = $IV

        try {
            $Decryptor = $Aes.CreateDecryptor()
            $FileStream.Position = 32

            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStream, $Decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
            $DecryptedData = New-Object System.IO.MemoryStream
            $Buffer = New-Object byte[] 4096

            while (($BytesRead = $CryptoStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
                $DecryptedData.Write($Buffer, 0, $BytesRead)
            }

            $CryptoStream.Close()
            $FileStream.Close()

            [System.IO.File]::WriteAllBytes($InputFile, $DecryptedData.ToArray())
            $DecryptedData.Close()

            return $true
        }
        catch {
            if ($CryptoStream) { $CryptoStream.Close() }
            if ($FileStream) { $FileStream.Close() }
            if ($DecryptedData) { $DecryptedData.Close() }
            return $false
        }
    }
    catch {
        throw $_.Exception.Message
    }
    finally {
        if ($FileStream -and $FileStream.CanRead) {
            $FileStream.Close()
        }
    }
}

function Handle-Encryption {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select a file to encrypt"
    
    if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $InputFile = $OpenFileDialog.FileName
        $Password = Read-Host "Enter encryption password"
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Title = "Save encrypted file"

        Encrypt-File -InputFile $InputFile -Password $Password
    }
}

# Function to handle decryption operations
function Handle-Decryption {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select a file to decrypt"
    
    if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $InputFile = $OpenFileDialog.FileName
        $Password = Read-Host "Enter decryption password"
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Title = "Save decrypted file"

        Decrypt-File -InputFile $InputFile -Password $Password
    }
}

# Function to create a SolidColorBrush from RGB values
function New-SolidColorBrush {
    param (
        [int]$R,
        [int]$G,
        [int]$B
    )
    $color = [System.Windows.Media.Color]::FromArgb(255, $R, $G, $B)
    return New-Object System.Windows.Media.SolidColorBrush($color)
}

# Main window
$window = New-Object System.Windows.Window
$window.Title = "Snip Sync: File Splitter and Joiner"
$window.Width = 400
$window.Height = 400
$window.ResizeMode = "NoResize"
$window.Background = New-SolidColorBrush -R 173 -G 216 -B 230 # LightBlue
$window.WindowStartupLocation = "CenterScreen"

# Grid for layout
$grid = New-Object System.Windows.Controls.Grid
$grid.Margin = "10"

# Define rows
$rowDefinitions = @(170, 50, 50, 50, 50)  # Increase first row height (logo) to 100px
foreach ($height in $rowDefinitions) {
    $row = New-Object System.Windows.Controls.RowDefinition
    $row.Height = [System.Windows.GridLength]::new($height, [System.Windows.GridUnitType]::Pixel)
    $null = $grid.RowDefinitions.Add($row)
}


# Define columns
$columnDefinitions = @(1, 1)  # Two equal-width columns
foreach ($width in $columnDefinitions) {
    $col = New-Object System.Windows.Controls.ColumnDefinition
    $col.Width = [System.Windows.GridLength]::new($width, [System.Windows.GridUnitType]::Star)
    $null = $grid.ColumnDefinitions.Add($col)
}

# # Path to the Logo Image
# $imagePath = "C:\Users\Admin\Documents\GitHub\NexusManagement.ps1\NexusManagement.ps1\SnipSync Logo.png"

# # Check if the file exists
# if (-Not (Test-Path $imagePath)) {
#     [System.Windows.MessageBox]::Show("Error: Logo file not found at $imagePath", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
#     return
# }

# Load the Logo Image
$LogoSource = New-Object System.Windows.Media.Imaging.BitmapImage
$LogoSource.BeginInit()
$LogoSource.UriSource = New-Object System.Uri("SnipSync Logo.png", [System.UriKind]::RelativeOrAbsolute)
$LogoSource.EndInit()

# Create an Image Control for the Logo
$LogoImage = New-Object Windows.Controls.Image
$LogoImage.Source = $LogoSource
$LogoImage.Width = 800  # Scaled down
$LogoImage.Height = 290 # Scaled down
$LogoImage.HorizontalAlignment = "Center"
$LogoImage.VerticalAlignment = "Center"
$LogoImage.Margin = [Windows.Thickness]::new(0, 10, 0, 10)
$LogoImage.SetValue([System.Windows.Controls.Grid]::RowProperty, 0)
$LogoImage.SetValue([System.Windows.Controls.Grid]::ColumnSpanProperty, 2)  # Span across both columns
$grid.Children.Add($LogoImage) | Out-Null

# Function to handle button clicks
function HandleButtonClick {
    param (
        [string]$Action,
        [System.Windows.Window]$MainWindow
    )
    switch ($Action) {
        "Split" {
            CreateSplitWindow -MainWindow $MainWindow
        }
        "Join" {
            CreateJoinWindow -MainWindow $MainWindow
        }
        "Encrypt" {
            CreateEncryptionWindow -MainWindow $MainWindow
        }
        "Decrypt" {
            CreateDecryptionWindow -MainWindow $MainWindow
        }
        "Exit" {
            if ($MainWindow -ne $null) {
                $MainWindow.Close()  # Gracefully closes the main window
            } else {
                Write-Host "MainWindow is not defined."
            }
        }
    }
}

# Buttons data
$buttonData = @(
    @{ Name = "Split"; Row = 1; Column = 0 },
    @{ Name = "Join"; Row = 1; Column = 1 },
    @{ Name = "Encrypt"; Row = 2; Column = 0 },
    @{ Name = "Decrypt"; Row = 2; Column = 1 },
    @{ Name = "Exit"; Row = 3; Column = 0; ColumnSpan = 2 }
)

# Create buttons dynamically
foreach ($data in $buttonData) {
    # Create a Border to wrap the Button
    $border = New-Object System.Windows.Controls.Border
    $border.Width = 150
    $border.Height = 50
    $border.CornerRadius = New-Object System.Windows.CornerRadius 15 # Rounded corners
    $border.HorizontalAlignment = "Center"
    $border.VerticalAlignment = "Center"
    $border.Margin = [Windows.Thickness]::new(5)
    $border.Background = if ($data.Name -eq "Exit") {
        New-SolidColorBrush -R 0 -G 0 -B 139 # DarkBlue
    } else {
        New-SolidColorBrush -R 70 -G 130 -B 180 # SteelBlue
    }

    # Add Drop Shadow Effect to Border
    $borderDropShadow = New-Object System.Windows.Media.Effects.DropShadowEffect
    $borderDropShadow.Color = [System.Windows.Media.Colors]::Black
    $borderDropShadow.Direction = 315
    $borderDropShadow.ShadowDepth = 5
    $borderDropShadow.Opacity = 0.5
    $borderDropShadow.BlurRadius = 10
    $border.Effect = $borderDropShadow

    # Create the Button inside the Border
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $data.Name
    $button.FontSize = 14
    $button.FontWeight = "Bold"
    $button.Foreground = [System.Windows.Media.Brushes]::White
    $button.Background = [System.Windows.Media.Brushes]::Transparent
    $button.BorderThickness = [System.Windows.Thickness]::new(0) # Remove default button border

    # Attach button click handler
    $button.Add_Click({
        param ($sender, $args)
        HandleButtonClick -Action $sender.Content -MainWindow $MainWindow
    })

    # Add the Button as a child of the Border
    $border.Child = $button

    # Set position in the grid
    $border.SetValue([System.Windows.Controls.Grid]::RowProperty, $data.Row)
    $border.SetValue([System.Windows.Controls.Grid]::ColumnProperty, $data.Column)
    if ($data.ContainsKey("ColumnSpan")) {
        $border.SetValue([System.Windows.Controls.Grid]::ColumnSpanProperty, $data.ColumnSpan)
    }

    # Add Border (with Button inside) to the Grid
    $grid.Children.Add($border) | Out-Null
}



# Set the grid as the window content
$window.Content = $grid


# Split Window (1st window)
function CreateSplitWindow {
    param([System.Windows.Window]$MainWindow)  # Accepts the main window as a parameter
    $splitWindow = New-Object System.Windows.Window
    $splitWindow.Title = "Split"
    $splitWindow.Width = 400 # Keeps original size
    $splitWindow.Height = 400
    $splitWindow.Background = New-SolidColorBrush -R 173 -G 216 -B 230  # Light Blue
    $splitWindow.WindowStartupLocation = "CenterScreen"
    $splitWindow.ResizeMode = "NoResize"  # Prevents resizing

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "10"

    # Rows and Columns
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Title
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Input File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Output File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Split File Size
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Instructions
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Buttons

    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" })) # Labels
    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))   # Textboxes fill remaining space
    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" })) # Extra Controls (e.g., dropdown)

    # Title
    $titleBorder = New-Object System.Windows.Controls.Border
    $titleBorder.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $titleBorder.CornerRadius = "5"
    $titleBorder.Padding = "10"
    $titleBorder.Margin = "0,0,0,20"
    $titleBorder.HorizontalAlignment = "Stretch"

    $titleText = New-Object System.Windows.Controls.TextBlock
    $titleText.Text = "Split Files"
    $titleText.FontSize = 24
    $titleText.FontWeight = "Bold"
    $titleText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
    $titleText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White
    $titleText.HorizontalAlignment = "Center"

    $titleBorder.Child = $titleText
    [System.Windows.Controls.Grid]::SetColumnSpan($titleBorder, 3)
    [System.Windows.Controls.Grid]::SetRow($titleBorder, 0)
    $null = $grid.Children.Add($titleBorder)

    # Select file button
    $inputButton = New-Object System.Windows.Controls.Button
    $inputButton.Content = "Select File"
    $inputButton.Width = 80
    $inputButton.Margin = "0,10,10,10"
    $inputButton.FontWeight = "Bold"   
    $inputButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $inputButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White

    $inputButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "All Files (*.*)|*.*"
        $OpenFileDialog.Title = "Select a file to split"
        $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $inputBox.Text = $OpenFileDialog.FileName
        }
    })
    [System.Windows.Controls.Grid]::SetRow($inputButton, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputButton, 0)
    $null = $grid.Children.Add($inputButton)

    $inputBox = New-Object System.Windows.Controls.TextBox
    $inputBox.Margin = "0,10,10,10"
    $inputBox.Height = 25
    $inputBox.HorizontalAlignment = "Stretch"  # Allow stretching
    $inputBox.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($inputBox, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputBox, 1)
    [System.Windows.Controls.Grid]::SetColumnSpan($inputBox, 2)  # Ensuring taht it spans across remaining space
    $null = $grid.Children.Add($inputBox)

    # Select folder button
    $outputButton = New-Object System.Windows.Controls.Button
    $outputButton.Content = "Select Folder"
    $outputButton.Width = 80
    $outputButton.Margin = "0,10,10,10"
    $outputButton.FontWeight = "Bold"   
    $outputButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $outputButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White

    $outputButton.Add_Click({
        $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $FolderBrowser.Description = "Select output folder"
        
        if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $outputBox.Text = $FolderBrowser.SelectedPath
        }
    })
    [System.Windows.Controls.Grid]::SetRow($outputButton, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputButton, 0)
    $null = $grid.Children.Add($outputButton)

    $outputBox = New-Object System.Windows.Controls.TextBox
    $outputBox.Margin = "0,10,10,10"
    $outputBox.Height = 25
    $outputBox.HorizontalAlignment = "Stretch"  # Allosw stretching
    $outputBox.VerticalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($outputBox, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputBox, 1)
    [System.Windows.Controls.Grid]::SetColumnSpan($outputBox, 2)  # Ensure it spans across remaining space
    $null = $grid.Children.Add($outputBox)

    # Split File Size
    $splitLabel = New-Object System.Windows.Controls.TextBlock
    $splitLabel.Text = "Split file size:"
    $splitLabel.Margin = "0,10,10,10"
    [System.Windows.Controls.Grid]::SetRow($splitLabel, 3)
    [System.Windows.Controls.Grid]::SetColumn($splitLabel, 0)
    $null = $grid.Children.Add($splitLabel)

    $splitSizeBox = New-Object System.Windows.Controls.TextBox
    $splitSizeBox.Margin = "0,10,10,10"
    $splitSizeBox.Height = 25
    $splitSizeBox.Width = 250
    [System.Windows.Controls.Grid]::SetRow($splitSizeBox, 3)
    [System.Windows.Controls.Grid]::SetColumn($splitSizeBox, 1)
    $null = $grid.Children.Add($splitSizeBox)

    $unitBox = New-Object System.Windows.Controls.ComboBox
    $unitBox.Margin = "75,10,10,10"
    $unitBox.Height = 25
    $unitBox.Width = 150
    $unitBox.Items.Add("Kbytes")
    $unitBox.Items.Add("Mbytes")
    $unitBox.SelectedIndex = 0
    [System.Windows.Controls.Grid]::SetRow($unitBox, 3)
    [System.Windows.Controls.Grid]::SetColumn($unitBox, 2)
    $null = $grid.Children.Add($unitBox)

    # Instructions
    $instructionText = New-Object System.Windows.Controls.TextBlock
    $instructionText.Text = "To split a file, please first open the input file. After pressing 'Start', the output files will go into the specified output location."
    $instructionText.TextWrapping = "Wrap"
    $instructionText.Margin = "0,20,0,10"
    [System.Windows.Controls.Grid]::SetColumnSpan($instructionText, 3)
    [System.Windows.Controls.Grid]::SetRow($instructionText, 4)
    $null = $grid.Children.Add($instructionText)

    # Buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = "0,10,0,0"
    [System.Windows.Controls.Grid]::SetColumnSpan($buttonPanel, 3)
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 5)

    #Start Button 
    $startButton = New-Object System.Windows.Controls.Button
    $startButton.Content = "Split"
    $startButton.Width = 80
    $startButton.Margin = "10,0,10,0"
    $startButton.FontWeight = "Bold"
    $startButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $startButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White

    #This is where split functionality happens in this window
$startButton.Add_Click({
    if (-not $inputBox.Text -or -not $outputBox.Text -or -not $splitSizeBox.Text) {
        Write-Host "Error: Please fill in all fields!" -ForegroundColor Red
        [System.Windows.MessageBox]::Show("Please fill in all fields!", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    $size = [int]$splitSizeBox.Text
    $unit = $unitBox.SelectedItem.ToString()

    $chunkSize = switch ($unit) {
        "Kbytes" { $size * 1024 }
        "Mbytes" { $size * 1024 * 1024 }
    }

    try {
        $inputFile = $inputBox.Text
        $baseName = [System.IO.Path]::GetFileName($inputFile)
        $outputDir = $outputBox.Text

        $fileStream = [System.IO.File]::OpenRead($inputFile)
        $buffer = New-Object byte[] $chunkSize
        $chunkNum = 0

        while ($bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)) {
            $chunkPath = Join-Path $outputDir "$baseName.part$chunkNum"
            $chunkStream = [System.IO.File]::OpenWrite($chunkPath)
            $chunkStream.Write($buffer, 0, $bytesRead)
            $chunkStream.Close()
            $chunkNum++
        }

        $fileStream.Close()
        Write-Host "Success: File successfully split into $chunkNum parts!" -ForegroundColor Green
        [System.Windows.MessageBox]::Show("File successfully split into $chunkNum parts!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
    catch {
        Write-Host "Error: Unable to split file. $_" -ForegroundColor Red
        [System.Windows.MessageBox]::Show("Error splitting file: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
})

    $buttonPanel.Children.Add($startButton)

    #Close Button
    $closeButton = New-Object System.Windows.Controls.Button
    $closeButton.Content = "Close"
    $closeButton.Width = 80
    $closeButton.Margin = "10,0,10,0"
    $closeButton.FontWeight = "Bold"
    $closeButton.Background = New-SolidColorBrush -R 0 -G 0 -B 139  # Darker Blue
    $closeButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $closeButton.Add_Click({
        $splitWindow.Hide()
        return $null})
    $buttonPanel.Children.Add($closeButton)

    $null = $grid.Children.Add($buttonPanel)

    $splitWindow.Content = $grid
    $splitWindow.ShowDialog()
}

#Join window (2nd Window)
function CreateJoinWindow {
    $joinWindow = New-Object System.Windows.Window
    $joinWindow.Title = "Join"
    $joinWindow.Width = 400# Match the main window width
    $joinWindow.Height = 400  # Match the main window height
    $joinWindow.Background = New-SolidColorBrush -R 173 -G 216 -B 230  # Light Blue
    $joinWindow.WindowStartupLocation = "CenterScreen"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "10"

    # Define Rows and Columns
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Title
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Input File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Output File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Instructions
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Buttons

    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" })) # Labels
    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))   # Textboxes expand

    # Title with Container
    $titleBorder = New-Object System.Windows.Controls.Border
    $titleBorder.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $titleBorder.CornerRadius = "5"
    $titleBorder.Padding = "10"
    $titleBorder.Margin = "0,0,0,20"
    $titleBorder.HorizontalAlignment = "Stretch"

    $titleText = New-Object System.Windows.Controls.TextBlock
    $titleText.Text = "File Join"
    $titleText.FontSize = 24
    $titleText.FontWeight = "Bold"
    $titleText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
    $titleText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White
    $titleText.HorizontalAlignment = "Center"

    $titleBorder.Child = $titleText

    [System.Windows.Controls.Grid]::SetColumnSpan($titleBorder, 2)
    [System.Windows.Controls.Grid]::SetRow($titleBorder, 0)
    $null = $grid.Children.Add($titleBorder)

    #select file button
    $inputButton = New-Object System.Windows.Controls.Button
    $inputButton.Content = "Select File"
    $inputButton.Width = 80
    $inputButton.Margin = "0,10,10,10"
    $inputButton.FontWeight = "Bold"   
    $inputButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $inputButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $inputButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "Part Files (*.part*)|*.part*|All Files (*.*)|*.*"
        $OpenFileDialog.Title = "Select any part file"
        $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
        
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $inputBox.Text = $OpenFileDialog.FileName
        }
    })
    [System.Windows.Controls.Grid]::SetRow($inputButton, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputButton, 0)
    $null = $grid.Children.Add($inputButton)

    $inputBox = New-Object System.Windows.Controls.TextBox
    $inputBox.Margin = "0,10,10,10"
    $inputBox.Height = 25
    [System.Windows.Controls.Grid]::SetRow($inputBox, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputBox, 1)
    $null = $grid.Children.Add($inputBox)

    #select folder button
    $outputButton = New-Object System.Windows.Controls.Button
    $outputButton.Content = "Select Folder"
    $outputButton.Width = 80
    $outputButton.Margin = "0,10,10,10"
    $outputButton.FontWeight = "Bold"   
    $outputButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $outputButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $outputButton.Add_Click({
        $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $FolderBrowser.Description = "Select output folder"
        
        if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $outputBox.Text = $FolderBrowser.SelectedPath
        }
    })
    [System.Windows.Controls.Grid]::SetRow($outputButton, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputButton, 0)
    $null = $grid.Children.Add($outputButton)

    $outputBox = New-Object System.Windows.Controls.TextBox
    $outputBox.Margin = "0,10,10,10"
    $outputBox.Height = 25
    [System.Windows.Controls.Grid]::SetRow($outputBox, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputBox, 1)
    $null = $grid.Children.Add($outputBox)

    # Instructions
    $instructionText = New-Object System.Windows.Controls.TextBlock
    $instructionText.Text = "To join a set of files, open the file as input. The output will be created in the specified output location."
    $instructionText.TextWrapping = "Wrap"
    $instructionText.Margin = "0,20,0,10"
    [System.Windows.Controls.Grid]::SetColumnSpan($instructionText, 2)
    [System.Windows.Controls.Grid]::SetRow($instructionText, 3)
    $null = $grid.Children.Add($instructionText)

    # Buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = "0,10,0,0"
    [System.Windows.Controls.Grid]::SetColumnSpan($buttonPanel, 2)
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 4)
    #Start Button
    $startButton = New-Object System.Windows.Controls.Button
    $startButton.Content = "Join"
    $startButton.Width = 80
    $startButton.Margin = "10,0,10,0"
    $startButton.FontWeight = "Bold"
    $startButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $startButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White

    # This is where the join functionality happens in this window
    $startButton.Add_Click({
        if (-not $inputBox.Text -or -not $outputBox.Text) {
            Write-Host "Error: Please fill in all fields!" -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Please fill in all fields!", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
    
        try {
            $inputFile = $inputBox.Text
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile) -replace "\.part\d+$", ""
            $outputDir = $outputBox.Text
            
            # Gets all part files
            $fileDir = [System.IO.Path]::GetDirectoryName($inputFile)
            $partFiles = Get-ChildItem -Path $fileDir -Filter "$baseName.part*" | Sort-Object Name
            
            if ($partFiles.Count -eq 0) {
                Write-Host "Error: No part files found!" -ForegroundColor Red
                throw "No part files found!"
            }
    
            $outputPath = Join-Path $outputDir $baseName
            $outputStream = [System.IO.File]::OpenWrite($outputPath)
    
            foreach ($partFile in $partFiles) {
                $partStream = [System.IO.File]::OpenRead($partFile.FullName)
                $buffer = New-Object byte[] $partStream.Length
                $bytesRead = $partStream.Read($buffer, 0, $buffer.Length)
                $outputStream.Write($buffer, 0, $bytesRead)
                $partStream.Close()
                
                # Removes the part file after it's been processed
                Remove-Item -Path $partFile.FullName -Force
            }
    
            $outputStream.Close()
            Write-Host "Success: Files successfully joined." -ForegroundColor Green
            [System.Windows.MessageBox]::Show("Files successfully joined.", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
        catch {
            Write-Host "Error: Unable to join files. $_" -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Error joining files: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $buttonPanel.Children.Add($startButton)
    #Close Button
    $closeButton = New-Object System.Windows.Controls.Button
    $closeButton.Content = "Close"
    $closeButton.Width = 80
    $closeButton.Margin = "10,0,10,0"
    $closeButton.FontWeight = "Bold"
    $closeButton.Background = New-SolidColorBrush -R 0 -G 0 -B 139  # Darker Blue
    $closeButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $closeButton.Add_Click({
        $joinWindow.Hide()
    return $null})
    $buttonPanel.Children.Add($closeButton)

    $null = $grid.Children.Add($buttonPanel)

    $joinWindow.Content = $grid
    $joinWindow.ShowDialog()
}
#Encryption window (3rd Window)
function CreateEncryptionWindow { 
    $encryptionWindow = New-Object System.Windows.Window
    $encryptionWindow.Title = "Encryption"
    $encryptionWindow.Width = 400  # Match the main window width
    $encryptionWindow.Height = 400  # Match the main window height
    $encryptionWindow.Background = New-SolidColorBrush -R 173 -G 216 -B 230  # Light Blue
    $encryptionWindow.WindowStartupLocation = "CenterScreen"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "10"

    # Define Rows and Columns
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Title
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Input File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Output File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Instructions
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Buttons

    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" })) # Labels
    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))   # Textboxes expand

    # Title with Container
    $titleBorder = New-Object System.Windows.Controls.Border
    $titleBorder.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $titleBorder.CornerRadius = "5"
    $titleBorder.Padding = "10"
    $titleBorder.Margin = "0,0,0,20"
    $titleBorder.HorizontalAlignment = "Stretch"

    $titleText = New-Object System.Windows.Controls.TextBlock
    $titleText.Text = "File Encryption"
    $titleText.FontSize = 24
    $titleText.FontWeight = "Bold"
    $titleText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
    $titleText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White
    $titleText.HorizontalAlignment = "Center"

    $titleBorder.Child = $titleText
    [System.Windows.Controls.Grid]::SetColumnSpan($titleBorder, 2)
    [System.Windows.Controls.Grid]::SetRow($titleBorder, 0)
    $null = $grid.Children.Add($titleBorder)

    # Select File Button
    $inputButton = New-Object System.Windows.Controls.Button
    $inputButton.Content = "Select File"
    $inputButton.Width = 80
    $inputButton.Margin = "0,10,10,10"
    $inputButton.FontWeight = "Bold"   
    $inputButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $inputButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $inputButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "All Files (*.*)|*.*"
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $inputBox.Text = $OpenFileDialog.FileName
        }
    })
    [System.Windows.Controls.Grid]::SetRow($inputButton, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputButton, 0)
    $null = $grid.Children.Add($inputButton)

    $inputBox = New-Object System.Windows.Controls.TextBox
    $inputBox.Margin = "0,10,10,10"
    $inputBox.Height = 25
    [System.Windows.Controls.Grid]::SetRow($inputBox, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputBox, 1)
    $null = $grid.Children.Add($inputBox)

    # Select Output Folder Button
    $outputLabel = New-Object System.Windows.Controls.TextBlock
    $outputLabel.Text = "Password Key:"
    $outputLabel.Margin = "0,10,10,10"
    [System.Windows.Controls.Grid]::SetRow($outputLabel, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputLabel, 0)
    $null = $grid.Children.Add($outputLabel)

    $outputBox = New-Object System.Windows.Controls.TextBox
    $outputBox.Margin = "0,10,10,10"
    $outputBox.Height = 25
    [System.Windows.Controls.Grid]::SetRow($outputBox, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputBox, 1)
    $null = $grid.Children.Add($outputBox)

    # Create a Grid for password input and toggle button
    $passwordGrid = New-Object System.Windows.Controls.Grid
    $null = $passwordGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
    $null = $passwordGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))

    # Create password box
    $outputBox = New-Object System.Windows.Controls.PasswordBox
    $outputBox.Height = 25
    $outputBox.Margin = "0,10,5,10"
    [System.Windows.Controls.Grid]::SetColumn($outputBox, 0)
    $null = $passwordGrid.Children.Add($outputBox)

    # Create text box (initially hidden)
    $outputTextBox = New-Object System.Windows.Controls.TextBox
    $outputTextBox.Height = 25
    $outputTextBox.Margin = "0,10,5,10"
    $outputTextBox.Visibility = "Collapsed"
    [System.Windows.Controls.Grid]::SetColumn($outputTextBox, 0)
    $null = $passwordGrid.Children.Add($outputTextBox)

    # Create toggle button with eye icon
    $toggleButton = New-Object System.Windows.Controls.Button
    $toggleButton.Width = 30
    $toggleButton.Height = 25
    $toggleButton.Margin = "0,10,10,10"
    $toggleButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180
    $toggleButton.BorderThickness = "0"

    # Creates eye icon (if the user want to see the password or censor it)
    $eyePath = New-Object System.Windows.Shapes.Path
    $eyePath.Data = [System.Windows.Media.Geometry]::Parse("M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z")
    $eyePath.Fill = New-SolidColorBrush -R 255 -G 255 -B 255
    $eyePath.Width = 16
    $eyePath.Height = 16
    $eyePath.Stretch = "Uniform"

    $toggleButton.Content = $eyePath
    [System.Windows.Controls.Grid]::SetColumn($toggleButton, 1)

    # Adds toggle functionality
    $toggleButton.Add_Click({
        if ($outputBox.Visibility -eq "Visible") {
            $outputTextBox.Text = $outputBox.Password
            $outputBox.Visibility = "Collapsed"
            $outputTextBox.Visibility = "Visible"
        } else {
            $outputBox.Password = $outputTextBox.Text
            $outputBox.Visibility = "Visible"
            $outputTextBox.Visibility = "Collapsed"
        }
    })

    $null = $passwordGrid.Children.Add($toggleButton)

    # Adds the password grid to the main grid
    [System.Windows.Controls.Grid]::SetRow($passwordGrid, 2)
    [System.Windows.Controls.Grid]::SetColumn($passwordGrid, 1)
    $null = $grid.Children.Add($passwordGrid)

    # Instructions
    $instructionText = New-Object System.Windows.Controls.TextBlock
    $instructionText.Text = "To encrypt a file, select the input file and enter your chosen password key."
    $instructionText.TextWrapping = "Wrap"
    $instructionText.Margin = "0,20,0,10"
    [System.Windows.Controls.Grid]::SetColumnSpan($instructionText, 2)
    [System.Windows.Controls.Grid]::SetRow($instructionText, 3)
    $null = $grid.Children.Add($instructionText)

    # Buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = "0,10,0,0"
    [System.Windows.Controls.Grid]::SetColumnSpan($buttonPanel, 2)
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 4)

    $startButton = New-Object System.Windows.Controls.Button
    $startButton.Content = "Encrypt"
    $startButton.Width = 80
    $startButton.Margin = "10,0,10,0"
    $startButton.FontWeight = "Bold"
    $startButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $startButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $startButton.Add_Click({
        $password = if ($outputBox.Visibility -eq "Visible") { $outputBox.Password } else { $outputTextBox.Text }
    
        if ([string]::IsNullOrWhiteSpace($inputBox.Text)) {
            Write-Host "Error: Please select a file to encrypt." -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Please select a file to encrypt.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Host "Error: Please enter a password." -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Please enter a password.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if (!(Test-Path $inputBox.Text)) {
            Write-Host "Error: Selected file does not exist." -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Selected file does not exist.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        try {
            Encrypt-File -InputFile $inputBox.Text -Password $password
            Write-Host "Success: File encrypted successfully!" -ForegroundColor Green
            [System.Windows.MessageBox]::Show("File encrypted successfully!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $encryptionWindow.Close()
        }
        catch {
            Write-Host "Error: Failed to encrypt file: $($_.Exception.Message)" -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Failed to encrypt file: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
    
    $buttonPanel.Children.Add($startButton)

    $closeButton = New-Object System.Windows.Controls.Button
    $closeButton.Content = "Close"
    $closeButton.Width = 80
    $closeButton.Margin = "10,0,10,0"
    $closeButton.FontWeight = "Bold"
    $closeButton.Background = New-SolidColorBrush -R 0 -G 0 -B 139  # Darker Blue
    $closeButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $closeButton.Add_Click({
        $encryptionWindow.Hide()
    })

    $buttonPanel.Children.Add($closeButton)
    $null = $grid.Children.Add($buttonPanel)
    $encryptionWindow.Content = $grid
    $encryptionWindow.ShowDialog()
}
#Decryption Window ()
function CreateDecryptionWindow { 
    $decryptionWindow = New-Object System.Windows.Window
    $decryptionWindow.Title = "Decryption"
    $decryptionWindow.Width = 400  # Match the main window width
    $decryptionWindow.Height = 400  # Match the main window height
    $decryptionWindow.Background = New-SolidColorBrush -R 173 -G 216 -B 230  # Light Blue
    $decryptionWindow.WindowStartupLocation = "CenterScreen"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "10"

    # Define Rows and Columns
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Title
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Input File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Output File
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Instructions
    $null = $grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{ Height = "Auto" }))  # Buttons
    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" })) # Labels
    $null = $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))   # Textboxes expand

    # Title with Container
    $titleBorder = New-Object System.Windows.Controls.Border
    $titleBorder.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $titleBorder.CornerRadius = "5"
    $titleBorder.Padding = "10"
    $titleBorder.Margin = "0,0,0,20"
    $titleBorder.HorizontalAlignment = "Stretch"

    $titleText = New-Object System.Windows.Controls.TextBlock
    $titleText.Text = "File Decryption"
    $titleText.FontSize = 24
    $titleText.FontWeight = "Bold"
    $titleText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
    $titleText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White
    $titleText.HorizontalAlignment = "Center"

    $titleBorder.Child = $titleText

    [System.Windows.Controls.Grid]::SetColumnSpan($titleBorder, 2)
    [System.Windows.Controls.Grid]::SetRow($titleBorder, 0)
    $null = $grid.Children.Add($titleBorder)

    # Select File Button
    $inputButton = New-Object System.Windows.Controls.Button
    $inputButton.Content = "Select File"
    $inputButton.Width = 80
    $inputButton.Margin = "0,10,10,10"
    $inputButton.FontWeight = "Bold"   
    $inputButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $inputButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $inputButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "All Files (*.*)|*.*"
        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $inputBox.Text = $OpenFileDialog.FileName
        }
    })
    [System.Windows.Controls.Grid]::SetRow($inputButton, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputButton, 0)
    $null = $grid.Children.Add($inputButton)

    $inputBox = New-Object System.Windows.Controls.TextBox
    $inputBox.Margin = "0,10,10,10"
    $inputBox.Height = 25
    [System.Windows.Controls.Grid]::SetRow($inputBox, 1)
    [System.Windows.Controls.Grid]::SetColumn($inputBox, 1)
    $null = $grid.Children.Add($inputBox)

    # Select Output Folder Button
    $outputLabel = New-Object System.Windows.Controls.TextBlock
    $outputLabel.Text = "Password Key:"
    $outputLabel.Margin = "0,10,10,10"
    [System.Windows.Controls.Grid]::SetRow($outputLabel, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputLabel, 0)
    $null = $grid.Children.Add($outputLabel)

    $outputBox = New-Object System.Windows.Controls.TextBox
    $outputBox.Margin = "0,10,10,10"
    $outputBox.Height = 25
    [System.Windows.Controls.Grid]::SetRow($outputBox, 2)
    [System.Windows.Controls.Grid]::SetColumn($outputBox, 1)
    $null = $grid.Children.Add($outputBox)

    # Create a Grid for password input and toggle button
    $passwordGrid = New-Object System.Windows.Controls.Grid
    $null = $passwordGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
    $null = $passwordGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))

    # Create password box
    $outputBox = New-Object System.Windows.Controls.PasswordBox
    $outputBox.Height = 25
    $outputBox.Margin = "0,10,5,10"
    [System.Windows.Controls.Grid]::SetColumn($outputBox, 0)
    $null = $passwordGrid.Children.Add($outputBox)

    # Create text box (initially hidden)
    $outputTextBox = New-Object System.Windows.Controls.TextBox
    $outputTextBox.Height = 25
    $outputTextBox.Margin = "0,10,5,10"
    $outputTextBox.Visibility = "Collapsed"
    [System.Windows.Controls.Grid]::SetColumn($outputTextBox, 0)
    $null = $passwordGrid.Children.Add($outputTextBox)

    # Create toggle button with eye icon
    $toggleButton = New-Object System.Windows.Controls.Button
    $toggleButton.Width = 30
    $toggleButton.Height = 25
    $toggleButton.Margin = "0,10,10,10"
    $toggleButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180
    $toggleButton.BorderThickness = "0"

    # Create eye icon
    $eyePath = New-Object System.Windows.Shapes.Path
    $eyePath.Data = [System.Windows.Media.Geometry]::Parse("M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z")
    $eyePath.Fill = New-SolidColorBrush -R 255 -G 255 -B 255
    $eyePath.Width = 16
    $eyePath.Height = 16
    $eyePath.Stretch = "Uniform"

    $toggleButton.Content = $eyePath
    [System.Windows.Controls.Grid]::SetColumn($toggleButton, 1)

    # Add toggle functionality
    $toggleButton.Add_Click({
        if ($outputBox.Visibility -eq "Visible") {
            $outputTextBox.Text = $outputBox.Password
            $outputBox.Visibility = "Collapsed"
            $outputTextBox.Visibility = "Visible"
        } else {
            $outputBox.Password = $outputTextBox.Text
            $outputBox.Visibility = "Visible"
            $outputTextBox.Visibility = "Collapsed"
        }
    })

    $null = $passwordGrid.Children.Add($toggleButton)

    # Add the password grid to the main grid
    [System.Windows.Controls.Grid]::SetRow($passwordGrid, 2)
    [System.Windows.Controls.Grid]::SetColumn($passwordGrid, 1)
    $null = $grid.Children.Add($passwordGrid)

    # Instructions
    $instructionText = New-Object System.Windows.Controls.TextBlock
    $instructionText.Text = "To decrypt a file, select the input file and enter your chosen password key."
    $instructionText.TextWrapping = "Wrap"
    $instructionText.Margin = "0,20,0,10"
    [System.Windows.Controls.Grid]::SetColumnSpan($instructionText, 2)
    [System.Windows.Controls.Grid]::SetRow($instructionText, 3)
    $null = $grid.Children.Add($instructionText)

    # Buttons
    $buttonPanel = New-Object System.Windows.Controls.StackPanel
    $buttonPanel.Orientation = "Horizontal"
    $buttonPanel.HorizontalAlignment = "Center"
    $buttonPanel.Margin = "0,10,0,0"
    [System.Windows.Controls.Grid]::SetColumnSpan($buttonPanel, 2)
    [System.Windows.Controls.Grid]::SetRow($buttonPanel, 4)

    $startButton = New-Object System.Windows.Controls.Button
    $startButton.Content = "Decrypt"
    $startButton.Width = 80
    $startButton.Margin = "10,0,10,0"
    $startButton.FontWeight = "Bold"
    $startButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $startButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $startButton.Add_Click({
        $password = if ($outputBox.Visibility -eq "Visible") { $outputBox.Password } else { $outputTextBox.Text }
        $maxAttempts = 3
        $currentAttempt = 1
    
        if ([string]::IsNullOrWhiteSpace($inputBox.Text)) {
            Write-Host "Error: Please select a file to decrypt." -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Please select a file to decrypt.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Host "Error: Please enter a password." -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Please enter a password.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if (!(Test-Path $inputBox.Text)) {
            Write-Host "Error: Selected file does not exist." -ForegroundColor Red
            [System.Windows.MessageBox]::Show("Selected file does not exist.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
    
        while ($currentAttempt -le $maxAttempts) {
            try {
                $result = Decrypt-File -InputFile $inputBox.Text -Password $password
    
                if ($result) {
                    Write-Host "Success: File decrypted successfully!" -ForegroundColor Green
                    [System.Windows.MessageBox]::Show("File decrypted successfully!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                    $decryptionWindow.Close()
                    return
                } else {
                    $remainingAttempts = $maxAttempts - $currentAttempt
                    if ($remainingAttempts -gt 0) {
                        Write-Host "Warning: Incorrect password. $remainingAttempts attempts remaining." -ForegroundColor Yellow
                        $response = [System.Windows.MessageBox]::Show(
                            "Incorrect password. $remainingAttempts attempts remaining.`nWould you like to try again?",
                            "Decryption Failed",
                            [System.Windows.MessageBoxButton]::YesNo,
                            [System.Windows.MessageBoxImage]::Warning
                        )
    
                        if ($response -eq [System.Windows.MessageBoxResult]::Yes) {
                            $currentAttempt++
                            $password = Read-Host "Enter decryption password"
                            if ($outputBox.Visibility -eq "Visible") {
                                $outputBox.Password = $password
                            } else {
                                $outputTextBox.Text = $password
                            }
                        } else {
                            Write-Host "Info: User chose not to retry decryption." -ForegroundColor Cyan
                            $decryptionWindow.Close()
                            return
                        }
                    } else {
                        Write-Host "Error: Maximum password attempts exceeded. Exiting decryption." -ForegroundColor Red
                        [System.Windows.MessageBox]::Show(
                            "Maximum password attempts exceeded. Returning to main menu.",
                            "Decryption Failed",
                            [System.Windows.MessageBoxButton]::OK,
                            [System.Windows.MessageBoxImage]::Error
                        )
                        $decryptionWindow.Close()
                        return
                    }
                }
            }
            catch {
                Write-Host "Error: Failed to decrypt file: $($_.Exception.Message)" -ForegroundColor Red
                [System.Windows.MessageBox]::Show("Failed to decrypt file: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                $decryptionWindow.Close()
                return
            }
        }
    })
    
    $buttonPanel.Children.Add($startButton)

    $closeButton = New-Object System.Windows.Controls.Button
    $closeButton.Content = "Close"
    $closeButton.Width = 80
    $closeButton.Margin = "10,0,10,0"
    $closeButton.FontWeight = "Bold"
    $closeButton.Background = New-SolidColorBrush -R 0 -G 0 -B 139  # Darker Blue
    $closeButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $closeButton.Add_Click({
        $decryptionWindow.Hide()
    })

    $buttonPanel.Children.Add($closeButton)
    $null = $grid.Children.Add($buttonPanel)
    $decryptionWindow.Content = $grid
    $decryptionWindow.ShowDialog()
}

# Assign the main window
$MainWindow = $window

# Add the grid to the window
$window.Content = $grid

# Show the window
$window.ShowDialog() | Out-Null
