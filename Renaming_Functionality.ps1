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

    # Show the form without making it visible (needed for dialog)
    $form.Show()

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
        [array]$selectedFiles
    )
    
        $baseName = Read-Host "Enter the base name for all selected files"
            
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
         
# Main Script Logic
$undoStack = @()
$redoStack = @()

while($true){
    Write-Output "Choose an option:"
    Write-Output "1. BASE NAME"
    Write-Output "2. PREFIX AND SUFFIX"
    Write-Output "3. REPLACEMENT"
    Write-Output "4. UNDO"
    Write-Output "5. REDO"
    Write-Output "6. ENCRYPTION "
    Write-Output "7. DECRYPTION"
    $Choice = Read-Host "Enter your choice"

        switch ($Choice) {
            '1' {               
                $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $OpenFileDialog.Filter = "All Files (*.*)|*.*"
                $OpenFileDialog.Title = "Select files to rename"
                $OpenFileDialog.Multiselect = $true  # Allow multiple file selection
                    
                # Show the file dialog and get the selected files
                if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedFiles = $OpenFileDialog.FileNames
                    $batchOperation = Rename-WithBaseName -selectedFiles $selectedFiles
                    $undoStack += ,$batchOperation
                    $redoStack = @()
                }
            }
            '2' {
                $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $OpenFileDialog.Filter = "All Files (*.*)|*.*"
                $OpenFileDialog.Title = "Select files to rename"
                $OpenFileDialog.Multiselect = $true  # Allow multiple file selection

                if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedFiles = $OpenFileDialog.FileNames
                    $batchOperation = Rename-WithPrefixSuffix -selectedFiles $selectedFiles
                    $undoStack += ,$batchOperation
                    $redoStack = @()
                }
            }
            '3' {
                $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $OpenFileDialog.Filter = "All Files (*.*)|*.*"
                $OpenFileDialog.Title = "Select files to rename"
                $OpenFileDialog.Multiselect = $true  # Allow multiple file selection
                
                if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedFiles = $OpenFileDialog.FileNames
                    $batchOperation = Rename-WithPatternReplacement -selectedFiles $selectedFiles
                    $undoStack += ,$batchOperation
                    $redoStack = @()
                }
            }
            '4' {
                $undoStack, $redoStack = Undo-Rename -undoStack $undoStack -redoStack $redoStack
            }
            '5' {
                $undoStack, $redoStack = Redo-Rename -redoStack $redoStack -undoStack $undoStack
            }
            '6' {
                # Open file dialog to select multiple files for encryption
                $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $OpenFileDialog.Filter = "All Files (*.*)|*.*"
                $OpenFileDialog.Title = "Select files to encrypt"
                $OpenFileDialog.Multiselect = $true  # Allow multiple file selection

                if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                    $InputFiles = $OpenFileDialog.FileNames  # Get all selected files
                    $Password = Read-Host "Enter encryption password"
                    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
                    $SaveFileDialog.Title = "Save encrypted file"
                    
                    foreach ($InputFile in $InputFiles) {
                        # Prepare the output file name (add .ext or keep the original name)
                        if ($FileType) {
                            $OutputFile = "$InputFile.$FileType"
                        } else {
                            $OutputFile = "$InputFile.encrypted"  # Default output name
                        }
                        
                        # Encrypt each selected file
                        Encrypt-File -InputFile $InputFile -OutputFile $OutputFile -Password $Password
                        Write-Host "Encrypted '$InputFile' to '$OutputFile'" -ForegroundColor Green
                    }
                }
            }
            '7' {
                # Open file dialog to select multiple files for decryption
                $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                $OpenFileDialog.Filter = "All Files (*.*)|*.*"
                $OpenFileDialog.Title = "Select files to decrypt"
                $OpenFileDialog.Multiselect = $true  # Allow multiple file selection

                if ($OpenFileDialog.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
                    $InputFiles = $OpenFileDialog.FileNames  # Get all selected files
                    $Password = Read-Host "Enter decryption password"
                    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
                    $SaveFileDialog.Title = "Save decrypted file"

                    foreach ($InputFile in $InputFiles) {
                        # Prepare the output file name (add .ext or keep the original name)
                        if ($FileType) {
                            $OutputFile = "$InputFile.$FileType"
                        } else {
                            $OutputFile = "$InputFile.decrypted"  # Default output name
                        }

                        # Decrypt each selected file
                        Decrypt-File -InputFile $InputFile -OutputFile $OutputFile -Password $Password
                        Write-Host "Decrypted '$InputFile' to '$OutputFile'" -ForegroundColor Green
                    }
                }
            }
            'exit' {
                Write-Host "Exiting the program. Goodbye!" -ForegroundColor Cyan
                exit
            }
            default {
                Write-Host "Invalid option. Try again." -ForegroundColor Red
            }
        }
    }






