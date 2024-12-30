
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

    function Rename-WithPrefixSuffix {
        param (
            [array]$selectedFiles
        )
    
        do {
            # Ask the user for prefix and suffix
            $prefix = Read-Host "Enter the prefix to add"
            $suffix = Read-Host "Enter the suffix to add"
    
            # Check if both prefix and suffix are empty
            if (-not $prefix -and -not $suffix) {
                Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
            }
        } while (-not $prefix -and -not $suffix)
    
        # Initialize batchOperation to track changes for undo/redo
        $batchOperation = @()
    
        # Process each selected file
        foreach ($filePath in $selectedFiles) {
            # Get file information
            $file = Get-Item -Path $filePath
            $folderPath = $file.DirectoryName
            $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $fileExtension = $file.Extension
    
            # Construct the new name
            $newFileName = "$prefix$fileNameWithoutExtension$suffix$fileExtension"
            $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
    
            # Ensure no conflicts by checking if the new file path already exists
            $counter = 1
            while (Test-Path -Path $newFilePath) {
                $newFileName = "$prefix$fileNameWithoutExtension$suffix ($counter)$fileExtension"
                $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
                $counter++
            }
    
            # Rename the file
            Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
    
            # Store the original and new paths for batch undo/redo
            $batchOperation += @{
                OriginalPath = $filePath
                NewPath = $newFilePath
            }
    
            Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
        }
    
        return $batchOperation
    }
    function Rename-WithPatternReplacement {
        param (
            [array]$selectedFiles
        )
    
        do {
            # Ask the user for the pattern to find and the replacement word
            $patternToFind = Read-Host "Enter the word pattern to find in file names"
            $replacementWord = Read-Host "Enter the word to replace the pattern with"
    
            # Check if either input is empty
            if (-not $patternToFind -or -not $replacementWord) {
                Write-Host "Error: Both the word pattern to find and the replacement word must be provided." -ForegroundColor Red
                continue
            }
    
            # Initialize batchOperation to track changes for undo/redo
            $batchOperation = @()
            $patternFound = $false
    
            # Process each selected file
            foreach ($filePath in $selectedFiles) {
                # Get file information
                $file = Get-Item -Path $filePath
                $folderPath = $file.DirectoryName
                $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                $fileExtension = $file.Extension
    
                # Replace the pattern in the file name if it exists
                if ($fileNameWithoutExtension -match [regex]::Escape($patternToFind)) {
                    $patternFound = $true
                    $newFileNameWithoutExtension = $fileNameWithoutExtension -replace [regex]::Escape($patternToFind), $replacementWord
                    $newFileName = "$newFileNameWithoutExtension$fileExtension"
                    $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
    
                    # Ensure no conflicts
                    $counter = 1
                    while (Test-Path -Path $newFilePath) {
                        $newFileNameWithoutExtension = "$newFileNameWithoutExtension ($counter)"
                        $newFileName = "$newFileNameWithoutExtension$fileExtension"
                        $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
                        $counter++
                    }
    
                    # Rename the file
                    Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
    
                    # Store new and old names
                    $batchOperation += @{
                        OriginalPath = $filePath
                        NewPath = $newFilePath
                    }
    
                    Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
                }
            }
    
            if (-not $patternFound) {
                Write-Host "Error: The word pattern '$patternToFind' could not be found in any of the selected file names." -ForegroundColor Red
            }
    
        } while (-not $patternFound)
    
        return $batchOperation
    }
    function Rename-WithBaseName {
    param (
        [array]$selectedFiles,
        [string]$baseName
    )
            
        # Initialize batchOperation to track changes for undo/redo
        $batchOperation = @()
        
        # Process each selected file and rename them sequentially
        $counter = 0
        foreach ($filePath in $selectedFiles) {
            # Get file information
            $file = Get-Item -Path $filePath
            $folderPath = $file.DirectoryName
            $fileExtension = $file.Extension
        
            # Construct the new name
            if ($counter -eq 0) {
                $newFileName = "$baseName$fileExtension"
            } else {
                $newFileName = "$baseName ($counter)$fileExtension"
            }
                
            $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
        
            # Ensure no conflicts
            while (Test-Path -Path $newFilePath) {
                $counter++
                $newFileName = "$baseName ($counter)$fileExtension"
                $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
            }
        
            # Rename the file
            Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
        
            # Store the original and new paths for batch undo/redo
            $batchOperation += @{
                OriginalPath = $filePath
                NewPath = $newFilePath
            }
        
            Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
            $counter++
        }
        
        return $batchOperation
    }
    
    function Undo-Rename {
        param (
            [array]$undoStack,
            [array]$redoStack
        )
    
        if ($undoStack.Count -eq 0) {
            Write-Host "Nothing to undo." -ForegroundColor Yellow
        } else {
            # Get the last batch of renames
            $lastBatch = $undoStack[-1]
            $undoStack = $undoStack[0..($undoStack.Count - 2)]  # Remove the last batch from undo stack
    
            # Undo each rename in reverse order
            foreach ($action in $lastBatch) {
                Rename-Item -Path $action.NewPath -NewName (Split-Path -Leaf $action.OriginalPath) -ErrorAction Stop
                Write-Host "Undo: Renamed '$($action.NewPath)' back to '$($action.OriginalPath)'" -ForegroundColor Cyan
            }
    
            # Push this batch to the redo stack
            $redoStack += ,$lastBatch
    
            Write-Host "Undo completed for the last batch of renames." -ForegroundColor Cyan
        }
    
        return $undoStack, $redoStack
    }
    
    function Redo-Rename {
        param (
            [array]$redoStack,
            [array]$undoStack
        )
    
        if ($redoStack.Count -eq 0) {
            Write-Host "Nothing to redo." -ForegroundColor Yellow
        } else {
            # Get the last batch of undone renames
            $lastBatch = $redoStack[-1]
            $redoStack = $redoStack[0..($redoStack.Count - 2)]  # Remove the last batch from redo stack
    
            # Redo each rename
            foreach ($action in $lastBatch) {
                Rename-Item -Path $action.OriginalPath -NewName (Split-Path -Leaf $action.NewPath) -ErrorAction Stop
                Write-Host "Redo: Renamed '$($action.OriginalPath)' to '$($action.NewPath)'" -ForegroundColor Cyan
            }
    
            # Push this batch back to the undo stack
            $undoStack += ,$lastBatch
    
            Write-Host "Redo completed for the last batch of renames." -ForegroundColor Cyan
        }
    
        return $undoStack, $redoStack
    }