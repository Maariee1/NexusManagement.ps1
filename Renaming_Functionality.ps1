Add-Type -AssemblyName System.Windows.Forms

#dito ini-store yung mga na-rename na sa undo
$undoStack = @()
$redoStack = @()

# Create an OpenFileDialog object
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Multiselect = $true # para sa multiple selection of files
$OpenFileDialog.Title = "Select Files to Rename"
$OpenFileDialog.Filter = "All Files (*.*)|*.*" # to record all types of file

# Shows the file dialog and check if they clicked OK
if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # Get the selected files
    $selectedFiles = $OpenFileDialog.FileNames

    # Ask the user for renaming option
    $renameOption = Read-Host "Enter '1' to use a base name or '2' to add prefix and suffix or '3' to replace a word pattern"

    # Prepare to track the batch of operations for undo/redo
    $batchOperation = @()

    if ($renameOption -eq '1') {
        # Ask the user for the baase name for all files
        $baseName = Read-Host "Enter the base name for all selected files"

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

            #inii-store ang new and old names
            $batchOperation += @{
                OriginalPath = $filePath
                NewPath = $newFilePath
            }

            Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
            $counter++
        }
    } elseif ($renameOption -eq '2') {
        do {
            # Ask the user for prefix and suffix
            $prefix = Read-Host "Enter the prefix to add"
            $suffix = Read-Host "Enter the suffix to add"

            # Check if both prefix and suffix are empty
            if (-not $prefix -and -not $suffix) {
                Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
            }
        } while (-not $prefix -and -not $suffix)

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

            # Ensure no conflicts
            $counter = 1
            while (Test-Path -Path $newFilePath) {
                $newFileName = "$prefix$fileNameWithoutExtension$suffix ($counter)$fileExtension"
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
    } elseif ($renameOption -eq '3') {
        $patternFound = $false
        do {
            # Ask the user for the pattern to find and the replacement word
            $patternToFind = Read-Host "Enter the word pattern to find in file names"
            $replacementWord = Read-Host "Enter the word to replace the pattern with"

            # Check if either input is empty
            if (-not $patternToFind -or -not $replacementWord) {
                Write-Host "Error: Both the word pattern to find and the replacement word must be provided." -ForegroundColor Red
                continue
            }

        # Process each selected file
        foreach ($filePath in $selectedFiles) {
            # Get file information
            $file = Get-Item -Path $filePath
            $folderPath = $file.DirectoryName
            $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            $fileExtension = $file.Extension

            # Replace the pattern in the file name if it exists
            if ($fileNameWithoutExtension -match [regex]::Escape($patternToFind)){
                $patternFound = $True
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
    } else {
        Write-Host "Invalid option selected. Exiting." -ForegroundColor Red
        exit
    }

    # Push the batch operation to the undo stack
    $undoStack += ,$batchOperation

    # Clear the redo stack on new rename operation
    $redoStack = @()

    Write-Host "All selected files have been renamed successfully!" -ForegroundColor Cyan

    #katulad ng switch case lang to for redo and undo
    #tatanggalin na lang yung read host kapag isasama na sa buttons
    while ($true) {
        $action = Read-Host "Enter 'undo' to undo the renaming or 'redo' to redo the renaming"
        switch ($action) {
            'undo' {
                if ($undoStack.Count -eq 0) {
                    Write-Host "Nothing to undo." -ForegroundColor Yellow
                } else {
                    # Get the last batch of renames
                    $lastBatch = $undoStack[-1] #give the last element -1
                    $undoStack = $undoStack[0..($undoStack.Count - 2)] # Remove the last batch from undo stack

                    # Undo each rename in reverse order
                    foreach ($action in $lastBatch) {
                        Rename-Item -Path $action.NewPath -NewName (Split-Path -Leaf $action.OriginalPath) -ErrorAction Stop
                        Write-Host "Undo: Renamed '$($action.NewPath)' back to '$($action.OriginalPath)'" -ForegroundColor Cyan
                    }

                    # Push this batch to the redo stack
                    $redoStack += ,$lastBatch

                    Write-Host "Undo completed for the last batch of renames." -ForegroundColor Cyan
                }
            }
            'redo' {
                if ($redoStack.Count -eq 0) {
                    Write-Host "Nothing to redo." -ForegroundColor Yellow
                } else {
                    # Get the last batch of undone renames
                    $lastBatch = $redoStack[-1]
                    $redoStack = $redoStack[0..($redoStack.Count - 2)] # Remove the last batch from redo stack

                    # Redo each rename
                    foreach ($action in $lastBatch) {
                        Rename-Item -Path $action.OriginalPath -NewName (Split-Path -Leaf $action.NewPath) -ErrorAction Stop
                        Write-Host "Redo: Renamed '$($action.OriginalPath)' to '$($action.NewPath)'" -ForegroundColor Cyan
                    }

                    # Push this batch back to the undo stack
                    $undoStack += ,$lastBatch

                    Write-Host "Redo completed for the last batch of renames." -ForegroundColor Cyan
                }
            }
            default {
                Write-Host "Invalid input. Try 'undo' or 'redo'." -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "No files selected. Exiting." -ForegroundColor Yellow
}



#WITH ENCRYPTION AND DECRYPTION BUT NOT YET DONEEEEEEEEEEEEEEEEEEEEEE!!!!
# Add-Type -AssemblyName System.Windows.Forms

# # Stack for undo and redo
# $undoStack = @()
# $redoStack = @()

# function Rename-WithBaseName {
#     param([string[]]$selectedFiles)

#     $baseName = Read-Host "Enter the base name for all selected files"
#     $batchOperation = @()

#     $counter = 0
#     foreach ($filePath in $selectedFiles) {
#         $file = Get-Item -Path $filePath
#         $folderPath = $file.DirectoryName
#         $fileExtension = $file.Extension

#         if ($counter -eq 0) {
#             $newFileName = "$baseName$fileExtension"
#         } else {
#             $newFileName = "$baseName ($counter)$fileExtension"
#         }

#         $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#         while (Test-Path -Path $newFilePath) {
#             $counter++
#             $newFileName = "$baseName ($counter)$fileExtension"
#             $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#         }

#         Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
#         $batchOperation += @{
#             OriginalPath = $filePath
#             NewPath = $newFilePath
#         }

#         Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#         $counter++
#     }

#     return $batchOperation
# }

# # Function: Rename with prefix and suffix
# function Rename-WithPatternReplacement {
#     param([string[]]$selectedFiles)

#     $batchOperation = @()
#     $patternFound = $false

#     do {
#         # Ask the user for the word pattern to find and the replacement word
#         $patternToFind = Read-Host "Enter the word pattern to find in file names"
#         $replacementWord = Read-Host "Enter the word to replace the pattern with"

#         # Ensure both the pattern to find and replacement word are provided
#         if (-not $patternToFind -or -not $replacementWord) {
#             Write-Host "Error: Both the word pattern to find and the replacement word must be provided." -ForegroundColor Red
#             continue
#         }

#         # Process each selected file to replace the pattern in the file names
#         foreach ($filePath in $selectedFiles) {
#             # Get file information
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#             $fileExtension = $file.Extension

#             # Replace the pattern in the file name if it exists
#             if ($fileNameWithoutExtension -match [regex]::Escape($patternToFind)) {
#                 $patternFound = $True
#                 $newFileNameWithoutExtension = $fileNameWithoutExtension -replace [regex]::Escape($patternToFind), $replacementWord
#                 $newFileName = "$newFileNameWithoutExtension$fileExtension"
#                 $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#                 # Ensure no conflicts (same name exists)
#                 $counter = 1
#                 while (Test-Path -Path $newFilePath) {
#                     $newFileNameWithoutExtension = "$newFileNameWithoutExtension ($counter)"
#                     $newFileName = "$newFileNameWithoutExtension$fileExtension"
#                     $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#                     $counter++
#                 }

#                 # Rename the file
#                 Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop

#                 # Store original and new paths for undo/redo
#                 $batchOperation += @{
#                     OriginalPath = $filePath
#                     NewPath = $newFilePath
#                 }

#                 Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#             }
#         }

#         # If no pattern was found, inform the user and loop again
#         if (-not $patternFound) {
#             Write-Host "Error: The word pattern '$patternToFind' could not be found in any of the selected file names." -ForegroundColor Red
#         }
#     } while (-not $patternFound)

#     # Return batch operation for undo/redo tracking
#     return $batchOperation
# }


# # Function: Rename by replacing a word pattern
# function Rename-WithPrefixSuffix {
#     param([string[]]$selectedFiles)

#     # Initialize batch operation storage
#     $batchOperation = @()

#     do {
#         # Ask the user for prefix and suffix
#         $prefix = Read-Host "Enter the prefix to add"
#         $suffix = Read-Host "Enter the suffix to add"

#         # Check if both prefix and suffix are empty
#         if (-not $prefix -and -not $suffix) {
#             Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
#         }
#     } while (-not $prefix -and -not $suffix)

#     # Process each selected file
#     foreach ($filePath in $selectedFiles) {
#         # Get file information
#         $file = Get-Item -Path $filePath
#         $folderPath = $file.DirectoryName
#         $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#         $fileExtension = $file.Extension

#         # Construct the new name
#         $newFileName = "$prefix$fileNameWithoutExtension$suffix$fileExtension"
#         $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#         # Ensure no conflicts
#         $counter = 1
#         while (Test-Path -Path $newFilePath) {
#             $newFileName = "$prefix$fileNameWithoutExtension$suffix ($counter)$fileExtension"
#             $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#             $counter++
#         }

#         # Rename the file
#         Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop

#         # Store new and old names for batch operation tracking
#         $batchOperation += @{
#             OriginalPath = $filePath
#             NewPath = $newFilePath
#         }

#         Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#     }

#     # Return batch operation for undo/redo tracking
#     return $batchOperation
# }


# # Function: Undo the last batch operation
# function Undo-Rename {
#     if ($undoStack.Count -eq 0) {
#         Write-Host "Nothing to undo." -ForegroundColor Yellow
#         return
#     }

#     # Get the last batch of renames
#     $lastBatch = $undoStack[-1]
#     $undoStack = $undoStack[0..($undoStack.Count - 2)] # Remove the last batch from undo stack

#     # Undo each rename in reverse order
#     foreach ($action in $lastBatch) {
#         Rename-Item -Path $action.NewPath -NewName (Split-Path -Leaf $action.OriginalPath) -ErrorAction Stop
#         Write-Host "Undo: Renamed '$($action.NewPath)' back to '$($action.OriginalPath)'" -ForegroundColor Cyan
#     }

#     # Push this batch to the redo stack
#     $redoStack += ,$lastBatch
#     Write-Host "Undo completed for the last batch of renames." -ForegroundColor Cyan
# }

# # Function: Redo the last undone batch operation
# function Redo-Rename {
#     if ($redoStack.Count -eq 0) {
#         Write-Host "Nothing to redo." -ForegroundColor Yellow
#         return
#     }

#     # Get the last batch of undone renames
#     $lastBatch = $redoStack[-1]
#     $redoStack = $redoStack[0..($redoStack.Count - 2)] # Remove the last batch from redo stack

#     # Redo each rename
#     foreach ($action in $lastBatch) {
#         Rename-Item -Path $action.OriginalPath -NewName (Split-Path -Leaf $action.NewPath) -ErrorAction Stop
#         Write-Host "Redo: Renamed '$($action.OriginalPath)' to '$($action.NewPath)'" -ForegroundColor Cyan
#     }

#     # Push this batch back to the undo stack
#     $undoStack += ,$lastBatch
#     Write-Host "Redo completed for the last batch of renames." -ForegroundColor Cyan
# }

# function Select-Files {
#     # Create an OpenFileDialog object
#     $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
#     $OpenFileDialog.Multiselect = $true  # Enable multiple file selection
#     $OpenFileDialog.Title = "Select Files to Rename"  # Set the dialog title
#     $OpenFileDialog.Filter = "All Files (*.*)|*.*"  # Set file filter (all files)

#     # Show the dialog and check if the user clicked OK
#     if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
#         # Return the selected file paths
#         return $OpenFileDialog.FileNames
#     } else {
#         # Return an empty array if the user cancels
#         return @()
#     }
# }




# Add-Type -AssemblyName System.Windows.Forms

# # Declare stacks for undo and redo operations
# $undoStack = @()
# $redoStack = @()

# # Create an OpenFileDialog object
# $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
# $OpenFileDialog.Multiselect = $true # Allows multiple file selection
# $OpenFileDialog.Title = "Select Files to Rename, Encrypt, or Decrypt"
# $OpenFileDialog.Filter = "All Files (*.*)|*.*" # For all file types

# # Show the file dialog and check if files were selected
# if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
#     # Get the selected files
#     $selectedFiles = $OpenFileDialog.FileNames

#     # Ask the user for renaming, encryption, or decryption option
#     $actionOption = Read-Host "Enter '1' to rename files, '2' to add prefix/suffix, '3' to replace word pattern, '4' to encrypt files, or '5' to decrypt files"

#     # Function to encrypt files
#     function Encrypt-File {
#         param (
#             [string]$inputFilePath,
#             [string]$outputFilePath,
#             [string]$key,
#             [string]$iv
#         )

#         # Ensure key and IV are 16 bytes long (128 bits)
#         $key = $key.Substring(0, [Math]::Min($key.Length, 16)).PadRight(16, '0')
#         $iv = $iv.Substring(0, [Math]::Min($iv.Length, 16)).PadRight(16, '0')

#         $aes = [System.Security.Cryptography.Aes]::Create()
#         $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($key)
#         $aes.IV = [System.Text.Encoding]::UTF8.GetBytes($iv)

#         $encryptor = $aes.CreateEncryptor()

#         $inputFileStream = [System.IO.File]::OpenRead($inputFilePath)
#         $outputFileStream = [System.IO.File]::OpenWrite($outputFilePath)

#         $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outputFileStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
#         $inputFileStream.CopyTo($cryptoStream)

#         $cryptoStream.FlushFinalBlock()
#         $inputFileStream.Close()
#         $cryptoStream.Close()
#         $outputFileStream.Close()
#     }

#     # Function to decrypt files
#     function Decrypt-File {
#         param (
#             [string]$inputFilePath,
#             [string]$outputFilePath,
#             [string]$key,
#             [string]$iv
#         )

#         # Ensure key and IV are 16 bytes long (128 bits)
#         $key = $key.Substring(0, [Math]::Min($key.Length, 16)).PadRight(16, '0')
#         $iv = $iv.Substring(0, [Math]::Min($iv.Length, 16)).PadRight(16, '0')

#         $aes = [System.Security.Cryptography.Aes]::Create()
#         $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($key)
#         $aes.IV = [System.Text.Encoding]::UTF8.GetBytes($iv)

#         $decryptor = $aes.CreateDecryptor()

#         $inputFileStream = [System.IO.File]::OpenRead($inputFilePath)
#         $outputFileStream = [System.IO.File]::OpenWrite($outputFilePath)

#         $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outputFileStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
#         $inputFileStream.CopyTo($cryptoStream)

#         $cryptoStream.FlushFinalBlock()
#         $inputFileStream.Close()
#         $cryptoStream.Close()
#         $outputFileStream.Close()
#     }

#     # Option 1: Renaming files
#     if ($actionOption -eq '1') {
#         # Ask the user for the base name for all files
#         $baseName = Read-Host "Enter the base name for all selected files"

#         $counter = 0
#         foreach ($filePath in $selectedFiles) {
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileExtension = $file.Extension

#             if ($counter -eq 0) {
#                 $newFileName = "$baseName$fileExtension"
#             } else {
#                 $newFileName = "$baseName ($counter)$fileExtension"
#             }

#             $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#             while (Test-Path -Path $newFilePath) {
#                 $counter++
#                 $newFileName = "$baseName ($counter)$fileExtension"
#                 $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#             }

#             Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
#             Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#             $counter++
#         }
#     } 
#     # Option 2: Adding prefix and suffix
#     elseif ($actionOption -eq '2') {
#         do {
#             $prefix = Read-Host "Enter the prefix to add"
#             $suffix = Read-Host "Enter the suffix to add"
#             if (-not $prefix -and -not $suffix) {
#                 Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
#             }
#         } while (-not $prefix -and -not $suffix)

#         foreach ($filePath in $selectedFiles) {
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#             $fileExtension = $file.Extension

#             $newFileName = "$prefix$fileNameWithoutExtension$suffix$fileExtension"
#             $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#             $counter = 1
#             while (Test-Path -Path $newFilePath) {
#                 $newFileName = "$prefix$fileNameWithoutExtension$suffix ($counter)$fileExtension"
#                 $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#                 $counter++
#             }

#             Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
#             Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#         }
#     }
#     # Option 3: Replacing word pattern
#     elseif ($actionOption -eq '3') {
#         $patternFound = $false
#         do {
#             $patternToFind = Read-Host "Enter the word pattern to find in file names"
#             $replacementWord = Read-Host "Enter the word to replace the pattern with"
#             if (-not $patternToFind -or -not $replacementWord) {
#                 Write-Host "Error: Both the word pattern to find and the replacement word must be provided." -ForegroundColor Red
#                 continue
#             }

#             foreach ($filePath in $selectedFiles) {
#                 $file = Get-Item -Path $filePath
#                 $folderPath = $file.DirectoryName
#                 $fileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#                 $fileExtension = $file.Extension

#                 if ($fileNameWithoutExtension -match [regex]::Escape($patternToFind)) {
#                     $patternFound = $True
#                     $newFileNameWithoutExtension = $fileNameWithoutExtension -replace [regex]::Escape($patternToFind), $replacementWord
#                     $newFileName = "$newFileNameWithoutExtension$fileExtension"
#                     $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

#                     $counter = 1
#                     while (Test-Path -Path $newFilePath) {
#                         $newFileNameWithoutExtension = "$newFileNameWithoutExtension ($counter)"
#                         $newFileName = "$newFileNameWithoutExtension$fileExtension"
#                         $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
#                         $counter++
#                     }

#                     Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop
#                     Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
#                 }
#             }

#             if (-not $patternFound) {
#                 Write-Host "Error: The word pattern '$patternToFind' could not be found in any of the selected file names." -ForegroundColor Red
#             }
#         } while (-not $patternFound)
#     }
#     # Option 4: Encrypting files
#     elseif ($actionOption -eq '4') {
#         # Ask the user for encryption key and IV
#         $key = Read-Host "Enter the encryption key (16 characters)"
#         $iv = Read-Host "Enter the initialization vector (16 characters)"

#         if ($key.Length -ne 16 -or $iv.Length -ne 16) {
#             Write-Host "Error: Both key and IV must be exactly 16 characters long." -ForegroundColor Red
#             exit
#         }

#         foreach ($filePath in $selectedFiles) {
#             $file = Get-Item -Path $filePath
#             $folderPath = $file.DirectoryName
#             $fileName = $file.Name
#             $encryptedFilePath = Join-Path -Path $folderPath -ChildPath "$fileName.enc"

#             # Encrypt the file
#             Encrypt-File -inputFilePath $filePath -outputFilePath $encryptedFilePath -key $key -iv $iv

#             Write-Host "Encrypted '$fileName' to '$encryptedFilePath'" -ForegroundColor Green
#         }

#         Write-Host "Encryption completed for all selected files!" -ForegroundColor Cyan
#     }
#     # Option 5: Decrypting files
#     elseif ($actionOption -eq '5') {
#         # Ask the user for decryption key and IV
#         $key = Read-Host "Enter the decryption key (16 characters)"
#         $iv = Read-Host "Enter the initialization vector (16 characters)"

#         if ($key.Length -ne 16 -or $iv.Length -ne 16) {
#             Write-Host "Error: Both key and IV must be exactly 16 characters long." -ForegroundColor Red
#             exit
#         }

#         foreach ($filePath in $selectedFiles) {
#             # Ensure the file has the .enc extension for decryption
#             if ($filePath -match "\.enc$") {
#                 $file = Get-Item -Path $filePath
#                 $folderPath = $file.DirectoryName
#                 $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
#                 $decryptedFilePath = Join-Path -Path $folderPath -ChildPath "$fileName.decrypted"

#                 # Decrypt the file
#                 Decrypt-File -inputFilePath $filePath -outputFilePath $decryptedFilePath -key $key -iv $iv

#                 Write-Host "Decrypted '$fileName.enc' to '$decryptedFilePath'" -ForegroundColor Green
#             } else {
#                 Write-Host "Skipping '$($file.Name)': Not an encrypted file (.enc)" -ForegroundColor Yellow
#             }
#         }

#         Write-Host "Decryption completed for all selected encrypted files!" -ForegroundColor Cyan
#     } else {
#         Write-Host "Invalid option selected. Exiting." -ForegroundColor Red
#         exit
#     }
# } else {
#     Write-Host "No files selected. Exiting." -ForegroundColor Yellow
# }





#NO NEEDDDDDDDDDDDDD
# # Main Script Logic
# $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
# $OpenFileDialog.Multiselect = $true
# $OpenFileDialog.Title = "Select Files to Rename"
# $OpenFileDialog.Filter = "All Files (*.*)|*.*"

# if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
#     $selectedFiles = $OpenFileDialog.FileNames

#     while ($true) {
#         $renameOption = Read-Host "Enter '1' for base name, '2' for prefix/suffix, '3' for pattern replace, '4' to undo, '5' to redo, or 'exit' to quit"

#         switch ($renameOption) {
#             '1' {
#                 $batchOperation = Rename-WithBaseName -selectedFiles $selectedFiles
#                 $undoStack += ,$batchOperation
#                 $redoStack = @()
#             }
#             '2' {
#                 $batchOperation = Rename-WithPrefixSuffix -selectedFiles $selectedFiles
#                 $undoStack += ,$batchOperation
#                 $redoStack = @()
#             }
#             '3' {
#                 $batchOperation = Rename-WithPatternReplacement -selectedFiles $selectedFiles
#                 $undoStack += ,$batchOperation
#                 $redoStack = @()
#             }
#             '4' {
#                 Undo-Rename
#             }
#             '5' {
#                 Redo-Rename
#             }
#             'exit' {
#                 Write-Host "Exiting the program. Goodbye!" -ForegroundColor Cyan
#                 break
#             }
#             default {
#                 Write-Host "Invalid option. Try again." -ForegroundColor Red
#             }
#         }
#     }
# } else {
#     Write-Host "No files selected. Exiting." -ForegroundColor Yellow
# }
