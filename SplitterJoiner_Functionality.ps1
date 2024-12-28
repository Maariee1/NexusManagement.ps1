# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Creates a form to host dialogs but make it invisible
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.ShowInTaskbar = $false
$form.Opacity = 0
$form.Size = New-Object System.Drawing.Size(1,1)

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

# Function to encrypt a file
function Encrypt-File {
    param (
        [string]$InputFile,   # Path to the file to encrypt
        [string]$Password     # Password for encryption
    )

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

# Function to decrypt a file in place
function Decrypt-File {
    param (
        [string]$InputFile,   # Path to the encrypted file
        [string]$Password     # Password for decryption
    )

    # Open the input file for reading and writing
    $FileStream = [System.IO.File]::Open($InputFile, 'Open', 'ReadWrite')

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

    # Generate the key from the password
    $Key = [System.Text.Encoding]::UTF8.GetBytes($Password.PadRight(32, '0').Substring(0, 32))

    # Initialize AES decryption
    $Aes = [System.Security.Cryptography.Aes]::Create()
    $Aes.Key = $Key
    $Aes.IV = $IV
    $Decryptor = $Aes.CreateDecryptor()

    # Move the file pointer to the position after the header and IV
    $FileStream.Position = 32

    # Create a CryptoStream for decryption
    $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($FileStream, $Decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)

    # Decrypt the file content
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
}

while ($true) {
    Write-Output "Choose an option:"
    Write-Output "1. Split a file"
    Write-Output "2. Join files"
    Write-Output "3. Encryption"
    Write-Output "4. Decryption"
    Write-Output "5. Exit"
    $Choice = Read-Host "Enter your choice"

    switch ($Choice) {
        "1" {
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
        "2" {
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
        "3" {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.Filter = "All Files (*.*)|*.*"
            $OpenFileDialog.Title = "Select a file to encrypt"
            
            if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                $InputFile = $OpenFileDialog.FileName
                $Password = Read-Host "Enter encryption password"
                $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
                $SaveFileDialog.Title = "Save encrypted file"

                if ($FileType) {
                    $OutputFile = "$OutputFile.$FileType"
                }
                    Encrypt-File -InputFile $InputFile -OutputFile $OutputFile -Password $Password        
            }
        }
        "4" {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.Filter = "All Files (*.*)|*.*"
            $OpenFileDialog.Title = "Select a file to decrypt"
            
            if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                $InputFile = $OpenFileDialog.FileName
                $Password = Read-Host "Enter decryption password"
                $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
                $SaveFileDialog.Title = "Save decrypted file"

                if ($FileType) {
                    $OutputFile = "$OutputFile.$FileType"
                }
                    Decrypt-File -InputFile $InputFile -OutputFile $OutputFile -Password $Password           
            }
        }
        "5" {
            Write-Output "Program Terminated."
            $form.Close()
            exit
        }
        default {
            Write-Output "Invalid choice. Please try again."
        }
    }
}


