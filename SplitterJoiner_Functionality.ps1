# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Security

# Creates a form to host dialogs but make it invisible
$form = New-Object System.Windows.Forms.Form
@ -10,6 +11,118 @@ $form.ShowInTaskbar = $false
$form.Opacity = 0
$form.Size = New-Object System.Drawing.Size(1,1)

# Function to encrypt file
function Encrypt-FileContent {
    param (
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Password
    )
    
    try {
        # Read the input file
        $FileContent = [System.IO.File]::ReadAllBytes($InputFile)
        
        # Generate salt
        $Salt = New-Object byte[] 16
        $RNG = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $RNG.GetBytes($Salt)
        
        # Create AES object
        $AES = New-Object System.Security.Cryptography.AesManaged
        $AES.KeySize = 256
        $AES.BlockSize = 128
        $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC
        
        # Generate key and IV
        $Rfc2898 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 1000)
        $AES.Key = $Rfc2898.GetBytes(32)
        $AES.IV = $Rfc2898.GetBytes(16)
        
        # Create output file stream
        $FileStream = [System.IO.File]::Create($OutputFile)
        
        # Write salt to the beginning of the file
        $FileStream.Write($Salt, 0, $Salt.Length)
        
        # Create crypto stream
        $CryptoStream = New-Object System.Security.Cryptography.CryptoStream(
            $FileStream, 
            $AES.CreateEncryptor(),
            [System.Security.Cryptography.CryptoStreamMode]::Write
        )
        
        # Write encrypted content
        $CryptoStream.Write($FileContent, 0, $FileContent.Length)
        $CryptoStream.FlushFinalBlock()
        
        # Clean up
        $CryptoStream.Close()
        $FileStream.Close()
        $AES.Clear()
        
        Write-Output "File encrypted successfully."
        return $true
    }
    catch {
        Write-Output "Encryption error: $_"
        return $false
    }
}

# Function to decrypt file
function Decrypt-FileContent {
    param (
        [string]$InputFile,
        [string]$OutputFile,
        [string]$Password
    )
    
    try {
        # Read the encrypted file
        $FileContent = [System.IO.File]::ReadAllBytes($InputFile)
        
        # Extract salt (first 16 bytes)
        $Salt = New-Object byte[] 16
        [Array]::Copy($FileContent, 0, $Salt, 0, 16)
        
        # Create AES object
        $AES = New-Object System.Security.Cryptography.AesManaged
        $AES.KeySize = 256
        $AES.BlockSize = 128
        $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC
        
        # Generate key and IV
        $Rfc2898 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, 1000)
        $AES.Key = $Rfc2898.GetBytes(32)
        $AES.IV = $Rfc2898.GetBytes(16)
        
        # Create streams for decryption
        $FileStream = [System.IO.File]::Create($OutputFile)
        $CryptoStream = New-Object System.Security.Cryptography.CryptoStream(
            $FileStream,
            $AES.CreateDecryptor(),
            [System.Security.Cryptography.CryptoStreamMode]::Write
        )
        
        # Write decrypted content (skip the salt)
        $CryptoStream.Write($FileContent, 16, $FileContent.Length - 16)
        $CryptoStream.FlushFinalBlock()
        
        # Clean up
        $CryptoStream.Close()
        $FileStream.Close()
        $AES.Clear()
        
        Write-Output "File decrypted successfully."
        return $true
    }
    catch {
        Write-Output "Decryption error: $_"
        return $false
    }
}

