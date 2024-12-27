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
