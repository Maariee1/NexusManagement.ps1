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

    # Ask the user for the base name for all files
    $baseName = Read-Host "Enter the base name for all selected files"

    # Prepare to track the batch of operations for undo/redo
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

        #inii-store ang new and old names
        $batchOperation += @{
            OriginalPath = $filePath
            NewPath = $newFilePath
        }

        Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
        $counter++
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