# Function to split a file
function Split-File {
    param (
@ -22,23 +135,27 @@ function Split-File {
        return
    }

    $BaseName = [System.IO.Path]::GetFileName($FilePath)
    $FileDir = [System.IO.Path]::GetDirectoryName($FilePath)
    try {
        $BaseName = [System.IO.Path]::GetFileName($FilePath)
        $FileDir = [System.IO.Path]::GetDirectoryName($FilePath)
        $FileStream = [System.IO.File]::OpenRead($FilePath)
        $Buffer = New-Object byte[] $ChunkSize
        $ChunkNum = 0

    $FileStream = [System.IO.File]::OpenRead($FilePath)
    $Buffer = New-Object byte[] $ChunkSize
    $ChunkNum = 0
        while ($BytesRead = $FileStream.Read($Buffer, 0, $Buffer.Length)) {
            $ChunkFileName = "$FileDir\$BaseName.part$ChunkNum"
            $ChunkStream = [System.IO.File]::Create($ChunkFileName)
            $ChunkStream.Write($Buffer, 0, $BytesRead)
            $ChunkStream.Close()
            $ChunkNum++
        }

    while ($ReadBytes = $FileStream.Read($Buffer, 0, $Buffer.Length)) {
        $ChunkFileName = "$FileDir\$BaseName.part$ChunkNum"
        $ChunkStream = [System.IO.File]::OpenWrite($ChunkFileName)
        $ChunkStream.Write($Buffer, 0, $ReadBytes)
        $ChunkStream.Close()
        $ChunkNum++
        $FileStream.Close()
        Write-Output "File split into $ChunkNum chunks."
    }
    catch {
        Write-Output "Error splitting file: $_"
    }

    $FileStream.Close()
    Write-Output "File split into $ChunkNum chunks."
}

# Function to join files
@ -48,34 +165,39 @@ function Join-Files {
        [string]$OutputFile
    )

    $FileDir = [System.IO.Path]::GetDirectoryName($OutputFile)
    $PartFiles = Get-ChildItem -Path $FileDir -Filter "$BaseName.part*" | Sort-Object Name
    try {
        $FileDir = [System.IO.Path]::GetDirectoryName($OutputFile)
        $PartFiles = Get-ChildItem -Path $FileDir -Filter "$BaseName.part*" | Sort-Object Name

    if ($PartFiles.Count -eq 0) {
        Write-Output "No part files found!"
        return
    }
        if ($PartFiles.Count -eq 0) {
            Write-Output "No part files found!"
            return
        }

    $OutputStream = [System.IO.File]::OpenWrite($OutputFile)
        $OutputStream = [System.IO.File]::Create($OutputFile)

    foreach ($PartFile in $PartFiles) {
        $PartStream = [System.IO.File]::OpenRead($PartFile.FullName)
        $Buffer = New-Object byte[] $PartStream.Length
        $ReadBytes = $PartStream.Read($Buffer, 0, $Buffer.Length)
        $OutputStream.Write($Buffer, 0, $ReadBytes)
        $PartStream.Close()
    }
        foreach ($PartFile in $PartFiles) {
            $PartContent = [System.IO.File]::ReadAllBytes($PartFile.FullName)
            $OutputStream.Write($PartContent, 0, $PartContent.Length)
        }

    $OutputStream.Close()
    Write-Output "Files joined into $OutputFile."
        $OutputStream.Close()
        Write-Output "Files joined successfully."
    }
    catch {
        Write-Output "Error joining files: $_"
    }
}

# Main menu loop
while ($true) {
    Write-Output "`nChoose an option:"
    Write-Output "1. Split a file"
    Write-Output "2. Join files"
    Write-Output "3. Exit"
    $Choice = Read-Host "Enter your choice"
    Write-Output "3. Encrypt file"
    Write-Output "4. Decrypt file"
    Write-Output "5. Exit"
    $Choice = Read-Host "Enter your choice: "

    switch ($Choice) {
        "1" {
@ -122,7 +244,6 @@ while ($true) {
                if ($SaveFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                    $OutputFile = $SaveFileDialog.FileName

                    # Ask for file type
                    $FileType = Read-Host "Enter the file extension/type (ex: txt/jpg/png/pdf, etc.) without the dot"
                    if ($FileType) {
                        $OutputFile = "$OutputFile.$FileType"
@ -137,6 +258,71 @@ while ($true) {
            }
        }
        "3" {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.Filter = "All Files (*.*)|*.*"
            $OpenFileDialog.Title = "Select a file to encrypt"
            $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            
            if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                $FilePath = $OpenFileDialog.FileName
                
                $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
                $SaveFileDialog.Filter = "Encrypted Files (*.encrypted)|*.encrypted|All Files (*.*)|*.*"
                $SaveFileDialog.Title = "Save encrypted file as"
                $SaveFileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($FilePath)
                $SaveFileDialog.FileName = [System.IO.Path]::GetFileName($FilePath) + ".encrypted"

                if ($SaveFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                    $OutputFile = $SaveFileDialog.FileName
                    
                    $Password = Read-Host "Enter encryption password" -AsSecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    
                    Encrypt-FileContent -InputFile $FilePath -OutputFile $OutputFile -Password $Password
                } else {
                    Write-Output "No output location specified."
                }
            } else {
                Write-Output "No file selected."
            }
        }
        "4" {
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.Filter = "Encrypted Files (*.encrypted)|*.encrypted|All Files (*.*)|*.*"
            $OpenFileDialog.Title = "Select encrypted file"
            $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            
            if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                $FilePath = $OpenFileDialog.FileName
                
                $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
                $SaveFileDialog.Filter = "All Files (*.*)|*.*"
                $SaveFileDialog.Title = "Save decrypted file as"
                $SaveFileDialog.InitialDirectory = [System.IO.Path]::GetDirectoryName($FilePath)
                $SaveFileDialog.FileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath).Replace(".encrypted", "")

                if ($SaveFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                    $OutputFile = $SaveFileDialog.FileName
                    
                    $FileType = Read-Host "Enter the file extension/type (ex: txt/jpg/png/pdf, etc.) without the dot"
                    if ($FileType) {
                        $OutputFile = "$OutputFile.$FileType"
                    }
                    
                    $Password = Read-Host "Enter decryption password" -AsSecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    
                    Decrypt-FileContent -InputFile $FilePath -OutputFile $OutputFile -Password $Password
                } else {
                    Write-Output "No output location specified."
                }
            } else {
                Write-Output "No file selected."
            }
        }
        "5" {
            Write-Output "Program Terminated."
            $form.Close()
            exit
