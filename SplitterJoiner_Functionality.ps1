# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create form to host dialogs but make it invisible
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.ShowInTaskbar = $false
$form.Opacity = 0
$form.Size = New-Object System.Drawing.Size(1,1)

# Define a function to split a file
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

# Define a function to join files
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

# Example usage
while ($true) {
    Write-Output "`nChoose an option:"
    Write-Output "1. Split a file"
    Write-Output "2. Join files"
    Write-Output "3. Exit"
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
            Write-Output "Program Terminated."
            $form.Close()
            break
        }
        default {
            Write-Output "Invalid choice. Please try again."
        }
    }
}