# MAIN CODE HAHAHHAHAHAH
# Add-Type -AssemblyName System.Windows.Forms

# #dito ini-store yung mga na-rename na sa undo
# $undoStack = @()
# $redoStack = @()

# # Create an OpenFileDialog object
# $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
# $OpenFileDialog.Multiselect = $true # para sa multiple selection of files
# $OpenFileDialog.Title = "Select Files to Rename"
# $OpenFileDialog.Filter = "All Files (*.*)|*.*" # to record all types of file

# # Shows the file dialog and check if they clicked OK
# if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
#     # Get the selected files
#     $selectedFiles = $OpenFileDialog.FileNames

#     # Ask the user for renaming option
#     $renameOption = Read-Host "Enter '1' to use a base name or '2' to add prefix and suffix or '3' to replace a word pattern"

#     # Prepare to track the batch of operations for undo/redo
#     $batchOperation = @()

#     if ($renameOption -eq '1') {
#         # Ask the user for the baase name for all files
#         $baseName = Read-Host "Enter the base name for all selected files"

#         # Process each selected file and rename them sequentially
#         $counter = 0
#         foreach ($filePath in $selectedFiles) {
#             # Get file information
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileExtension = $file.Extension

#             # Construct the new name
#             if ($counter -eq 0) {
#                 $newFileName = "$baseName$fileExtension"
#             } else {
#                 $newFileName = "$baseName ($counter)$fileExtension"
#             }
        
#             $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#             # Ensure no conflicts
#             while (Test-Path -Path $newFilePath) {
#                 $counter++
#                 $newFileName = "$baseName ($counter)$fileExtension"
#                 $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#             }

#             # Rename the file
#             Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop

#             #inii-store ang new and old names
#             $batchOperation += @{
#                 OriginalPath = $filePath
#                 NewPath = $newFilePath
#             }

#             Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#             $counter++
#         }
#     } elseif ($renameOption -eq '2') {
#         do {
#             # Ask the user for prefix and suffix
#             $prefix = Read-Host "Enter the prefix to add"
#             $suffix = Read-Host "Enter the suffix to add"

#             # Check if both prefix and suffix are empty
#             if (-not $prefix -and -not $suffix) {
#                 Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
#             }
#         } while (-not $prefix -and -not $suffix)

#         # Process each selected file
#         foreach ($filePath in $selectedFiles) {
#             # Get file information
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#             $fileExtension = $file.Extension

#             # Construct the new name
#             $newFileName = "$prefix$fileNameWithoutExtension$suffix$fileExtension"
#             $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#             # Ensure no conflicts
#             $counter = 1
#             while (Test-Path -Path $newFilePath) {
#                 $newFileName = "$prefix$fileNameWithoutExtension$suffix ($counter)$fileExtension"
#                 $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#                 $counter++
#             }

#             # Rename the file
#             Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop

#             # Store new and old names
#             $batchOperation += @{
#                 OriginalPath = $filePath
#                 NewPath = $newFilePath
#             }

#             Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#         }
#     } elseif ($renameOption -eq '3') {
#         $patternFound = $false
#         do {
#             # Ask the user for the pattern to find and the replacement word
#             $patternToFind = Read-Host "Enter the word pattern to find in file names"
#             $replacementWord = Read-Host "Enter the word to replace the pattern with"

#             # Check if either input is empty
#             if (-not $patternToFind -or -not $replacementWord) {
#                 Write-Host "Error: Both the word pattern to find and the replacement word must be provided." -ForegroundColor Red
#                 continue
#             }

