# Add necessary .NET types
Add-Type -AssemblyName PresentationFramework
# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Creates a form to host dialogs but make it invisible
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
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select a file to split"
    $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    
    if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $FilePath = $OpenFileDialog.FileName
        $SizeUnit = Read-Host "Enter size unit (KB or MB)"
        $SizeValue = [int](Read-Host "Enter size in $SizeUnit")

        $ChunkSize = if ($SizeUnit -eq "KB") {
            $SizeValue * 1024
        } elseif ($SizeUnit -eq "MB") {
            $SizeValue * 1024 * 1024
        } else {
            Write-Output "Invalid size unit! Defaulting to bytes."
            $SizeValue
        }

        Split-File -FilePath $FilePath -ChunkSize $ChunkSize
    } else {
        Write-Output "No file selected."
    }
}

# Function to handle file joining operation
function Handle-JoinFiles {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "Part Files (*.part*)|*.part*|All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select any part file"
    $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')

    if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
        $FilePath = $OpenFileDialog.FileName
        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath) -replace "\.part\d+$", ""

        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Filter = "All Files (*.*)|*.*"
        $SaveFileDialog.Title = "Save joined file as"
        $SaveFileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($FilePath)

        if ($SaveFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
            $OutputFile = $SaveFileDialog.FileName

            # Ask for file type
            $FileType = Read-Host "Enter the file extension/type (ex: txt/jpg/png/pdf, etc.) without the dot"
            if ($FileType) {
                $OutputFile = "$OutputFile.$FileType"
            }

            Join-Files -BaseName $BaseName -OutputFile $OutputFile
        } else {
            Write-Output "No output file specified."
        }
    } else {
        Write-Output "No part file selected."
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

    # Generate a 32-byte key and 16-byte IV from the password
    $Key = [System.Text.Encoding]::UTF8.GetBytes($Password.PadRight(32, '0').Substring(0, 32))
    $IV = New-Object byte[] 16
    [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($IV)

    # Initialize AES encryption
    $Aes = [System.Security.Cryptography.Aes]::Create()
    $Aes.Key = $Key
    $Aes.IV = $IV
    $Encryptor = $Aes.CreateEncryptor()

    # Read the file content into memory
    $FileContent = [System.IO.File]::ReadAllBytes($InputFile)

    # Create a memory stream to hold the encrypted data
    $EncryptedData = New-Object System.IO.MemoryStream

    # Write the custom header to the encrypted data
    $Header = "ENCRYPTED_HEADER"
    $HeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($Header)
    $EncryptedData.Write($HeaderBytes, 0, $HeaderBytes.Length)

    # Write the IV to the encrypted data
    $EncryptedData.Write($IV, 0, $IV.Length)

    # Encrypt the file content and write to the memory stream
    $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($EncryptedData, $Encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $CryptoStream.Write($FileContent, 0, $FileContent.Length)
    $CryptoStream.Close()

    # Overwrite the original file with the encrypted data
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

    # Open the input file for reading
    $FileStream = [System.IO.File]::Open($InputFile, 'Open', 'Read')

    # Read the first bytes for the header
    $HeaderBytes = New-Object byte[] 16
    $FileStream.Read($HeaderBytes, 0, $HeaderBytes.Length) | Out-Null

    # Convert the header bytes to a string and check if it matches the signature
    $Header = [System.Text.Encoding]::UTF8.GetString($HeaderBytes)
    if ($Header -ne "ENCRYPTED_HEADER") {
        Write-Output "This file is not encrypted!"
        $FileStream.Close()
        return
    }

    # Read the IV (next 16 bytes after the header)
    $IV = New-Object byte[] 16
    $FileStream.Read($IV, 0, $IV.Length) | Out-Null

    # Attempt decryption with up to 3 tries
    $Attempts = 0
    $MaxAttempts = 3
    $DecryptedSuccessfully = $false

    while ($Attempts -lt $MaxAttempts -and -not $DecryptedSuccessfully) {
        # Increment the attempt counter
        $Attempts++

        # Generate the key from the password
        $Key = [System.Text.Encoding]::UTF8.GetBytes($Password.PadRight(32, '0').Substring(0, 32))

        # Initialize AES decryption
        $Aes = [System.Security.Cryptography.Aes]::Create()
        $Aes.Key = $Key
        $Aes.IV = $IV

        try {
            $Decryptor = $Aes.CreateDecryptor()

            # Move the file pointer to the position after the header and IV
            $FileStream.Position = 32

            # Create a CryptoStream for decryption
            $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStream, $Decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)

            # Decrypt the file content into memory
            $DecryptedData = New-Object System.IO.MemoryStream
            $Buffer = New-Object byte[] 4096

            while (($BytesRead = $CryptoStream.Read($Buffer, 0, $Buffer.Length)) -gt 0) {
                $DecryptedData.Write($Buffer, 0, $BytesRead)
            }

            # Close the streams
            $CryptoStream.Close()
            $FileStream.Close()

            # Overwrite the original file with decrypted content
            [System.IO.File]::WriteAllBytes($InputFile, $DecryptedData.ToArray())
            $DecryptedData.Close()

            Write-Output "File is decrypted."
            $DecryptedSuccessfully = $true
        } catch {
            Write-Output "Incorrect password. Attempts remaining: $(($MaxAttempts - $Attempts))"

            if ($Attempts -lt $MaxAttempts) {
                $Password = Read-Host "Enter decryption password"
            } else {
                Write-Output "Maximum attempts reached. Decryption failed."
            }
        }
    }

    # Ensure the file stream is closed if still open
    if ($FileStream -and $FileStream.CanRead) {
        $FileStream.Close()
    }
    }
    catch {
        throw "Decryption failed: $($_.Exception.Message)"
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

# Function to handle decryption operation
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

#Create the main window
$window = New-Object System.Windows.Window
$window.Title = "File Splitter and Joiner"
$window.Width = 400
$window.Height = 400  # Reduced height
$window.ResizeMode = "NoResize"
$window.Background = New-SolidColorBrush -R 173 -G 216 -B 230 # LightBlue
$window.WindowStartupLocation = "CenterScreen"

# Create a grid for layout
$grid = New-Object System.Windows.Controls.Grid
$grid.Margin = "10"

# Define grid rows
$rowDefinitions = @(80, 30, 40, 40, 40, 40, 40) # Adjusted row heights for compact layout
foreach ($height in $rowDefinitions) {
    $row = New-Object System.Windows.Controls.RowDefinition
    $row.Height = [System.Windows.GridLength]::Auto
    $null = $grid.RowDefinitions.Add($row)
}

# Title container (a Border for styling)
$titleBorder = New-Object System.Windows.Controls.Border
$titleBorder.BorderBrush = New-SolidColorBrush -R 0 -G 0 -B 0  # Black border
$titleBorder.BorderThickness = [System.Windows.Thickness]::new(2)
$titleBorder.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # SteelBlue background
$titleBorder.Margin = "0,10,0,10"
$titleBorder.CornerRadius = "5"  # Slightly rounded corners
$titleBorder.SetValue([System.Windows.Controls.Grid]::RowProperty, 0)

# Title TextBlock with styling
$titleText = New-Object System.Windows.Controls.TextBlock
$titleText.Text = "File Splitter and Joiner"
$titleText.FontSize = 24
$titleText.FontWeight = "Bold"
$titleText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
$titleText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White text
$titleText.TextAlignment = "Center"
$titleText.VerticalAlignment = "Center"

# Add shadow effect to the title text
$dropShadowEffect = New-Object System.Windows.Media.Effects.DropShadowEffect
$dropShadowEffect.Color = [System.Windows.Media.Color]::FromArgb(100, 0, 0, 0)  # Semi-transparent black shadow
$dropShadowEffect.Direction = 320  # Angle of the shadow
$dropShadowEffect.ShadowDepth = 5  # Distance of shadow
$dropShadowEffect.BlurRadius = 10  # Blur of shadow

$titleText.Effect = $dropShadowEffect

# Add the TextBlock to the Border
$titleBorder.Child = $titleText

# Add the title border to the grid
$null = $grid.Children.Add($titleBorder)

# Add motto text
$motto = New-Object System.Windows.Controls.TextBlock
$motto.Text = "Effortless File Management"
$motto.FontSize = 12
$motto.HorizontalAlignment = "Center"
$motto.Foreground = New-SolidColorBrush -R 0 -G 0 -B 128 # Navy
$motto.SetValue([System.Windows.Controls.Grid]::RowProperty, 1)
$null = $grid.Children.Add($motto)

# Set the grid as the window content
$window.Content = $grid

# Assign the main window
$MainWindow = $window

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
                $MainWindow.Close()  # Gracefully close the main window
            } else {
                Write-Host "MainWindow is not defined."
            }
        }
    }
}

