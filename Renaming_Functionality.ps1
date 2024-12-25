Add-Type -AssemblyName System.Windows.Forms

# Create an OpenFileDialog object
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Multiselect = $true # para sa multiple selection of files
$OpenFileDialog.Title = "Select Files to Rename"
$OpenFileDialog.Filter = "All Files (*.*)|*.*" # to record all types of file
#can also use - Images (*.jpg;*.png) only if image

#Shows the file dialog and check if they clicked OK
if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    #Get the selected files
    $selectedFiles = $OpenFileDialog.FileNames

    #Ask the user for the base name for all files
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
            #uses the base name
            $newFileName = "$baseName$fileExtension"
        } else {
            #New name tapos using array nag iincrease ang counter
            $newFileName = "$baseName ($counter)$fileExtension"
        }
        
        $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName

        # Ensure no conflicts
        # chinecheck nito yung path na selected at magsstop lang ang loop if nakahanap siya unique name
        while (Test-Path -Path $newFilePath) {
            $counter++
            $newFileName = "$baseName ($counter)$fileExtension"
            $newFilePath = Join-Path -Path $folderPath -ChildPath $newFileName
        }

        #get the path and rename the files also it will throw error message if something is not allowed in the system
        Rename-Item -Path $filePath -NewName $newFileName -ErrorAction Stop

        Write-Host "Renamed '$($file.Name)' to '$newFileName'" -ForegroundColor Green
        $counter++
    }

    Write-Host "All selected files have been renamed successfully!" -ForegroundColor Cyan
} else {
    Write-Host "No files selected. Exiting." -ForegroundColor Yellow
}