#         # Process each selected file
#         foreach ($filePath in $selectedFiles) {
#             # Get file information
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#             $fileExtension = $file.Extension

#             # Replace the pattern in the file name if it exists
#             if ($fileNameWithoutExtension -match [regex]::Escape($patternToFind)){
#                 $patternFound = $True
#                 $newFileNameWithoutExtension = $fileNameWithoutExtension -replace [regex]::Escape($patternToFind), $replacementWord
#                 $newFileName = "$newFileNameWithoutExtension$fileExtension"
#                 $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#                 # Ensure no conflicts
#                 $counter = 1
#                 while (Test-Path -Path $newFilePath) {
#                     $newFileNameWithoutExtension = "$newFileNameWithoutExtension ($counter)"
#                     $newFileName = "$newFileNameWithoutExtension$fileExtension"
#                     $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#                     $counter++
#                 }

#                 # Rename the file
#                 Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop

#                 # Store new and old names
#                 $batchOperation += @{
#                     OriginalPath = $filePath
#                     NewPath = $newFilePath
#                 }

#                     Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#                 }
#             }

#             if (-not $patternFound) {
#                 Write-Host "Error: The word pattern '$patternToFind' could not be found in any of the selected file names." -ForegroundColor Red
#             }
#         } while (-not $patternFound)
#     } else {
#         Write-Host "Invalid option selected. Exiting." -ForegroundColor Red
#         exit
#     }

#     # Push the batch operation to the undo stack
#     $undoStack += ,$batchOperation

#     # Clear the redo stack on new rename operation
#     $redoStack = @()

#     Write-Host "All selected files have been renamed successfully!" -ForegroundColor Cyan

#     #katulad ng switch case lang to for redo and undo
#     #tatanggalin na lang yung read host kapag isasama na sa buttons
#     while ($true) {
#         $action = Read-Host "Enter 'undo' to undo the renaming or 'redo' to redo the renaming"
#         switch ($action) {
#             'undo' {
#                 if ($undoStack.Count -eq 0) {
#                     Write-Host "Nothing to undo." -ForegroundColor Yellow
#                 } else {
#                     # Get the last batch of renames
#                     $lastBatch = $undoStack[-1] #give the last element -1
#                     $undoStack = $undoStack[0..($undoStack.Count - 2)] # Remove the last batch from undo stack

#                     # Undo each rename in reverse order
#                     foreach ($action in $lastBatch) {
#                         Rename-Item -Path $action.NewPath -NewName (Split-Path -Leaf $action.OriginalPath) -ErrorAction Stop
#                         Write-Host "Undo: Renamed '$($action.NewPath)' back to '$($action.OriginalPath)'" -ForegroundColor Cyan
#                     }

#                     # Push this batch to the redo stack
#                     $redoStack += ,$lastBatch

#                     Write-Host "Undo completed for the last batch of renames." -ForegroundColor Cyan
#                 }
#             }
#             'redo' {
#                 if ($redoStack.Count -eq 0) {
#                     Write-Host "Nothing to redo." -ForegroundColor Yellow
#                 } else {
#                     # Get the last batch of undone renames
#                     $lastBatch = $redoStack[-1]
#                     $redoStack = $redoStack[0..($redoStack.Count - 2)] # Remove the last batch from redo stack

#                     # Redo each rename
#                     foreach ($action in $lastBatch) {
#                         Rename-Item -Path $action.OriginalPath -NewName (Split-Path -Leaf $action.NewPath) -ErrorAction Stop
#                         Write-Host "Redo: Renamed '$($action.OriginalPath)' to '$($action.NewPath)'" -ForegroundColor Cyan
#                     }

#                     # Push this batch back to the undo stack
#                     $undoStack += ,$lastBatch

#                     Write-Host "Redo completed for the last batch of renames." -ForegroundColor Cyan
#                 }
#             }
#             default {
#                 Write-Host "Invalid input. Try 'undo' or 'redo'." -ForegroundColor Red
#             }
#         }
#     }
# } else {
#     Write-Host "No files selected. Exiting." -ForegroundColor Yellow
# }