# Create buttons
$buttonNames = @("Split", "Join", "Encrypt", "Decrypt", "Exit")
$buttonColors = @(
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 0; G = 0; B = 139 }      # Darker Blue for Exit
)

for ($i = 0; $i -lt $buttonNames.Length; $i++) {
    # Button container (Border for styling)
    $buttonBorder = New-Object System.Windows.Controls.Border
    $buttonBorder.Background = New-SolidColorBrush -R $buttonColors[$i].R -G $buttonColors[$i].G -B $buttonColors[$i].B
    $buttonBorder.CornerRadius = "5"  # Slightly rounded corners
    $buttonBorder.Padding = "2"
    $buttonBorder.Margin = "0,5,0,5"
    $buttonBorder.Width = 130
    $buttonBorder.Height = 40
    $buttonBorder.HorizontalAlignment = "Center"

    # Button with custom TextBlock for drop shadow effect
    $button = New-Object System.Windows.Controls.Button
    $button.Width = 130
    $button.Height = 40
    $button.Background = [System.Windows.Media.Brushes]::Transparent  # Transparent to let Border handle design
    $button.BorderThickness = "0"  # No border around the button itself
    $button.Padding = "0"

    $buttonText = New-Object System.Windows.Controls.TextBlock
    $buttonText.Text = $buttonNames[$i]
    $buttonText.FontSize = 14
    $buttonText.FontWeight = "Bold"
    $buttonText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
    $buttonText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White text
    $buttonText.HorizontalAlignment = "Center"
    $buttonText.VerticalAlignment = "Center"

    # Adding a DropShadowEffect to the TextBlock
    $buttonText.Effect = New-Object System.Windows.Media.Effects.DropShadowEffect -Property @{
        BlurRadius = 4
        ShadowDepth = 2
        Color = [System.Windows.Media.Color]::FromArgb(255, 0, 0, 0)  # Black shadow
        Opacity = 0.7
    }

    $button.Content = $buttonText
    # Add click event handler
    $button.Add_Click({
        param ($sender, $args)
        HandleButtonClick -Action $sender.Content.Text -MainWindow $MainWindow
    })

    $buttonBorder.Child = $button
    $buttonBorder.SetValue([System.Windows.Controls.Grid]::RowProperty, $i + 2)
    $null = $grid.Children.Add($buttonBorder)
}

# Split Window (1st window)
function CreateSplitWindow {
    param([System.Windows.Window]$MainWindow)  # Accept the main window as a parameter
    $splitWindow = New-Object System.Windows.Window
    $splitWindow.Title = "Split"
    $splitWindow.Width = 400 # Keep original size
    $splitWindow.Height = 400
    $splitWindow.Background = New-SolidColorBrush -R 173 -G 216 -B 230  # Light Blue
    $splitWindow.WindowStartupLocation = "CenterScreen"
    $splitWindow.ResizeMode = "NoResize"  # Prevent resizing

    $grid = New-Object System.Windows.Controls.Grid
    $grid.Margin = "10"

    # Define Rows and Columns
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
    [System.Windows.Controls.Grid]::SetColumnSpan($inputBox, 2)  # Ensure it spans across remaining space
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
    $outputBox.HorizontalAlignment = "Stretch"  # Allow stretching
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
    $startButton.Content = "Start"
    $startButton.Width = 80
    $startButton.Margin = "10,0,10,0"
    $startButton.FontWeight = "Bold"
    $startButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $startButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $startButton.Add_Click({
        if (-not $inputBox.Text -or -not $outputBox.Text -or -not $splitSizeBox.Text) {
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
            [System.Windows.MessageBox]::Show("File successfully split into $chunkNum parts!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
        catch {
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
    $startButton.Content = "Start"
    $startButton.Width = 80
    $startButton.Margin = "10,0,10,0"
    $startButton.FontWeight = "Bold"
    $startButton.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # Steel Blue
    $startButton.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White
    $startButton.Add_Click({
        if (-not $inputBox.Text -or -not $outputBox.Text) {
            [System.Windows.MessageBox]::Show("Please fill in all fields!", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }

        try {
            $inputFile = $inputBox.Text
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile) -replace "\.part\d+$", ""
            $outputDir = $outputBox.Text
            
            # Get all part files
            $fileDir = [System.IO.Path]::GetDirectoryName($inputFile)
            $partFiles = Get-ChildItem -Path $fileDir -Filter "$baseName.part*" | Sort-Object Name
            
            if ($partFiles.Count -eq 0) {
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
            }

            $outputStream.Close()
            [System.Windows.MessageBox]::Show("Files successfully joined!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
        catch {
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
        if ([string]::IsNullOrWhiteSpace($inputBox.Text)) {
            [System.Windows.MessageBox]::Show("Please select a file to encrypt.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if ([string]::IsNullOrWhiteSpace($outputBox.Text)) {
            [System.Windows.MessageBox]::Show("Please enter a password.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if (!(Test-Path $inputBox.Text)) {
            [System.Windows.MessageBox]::Show("Selected file does not exist.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        
        try {
            Encrypt-File -InputFile $inputBox.Text -Password $outputBox.Text
            [System.Windows.MessageBox]::Show("File encrypted successfully!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $encryptionWindow.Close()
        }
        catch {
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
        if ([string]::IsNullOrWhiteSpace($inputBox.Text)) {
            [System.Windows.MessageBox]::Show("Please select a file to decrypt.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if ([string]::IsNullOrWhiteSpace($outputBox.Text)) {
            [System.Windows.MessageBox]::Show("Please enter a password.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
        if (!(Test-Path $inputBox.Text)) {
            [System.Windows.MessageBox]::Show("Selected file does not exist.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }
    
        try {
            Decrypt-File -InputFile $inputBox.Text -Password $outputBox.Text
            [System.Windows.MessageBox]::Show("File decrypted successfully!", "Success", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            $decryptionWindow.Close()
        }
        catch {
            [System.Windows.MessageBox]::Show("Failed to decrypt file: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
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
$window.ShowDialog()
