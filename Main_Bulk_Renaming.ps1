# Load necessary components for WPF application
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

. ./Rename.ps1

# Function to convert a hex color to SolidColorBrush
function ConvertTo-SolidColorBrush {
    param ($hexColor)
    $Color = [Windows.Media.Color]::FromArgb(
        255, 
        [Convert]::ToByte($hexColor.Substring(1, 2), 16),
        [Convert]::ToByte($hexColor.Substring(3, 2), 16),
        [Convert]::ToByte($hexColor.Substring(5, 2), 16) 
    )
    $Brush = New-Object Windows.Media.SolidColorBrush
    $Brush.Color = $Color
    return $Brush
}

function Create-StyledButton {
    param (
        [string]$Content,
        [int]$Row,
        [int]$Column
    )
    $Button = New-Object Windows.Controls.Button
    $Button.Content = $Content
    $Button.Width = 100
    $Button.Height = 30
    $Button.Margin = [Windows.Thickness]::new(5)
    $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $Button.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.FontSize = 12
    $Button.FontWeight = "Bold"
    $Button.SetValue([Windows.Controls.Grid]::RowProperty, $Row)
    $Button.SetValue([Windows.Controls.Grid]::ColumnProperty, $Column)
    return $Button
}

function Create-SmallButton {
    param ($Content, $Row, $Column)
    $Button = New-Object Windows.Controls.Button
    $Button.Content = $Content
    $Button.Width = 100
    $Button.Height = 30
    $Button.Margin = [Windows.Thickness]::new(5)
    $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $Button.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.FontSize = 12
    $Button.FontWeight = "Bold"
    $Button.SetValue([Windows.Controls.Grid]::RowProperty, $Row)
    $Button.SetValue([Windows.Controls.Grid]::ColumnProperty, $Column)
    return $Button
}

function Create-Button {
    param ($Content, $TopMargin, $Width = 200, $Height = 40)
    $Button = New-Object Windows.Controls.Button
    $Button.Content = $Content
    $Button.Width = $Width
    $Button.Height = $Height
    $Button.HorizontalAlignment = "Center"
    $Button.VerticalAlignment = "Top"
    $Button.Margin = [Windows.Thickness]::new(0, $TopMargin, 0, 0)
    $Button.FontSize = 14
    $Button.FontWeight = "Bold"
    $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $Button.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.BorderThickness = [Windows.Thickness]::new(2)

    # Add hover effect
    $Button.Add_MouseEnter({
        if ($Button -is [System.Windows.Controls.Button]) {
            $Button.Background = (ConvertTo-SolidColorBrush "#64B5F6")
        }
    })
    $Button.Add_MouseLeave({
        if ($Button -is [System.Windows.Controls.Button]) {
            $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
        }
    })
    return $Button
}

# Function to handle the bulk rename button click
function HandleBulkRenameClick {
    param()
    $MainPageWindow.Hide()  # Hide the MainPageWindow first
    #----------------BULK RENAMING WINDOW -----------------------#

    $BulkRenamingWindow = New-Object Windows.Window
    $BulkRenamingWindow.Title = "SHIFTIFY: Bulk Renaming"
    $BulkRenamingWindow.Height = 650
    $BulkRenamingWindow.Width = 400
    $BulkRenamingWindow.WindowStartupLocation = "CenterScreen"
    $BulkRenamingWindow.FontFamily = "Segoe UI"
    $BulkRenamingWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")
    $BulkRenamingWindow.ResizeMode = "NoResize"
    $BulkRenamingWindow.WindowStyle = "SingleBorderWindow"

    # Create a Grid for Bulk Renaming Window
    $BulkGrid = New-Object Windows.Controls.Grid

    # Title for Bulk Renaming Window
    $BulkTitleBorder = New-Object Windows.Controls.Border
    $BulkTitleBorder.Width = 350
    $BulkTitleBorder.Height = 60
    $BulkTitleBorder.HorizontalAlignment = "Center"
    $BulkTitleBorder.VerticalAlignment = "Top"
    $BulkTitleBorder.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
    $BulkTitleBorder.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $BulkTitleBorder.CornerRadius = [Windows.CornerRadius]::new(20)
    $BulkTitleBorder.BorderBrush = (ConvertTo-SolidColorBrush "#4682B4")
    $BulkTitleBorder.BorderThickness = [Windows.Thickness]::new(3)

    $BulkTitleTextBlock = New-Object Windows.Controls.TextBlock
    $BulkTitleTextBlock.Text = "Bulk Renaming"
    $BulkTitleTextBlock.FontSize = 24
    $BulkTitleTextBlock.FontWeight = "Bold"
    $BulkTitleTextBlock.HorizontalAlignment = "Center"
    $BulkTitleTextBlock.VerticalAlignment = "Center"
    $BulkTitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")

    $BulkTitleBorder.Child = $BulkTitleTextBlock
    $BulkGrid.Children.Add($BulkTitleBorder)

    # Center panel for actions and input
    $CenterStackPanel = New-Object Windows.Controls.StackPanel
    $CenterStackPanel.HorizontalAlignment = "Center"
    $CenterStackPanel.VerticalAlignment = "Top"
    $CenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)
    
    # File selection button
    $SelectFilesButton = New-Object Windows.Controls.Button
    $SelectFilesButton.Content = "Select File"
    $SelectFilesButton.Width = 130
    $SelectFilesButton.Height = 35
    $SelectFilesButton.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $SelectFilesButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $SelectFilesButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $SelectFilesButton.FontSize = 14
    $SelectFilesButton.FontWeight = "Bold"
    $CenterStackPanel.Children.Add($SelectFilesButton)

    # File list box
    $FileListBox = New-Object Windows.Controls.ListBox
    $FileListBox.Width = 300
    $FileListBox.Height = 100
    $FileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $FileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $FileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $FileListBox.BorderThickness = [Windows.Thickness]::new(2)
    $CenterStackPanel.Children.Add($FileListBox)

    # Layout for "Enter Base Name" Label and TextBox
    $BaseNamePanel = New-Object Windows.Controls.StackPanel
    $BaseNamePanel.Orientation = "Horizontal"
    $BaseNamePanel.HorizontalAlignment = "Center"
    $BaseNamePanel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)

    # Basename Label
    $BaseNameLabel = New-Object Windows.Controls.TextBlock
    $BaseNameLabel.Text = "Enter Base Name: "
    $BaseNameLabel.FontSize = 14
    $BaseNameLabel.VerticalAlignment = "Center"
    $BaseNamePanel.Children.Add($BaseNameLabel)

    # Basename Text Box
    $BaseNameTextBox = New-Object Windows.Controls.TextBox
    $BaseNameTextBox.Width = 177
    $BaseNameTextBox.FontSize = 14
    $BaseNameTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $BaseNameTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $BaseNameTextBox.Margin = [Windows.Thickness]::new(10, 0, 0, 0)
    $BaseNamePanel.Children.Add($BaseNameTextBox)

    # Add the BaseNamePanel to the main StackPanel
    $CenterStackPanel.Children.Add($BaseNamePanel)

    # Button Grid
    $ButtonGrid = New-Object Windows.Controls.Grid
    $ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

    # Buttons for Rename, Undo, Redo
    for ($row = 0; $row -lt 2; $row++) {
        $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    $RenameButton = Create-SmallButton -Content "Rename" -Row 0 -Column 0
    $UndoButton = Create-SmallButton -Content "Undo" -Row 1 -Column 0
    $RedoButton = Create-SmallButton -Content "Redo" -Row 0 -Column 1

    $ButtonGrid.Children.Add($RenameButton)
    $ButtonGrid.Children.Add($UndoButton)
    $ButtonGrid.Children.Add($RedoButton)

    # Add the ButtonGrid to the main StackPanel
    $CenterStackPanel.Children.Add($ButtonGrid)

    # Add title for Output TextBox
    $OutputTitle = New-Object Windows.Controls.TextBlock
    $OutputTitle.Text = "Renamed Files:"
    $OutputTitle.FontSize = 14
    $OutputTitle.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
    $OutputTitle.HorizontalAlignment = "Center"
    $CenterStackPanel.Children.Add($OutputTitle)

    # Adjust layout for Output TextBox below the buttons
    $OutputTextBox = New-Object Windows.Controls.TextBox
    $OutputTextBox.Width = 300
    $OutputTextBox.Height = 100
    $OutputTextBox.FontSize = 12
    $OutputTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $OutputTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $OutputTextBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $OutputTextBox.BorderThickness = [Windows.Thickness]::new(2)
    $OutputTextBox.IsReadOnly = $true  # Makes the TextBox read-only (can't be edited by the user)
    $OutputTextBox.VerticalScrollBarVisibility = "Auto"
    $OutputTextBox.HorizontalScrollBarVisibility = "Auto"

    # Add the Output TextBox after the ButtonGrid
    $CenterStackPanel.Children.Add($OutputTextBox)

    # Bulk Renaming Back button
    $BackButton = New-Object Windows.Controls.Button
    $BackButton.Content = "Back"
    $BackButton.Width = 100
    $BackButton.Height = 30
    $BackButton.Margin = [Windows.Thickness]::new(0, 1, 0, 0)
    $BackButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $BackButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $BackButton.FontSize = 12
    $BackButton.FontWeight = "Bold"
    $BackButton.HorizontalAlignment = "Center"

    # Set the "Back" button's position in the grid
    [Windows.Controls.Grid]::SetRow($BackButton, 1)
    [Windows.Controls.Grid]::SetColumn($BackButton, 1)

    # Add the "Back" button to the ButtonGrid
    $ButtonGrid.Children.Add($BackButton)
    
    $BulkGrid.Children.Add($CenterStackPanel)

    $BulkRenamingWindow.Content = $BulkGrid

    # Back button logic for Bulk Renaming page
    $BackButton.Add_Click({
        $BulkRenamingWindow.Hide()
        $MainPageWindow.ShowDialog() | Out-Null
    })
    # File selection logic
    $SelectFilesButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "All Files (*.*)|*.*"
        $OpenFileDialog.Title = "Select files to rename"
        $OpenFileDialog.Multiselect = $true 

        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $FileListBox.Items.Clear()  # Clear any existing items in the list box
    
            # Loop through selected files
            foreach ($file in $OpenFileDialog.FileNames) {
                $FileListBox.Items.Add($file)  # Add each selected file path to the list box
                # Add each selected file path to the OutputTextBox
            }
        }
    })
    # Rename button logic
    $RenameButton.Add_Click({
        $MainPageWindow.Hide()
        $BulkRenamingWindow.Show()
    
        $baseName = $BaseNameTextBox.Text
    
        # Check if any files have been selected
        if ($FileListBox.Items.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select files before proceeding.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        # Get selected files from the FileListBox
        $selectedFiles = $FileListBox.Items
    
        # Perform the batch renaming operation
        $batchOperation = Rename-WithBaseName -selectedFiles $selectedFiles -baseName $baseName
    
        # Add the operation to the undo stack (for potential undo functionality)
        $undoStack += ,$batchOperation
        $redoStack = @()  # Clear the redo stack since new operations are performed
    
        # Display the renamed files in the OutputTextBox
        $OutputTextBox.Text = ""  # Clear previous output
    
        foreach ($operation in $batchOperation) {
            # Extract the file name part only (not the full path)
            $originalFileName = [System.IO.Path]::GetFileName($operation.OriginalPath)
            $newFileName = [System.IO.Path]::GetFileName($operation.NewPath)
    
            # Display the renaming result in the OutputTextBox
            $OutputTextBox.Text += "Renamed '$originalFileName' to '$newFileName'`r`n"
        }
    })
    # Redo button logic
    $RedoButton.Add_Click({
        if ($redoStack.Count -gt 0) {
            # Get the last operation from the redo stack
            $operationToRedo = $redoStack[-1]
            $redoStack = $redoStack[0..($redoStack.Count - 2)]  # Remove last operation from redo stack

            # Perform the redo operation (reapply the renaming)
            foreach ($action in $operationToRedo) {
                Rename-Item -Path $action.OriginalPath -NewName (Split-Path -Leaf $action.NewPath) -ErrorAction Stop
                Write-Host "Redo: Renamed '$($action.OriginalPath)' back to '$($action.NewPath)'" -ForegroundColor Cyan
            }

            # Push the operation back to the undo stack
            $undoStack += ,$operationToRedo
            Write-Host "Redo completed." -ForegroundColor Cyan
        } else {
            [System.Windows.Forms.MessageBox]::Show("No actions to redo.", "Redo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
    # Undo button logic
    $UndoButton.Add_Click({
        if ($undoStack.Count -gt 0) {
            # Get the last operation from the undo stack
            $lastBatch = $undoStack[-1]
            $undoStack = $undoStack[0..($undoStack.Count - 2)]  # Remove last operation from undo stack

            # Undo each rename in reverse order (restore original file names)
            foreach ($action in $lastBatch) {
                Rename-Item -Path $action.NewPath -NewName (Split-Path -Leaf $action.OriginalPath) -ErrorAction Stop
                Write-Host "Undo: Renamed '$($action.NewPath)' back to '$($action.OriginalPath)'" -ForegroundColor Cyan
            }

            # Push the operation to the redo stack
            $redoStack += ,$lastBatch
            Write-Host "Undo completed." -ForegroundColor Cyan
        } else {
            [System.Windows.Forms.MessageBox]::Show("Nothing to undo.", "Undo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
    # Show the Bulk Renaming window modally
    $BulkRenamingWindow.ShowDialog() | Out-Null
}

function Show-ReplaceWindow {
    param()
    $MainPageWindow.Hide()
    
    # Create the Replace window
    $ReplaceWindow = New-Object Windows.Window
    $ReplaceWindow.Title = "SHIFTIFY: Text Substitution Tool"
    $ReplaceWindow.Height = 650
    $ReplaceWindow.Width = 400
    $ReplaceWindow.WindowStartupLocation = "CenterScreen"
    $ReplaceWindow.FontFamily = "Segoe UI"
    $ReplaceWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")
    $ReplaceWindow.ResizeMode = "NoResize"
    $ReplaceWindow.WindowStyle = "SingleBorderWindow"

    # Create a Grid for Replace Page
    $ReplaceGrid = New-Object Windows.Controls.Grid

    # Title for Replace Page
    $ReplaceTitleBorder = New-Object Windows.Controls.Border
    $ReplaceTitleBorder.Width = 350
    $ReplaceTitleBorder.Height = 60
    $ReplaceTitleBorder.HorizontalAlignment = "Center"
    $ReplaceTitleBorder.VerticalAlignment = "Top"
    $ReplaceTitleBorder.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
    $ReplaceTitleBorder.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceTitleBorder.CornerRadius = [Windows.CornerRadius]::new(20)
    $ReplaceTitleBorder.BorderBrush = (ConvertTo-SolidColorBrush "#4682B4")
    $ReplaceTitleBorder.BorderThickness = [Windows.Thickness]::new(3)

    $ReplaceTitleTextBlock = New-Object Windows.Controls.TextBlock
    $ReplaceTitleTextBlock.Text = "Replacing Word"
    $ReplaceTitleTextBlock.FontSize = 24
    $ReplaceTitleTextBlock.FontWeight = "Bold"
    $ReplaceTitleTextBlock.HorizontalAlignment = "Center"
    $ReplaceTitleTextBlock.VerticalAlignment = "Center"
    $ReplaceTitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")

    $ReplaceTitleBorder.Child = $ReplaceTitleTextBlock
    $ReplaceGrid.Children.Add($ReplaceTitleBorder)

    # Center panel for actions and input
    $ReplaceCenterStackPanel = New-Object Windows.Controls.StackPanel
    $ReplaceCenterStackPanel.HorizontalAlignment = "Center"
    $ReplaceCenterStackPanel.VerticalAlignment = "Top"
    $ReplaceCenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

    # File selection button
    $ReplaceSelectFileButton = New-Object Windows.Controls.Button
    $ReplaceSelectFileButton.Content = "Select File"
    $ReplaceSelectFileButton.Width = 130
    $ReplaceSelectFileButton.Height = 35
    $ReplaceSelectFileButton.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $ReplaceSelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceSelectFileButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceSelectFileButton.FontSize = 14
    $ReplaceSelectFileButton.FontWeight = "Bold"
    $ReplaceCenterStackPanel.Children.Add($ReplaceSelectFileButton)

    # File list box
    $ReplaceFileListBox = New-Object Windows.Controls.ListBox
    $ReplaceFileListBox.Width = 300
    $ReplaceFileListBox.Height = 100
    $ReplaceFileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $ReplaceFileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $ReplaceFileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceFileListBox.BorderThickness = [Windows.Thickness]::new(2)
    $ReplaceCenterStackPanel.Children.Add($ReplaceFileListBox)

    # Create a horizontal StackPanel for Replace/With inputs
    $ReplaceWithPanel = New-Object Windows.Controls.StackPanel
    $ReplaceWithPanel.Orientation = "Horizontal"
    $ReplaceWithPanel.HorizontalAlignment = "Center"
    $ReplaceWithPanel.Margin = [Windows.Thickness]::new(0, 10, 0, 0)

    # Text box and label for "Replace"
    $ReplaceLabel = New-Object Windows.Controls.TextBlock
    $ReplaceLabel.Text = "Replace:"
    $ReplaceLabel.FontSize = 14
    $ReplaceLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $ReplaceWithPanel.Children.Add($ReplaceLabel)

    $ReplaceTextBox = New-Object Windows.Controls.TextBox
    $ReplaceTextBox.Width = 100
    $ReplaceTextBox.FontSize = 14
    $ReplaceTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $ReplaceTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceTextBox.Margin = [Windows.Thickness]::new(0, 0, 10, 0)
    $ReplaceWithPanel.Children.Add($ReplaceTextBox)

    # Text box and label for "With"
    $SubstituteWithLabel = New-Object Windows.Controls.TextBlock
    $SubstituteWithLabel.Text = "With:"
    $SubstituteWithLabel.FontSize = 14
    $SubstituteWithLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $ReplaceWithPanel.Children.Add($SubstituteWithLabel)

    $SubstituteWithTextBox = New-Object Windows.Controls.TextBox
    $SubstituteWithTextBox.Width = 95
    $SubstituteWithTextBox.FontSize = 14
    $SubstituteWithTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $SubstituteWithTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceWithPanel.Children.Add($SubstituteWithTextBox)

    $ReplaceCenterStackPanel.Children.Add($ReplaceWithPanel)

    # Buttons for Apply, Undo, Redo
    $ReplaceButtonGrid = New-Object Windows.Controls.Grid
    $ReplaceButtonGrid.Margin = [Windows.Thickness]::new(0, 10, 0, 0)

    for ($row = 0; $row -lt 2; $row++) {
        $ReplaceButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ReplaceButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    $ReplaceApplyButton = Create-SmallButton -Content "Apply" -Row 0 -Column 0
    $ReplaceUndoButton = Create-SmallButton -Content "Undo" -Row 1 -Column 0
    $ReplaceRedoButton = Create-SmallButton -Content "Redo" -Row 0 -Column 1

    $ReplaceButtonGrid.Children.Add($ReplaceApplyButton)
    $ReplaceButtonGrid.Children.Add($ReplaceUndoButton)
    $ReplaceButtonGrid.Children.Add($ReplaceRedoButton)
    
    # Add the ButtonGrid to the main StackPanel
    $ReplaceCenterStackPanel.Children.Add($ReplaceButtonGrid)

    # Title for Output TextBox
    $OutputTitle = New-Object Windows.Controls.TextBlock
    $OutputTitle.Text = "Renamed Files:"
    $OutputTitle.FontSize = 14
    $OutputTitle.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
    $OutputTitle.HorizontalAlignment = "Center"
    $ReplaceCenterStackPanel.Children.Add($OutputTitle)

    # Layout for Output TextBox 
    $ReplaceOutputTextBox = New-Object Windows.Controls.TextBox
    $ReplaceOutputTextBox.Width = 300
    $ReplaceOutputTextBox.Height = 100
    $ReplaceOutputTextBox.FontSize = 12
    $ReplaceOutputTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $ReplaceOutputTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceOutputTextBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $ReplaceOutputTextBox.BorderThickness = [Windows.Thickness]::new(2)
    $ReplaceOutputTextBox.IsReadOnly = $true  # Makes the TextBox read-only (can't be edited by the user)
    $ReplaceOutputTextBox.VerticalScrollBarVisibility = "Auto"
    $ReplaceOutputTextBox.HorizontalScrollBarVisibility = "Auto"

    # Output TextBox after the ButtonGrid
    $ReplaceCenterStackPanel.Children.Add($ReplaceOutputTextBox)

    # Replace Back button
    $ReplaceBackButton = New-Object Windows.Controls.Button
    $ReplaceBackButton.Content = "Back"
    $ReplaceBackButton.Width = 100
    $ReplaceBackButton.Height = 30
    $ReplaceBackButton.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $ReplaceBackButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceBackButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceBackButton.FontSize = 12
    $ReplaceBackButton.FontWeight = "Bold"
    $ReplaceBackButton.HorizontalAlignment = "Center"

    # Set the "Back" button's position in the grid
    [Windows.Controls.Grid]::SetRow($ReplaceBackButton, 1)
    [Windows.Controls.Grid]::SetColumn($ReplaceBackButton, 1)

    $ReplaceButtonGrid.Children.Add($ReplaceBackButton)

    $ReplaceGrid.Children.Add($ReplaceCenterStackPanel)

    $ReplaceWindow.Content = $ReplaceGrid

    #Back button logic
    $ReplaceBackButton.Add_Click({
        $ReplaceWindow.Close()  # Close the current Replace window
        $MainPageWindow.ShowDialog() | Out-Null # Open the main window
    })

    # Select File logic
    $ReplaceSelectFileButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "All Files (*.*)|*.*"
        $OpenFileDialog.Title = "Select files to rename"
        $OpenFileDialog.Multiselect = $true 

        if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ReplaceFileListBox.Items.Clear()  # Clear any existing items in the list box
    
            # Loop through selected files
            foreach ($file in $OpenFileDialog.FileNames) {
                $ReplaceFileListBox.Items.Add($file)  # Add each selected file path to the list box
            }
        }
    })

    $ReplaceApplyButton.Add_Click({
        $patternToFind = $ReplaceTextBox.Text
        $replacementWord = $SubstituteWithTextBox.Text

        if (-not $patternToFind -or -not $replacementWord) {
            Write-Host "Error: Both 'Replace' and 'With' fields must be filled." -ForegroundColor Red
            return
        }

        $selectedFiles = $ReplaceFileListBox.Items
        $batchOperation = Rename-WithPatternReplacement -selectedFiles $selectedFiles -patternToFind $patternToFind -replacementWord $replacementWord

        $undoStack += ,$batchOperation
        $redoStack = @()  # Clear the redo stack since new operations are performed
    
        # Display the renamed files in the OutputTextBox
        $ReplaceOutputTextBox.Text = ""  # Clear previous output
    
        foreach ($operation in $batchOperation) {
            $originalFileName = [System.IO.Path]::GetFileName($operation.OriginalPath)
            $newFileName = [System.IO.Path]::GetFileName($operation.NewPath)
    
            # Display the renaming result in the OutputTextBox
            $ReplaceOutputTextBox.Text += "Renamed '$originalFileName' to '$newFileName'`r`n"
        }
    })

    $ReplaceWindow.Content = $ReplaceGrid
    $ReplaceWindow.ShowDialog() | Out-Null
}

function ShowPrefixsuffixWindow {
    param()
    $MainPageWindow.Hide()

    # Create the Prefix-Suffix window
    $PrefixSuffixWindow = New-Object Windows.Window
    $PrefixSuffixWindow.Title = "SHIFTIFY: Prefix and Suffix Tool"
    $PrefixSuffixWindow.Height = 650
    $PrefixSuffixWindow.Width = 400
    $PrefixSuffixWindow.WindowStartupLocation = "CenterScreen"
    $PrefixSuffixWindow.FontFamily = "Segoe UI"
    $PrefixSuffixWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")
    $PrefixSuffixWindow.ResizeMode = "NoResize"
    $PrefixSuffixWindow.WindowStyle = "SingleBorderWindow"

    # Create a Grid for Prefix-Suffix Page
    $PrefixSuffixGrid = New-Object Windows.Controls.Grid

    # Title for Prefix-Suffix Page
    $PrefixSuffixTitleBorder = New-Object Windows.Controls.Border
    $PrefixSuffixTitleBorder.Width = 350
    $PrefixSuffixTitleBorder.Height = 60
    $PrefixSuffixTitleBorder.HorizontalAlignment = "Center"
    $PrefixSuffixTitleBorder.VerticalAlignment = "Top"
    $PrefixSuffixTitleBorder.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
    $PrefixSuffixTitleBorder.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $PrefixSuffixTitleBorder.CornerRadius = [Windows.CornerRadius]::new(20)
    $PrefixSuffixTitleBorder.BorderBrush = (ConvertTo-SolidColorBrush "#4682B4")
    $PrefixSuffixTitleBorder.BorderThickness = [Windows.Thickness]::new(3)

    $PrefixSuffixTitleTextBlock = New-Object Windows.Controls.TextBlock
    $PrefixSuffixTitleTextBlock.Text = "Add Prefix and Suffix"
    $PrefixSuffixTitleTextBlock.FontSize = 24
    $PrefixSuffixTitleTextBlock.FontWeight = "Bold"
    $PrefixSuffixTitleTextBlock.HorizontalAlignment = "Center"
    $PrefixSuffixTitleTextBlock.VerticalAlignment = "Center"
    $PrefixSuffixTitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")

    $PrefixSuffixTitleBorder.Child = $PrefixSuffixTitleTextBlock
    $PrefixSuffixGrid.Children.Add($PrefixSuffixTitleBorder)

    # Center panel for actions and input
    $PrefixSuffixCenterStackPanel = New-Object Windows.Controls.StackPanel
    $PrefixSuffixCenterStackPanel.HorizontalAlignment = "Center"
    $PrefixSuffixCenterStackPanel.VerticalAlignment = "Top"
    $PrefixSuffixCenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

    # File selection button
    $PrefixSuffixSelectFileButton = New-Object Windows.Controls.Button
    $PrefixSuffixSelectFileButton.Content = "Select File"
    $PrefixSuffixSelectFileButton.Width = 130
    $PrefixSuffixSelectFileButton.Height = 35
    $PrefixSuffixSelectFileButton.Margin = [Windows.Thickness]::new(0, 10, 0, 10)
    $PrefixSuffixSelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $PrefixSuffixSelectFileButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $PrefixSuffixSelectFileButton.FontSize = 14
    $PrefixSuffixSelectFileButton.FontWeight = "Bold"
    $PrefixSuffixSelectFileButton.Add_Click({
        $dialog = New-Object Windows.Forms.OpenFileDialog
        $dialog.Multiselect = $true
        $dialog.ShowDialog() | Out-Null
        $dialog.FileNames | ForEach-Object { $PrefixSuffixFileListBox.Items.Add($_) }
    })
    $PrefixSuffixCenterStackPanel.Children.Add($PrefixSuffixSelectFileButton)

    # File list box
    $PrefixSuffixFileListBox = New-Object Windows.Controls.ListBox
    $PrefixSuffixFileListBox.Width = 300
    $PrefixSuffixFileListBox.Height = 100
    $PrefixSuffixFileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $PrefixSuffixFileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $PrefixSuffixFileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $PrefixSuffixFileListBox.BorderThickness = [Windows.Thickness]::new(2)
    $PrefixSuffixCenterStackPanel.Children.Add($PrefixSuffixFileListBox)

    # Text box and label for prefix
    $PrefixStackPanel = New-Object Windows.Controls.StackPanel
    $PrefixStackPanel.Orientation = "Horizontal"
    $PrefixStackPanel.HorizontalAlignment = "Center"
    $PrefixStackPanel.Margin = [Windows.Thickness]::new(0, 10, 0, 0)

    $PrefixLabel = New-Object Windows.Controls.TextBlock
    $PrefixLabel.Text = "Enter Prefix: "
    $PrefixLabel.FontSize = 14
    $PrefixLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $PrefixStackPanel.Children.Add($PrefixLabel)

    $PrefixTextBox = New-Object Windows.Controls.TextBox
    $PrefixTextBox.Width = 220
    $PrefixTextBox.FontSize = 14
    $PrefixTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $PrefixTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $PrefixStackPanel.Children.Add($PrefixTextBox)

    $PrefixSuffixCenterStackPanel.Children.Add($PrefixStackPanel)

    # Text box and label for suffix
    $SuffixStackPanel = New-Object Windows.Controls.StackPanel
    $SuffixStackPanel.Orientation = "Horizontal"
    $SuffixStackPanel.HorizontalAlignment = "Center"
    $SuffixStackPanel.Margin = [Windows.Thickness]::new(0, 10, 0, 0)

    $SuffixLabel = New-Object Windows.Controls.TextBlock
    $SuffixLabel.Text = "Enter Suffix: "
    $SuffixLabel.FontSize = 14
    $SuffixLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $SuffixStackPanel.Children.Add($SuffixLabel)

    $SuffixTextBox = New-Object Windows.Controls.TextBox
    $SuffixTextBox.Width = 220
    $SuffixTextBox.FontSize = 14
    $SuffixTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $SuffixTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $SuffixStackPanel.Children.Add($SuffixTextBox)

    $PrefixSuffixCenterStackPanel.Children.Add($SuffixStackPanel)

    # Buttons for Apply, Undo, Redo, and Back
    $ButtonGrid = New-Object Windows.Controls.Grid
    $ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 10)

    for ($row = 0; $row -lt 2; $row++) {
        $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    $ApplyButton = Create-SmallButton -Content "Apply" -Row 0 -Column 0
    $UndoButton = Create-SmallButton -Content "Undo" -Row 0 -Column 1
    $RedoButton = Create-SmallButton -Content "Redo" -Row 1 -Column 0
    $BackButton = Create-SmallButton -Content "Back" -Row 1 -Column 1

    $ButtonGrid.Children.Add($ApplyButton)
    $ButtonGrid.Children.Add($UndoButton)
    $ButtonGrid.Children.Add($RedoButton)
    $ButtonGrid.Children.Add($BackButton)

    $PrefixSuffixCenterStackPanel.Children.Add($ButtonGrid)

    # Add output display box with title
    $RenamedFilesTitle = New-Object Windows.Controls.TextBlock
    $RenamedFilesTitle.Text = "Renamed Files:"
    $RenamedFilesTitle.FontSize = 14
    $RenamedFilesTitle.HorizontalAlignment = "Center"
    $RenamedFilesTitle.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $PrefixSuffixCenterStackPanel.Children.Add($RenamedFilesTitle)

    $SuffixPrefixOutputTextBox = New-Object Windows.Controls.TextBox
    $SuffixPrefixOutputTextBox.Width = 300
    $SuffixPrefixOutputTextBox.Height = 100
    $SuffixPrefixOutputTextBox.FontSize = 12
    $SuffixPrefixOutputTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $SuffixPrefixOutputTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $SuffixPrefixOutputTextBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $SuffixPrefixOutputTextBox.IsReadOnly = $true
    $SuffixPrefixOutputTextBox.VerticalScrollBarVisibility = "Auto"
    $SuffixPrefixOutputTextBox.HorizontalScrollBarVisibility = "Auto"
    $PrefixSuffixCenterStackPanel.Children.Add($SuffixPrefixOutputTextBox)

    $PrefixSuffixGrid.Children.Add($PrefixSuffixCenterStackPanel)

    # Set Grid as content
    $PrefixSuffixWindow.Content = $PrefixSuffixGrid

    # Create undo and redo stacks
    $undoStack = New-Object System.Collections.Stack
    $redoStack = New-Object System.Collections.Stack

    # Function to store current state to the undo stack
    # function Save-CurrentState {
    #     $currentState = @{
    #         prefix = $PrefixTextBox.Text
    #         suffix = $SuffixTextBox.Text
    #         files = @($PrefixSuffixFileListBox.Items)
    #     }
    #     $undoStack.Push($currentState)
    #     $redoStack.Clear()  # Clear redo stack whenever a new state is saved
    # }

    # # Function to undo the last action
    # function Undo-Action {
    #     if ($undoStack.Count -gt 0) {
    #         $lastState = $undoStack.Pop()
    #         $PrefixTextBox.Text = $lastState.prefix
    #         $SuffixTextBox.Text = $lastState.suffix
    #         $PrefixSuffixFileListBox.Items.Clear()
    #         $lastState.files | ForEach-Object { $PrefixSuffixFileListBox.Items.Add($_) }
    #         $redoStack.Push($lastState)  # Push to redo stack
    #     }
    # }

    # # Function to redo the last undone action
    # function Redo-Action {
    #     if ($redoStack.Count -gt 0) {
    #         $lastUndoneState = $redoStack.Pop()
    #         $PrefixTextBox.Text = $lastUndoneState.prefix
    #         $SuffixTextBox.Text = $lastUndoneState.suffix
    #         $PrefixSuffixFileListBox.Items.Clear()
    #         $lastUndoneState.files | ForEach-Object { $PrefixSuffixFileListBox.Items.Add($_) }
    #         $undoStack.Push($lastUndoneState)  # Push to undo stack
    #     }
    # }

    $ApplyButton.Add_Click({
        # Get the prefix and suffix values from the textboxes
        $prefix = $PrefixTextBox.Text
        $suffix = $SuffixTextBox.Text
        
        # Ensure both prefix and suffix are entered
        if (-not $prefix -and -not $suffix) {
            Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
            return
        }
    
        # Get the list of selected files
        $selectedFiles = @()
        foreach ($file in $PrefixSuffixFileListBox.Items) {
            $selectedFiles += $file
        }
    
        # Call the Rename-WithPrefixSuffix function to rename the files
        $batchOperation = Rename-WithPrefixSuffix -selectedFiles $selectedFiles -prefix $prefix -suffix $suffix
        
        # Clear the output TextBox (but not the list box)
        $SuffixPrefixOutputTextBox.Clear()
    
        # Process each operation in batch
        foreach ($operation in $batchOperation) {
            # Format the renaming message
            $renamingMessage = "Renamed '$($operation.OriginalPath)' to '$($operation.NewPath)'"
            
            # Display the message in the output TextBox, appending to existing content
            $SuffixPrefixOutputTextBox.AppendText($renamingMessage + "`r`n")
        }
    })

    # Back Button Logic (close the current window and show the MainPageWindow)
    $BackButton.Add_Click({
        $PrefixSuffixWindow.Close()
        $MainPageWindow.ShowDialog() | Out-Null
    })

    # Show the Prefix-Suffix window
    $PrefixSuffixWindow.ShowDialog()
}


function showEncryptDecryptWindow {
    param()
    $MainPageWindow.Hide() 

    $EncryptionWindow = New-Object Windows.Window
    $EncryptionWindow.Title = "SHIFTIFY: Encryption and Decryption Tool"
    $EncryptionWindow.Height = 650
    $EncryptionWindow.Width = 400
    $EncryptionWindow.WindowStartupLocation = "CenterScreen"
    $EncryptionWindow.FontFamily = "Segoe UI"
    $EncryptionWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")
    $EncryptionWindow.ResizeMode = "NoResize"
    $EncryptionWindow.WindowStyle = "SingleBorderWindow"

    # Create a Grid for Encryption Page
    $EncryptionGrid = New-Object Windows.Controls.Grid

    # Title for Encryption Page
    $EncryptionTitleBorder = New-Object Windows.Controls.Border
    $EncryptionTitleBorder.Width = 350
    $EncryptionTitleBorder.Height = 60
    $EncryptionTitleBorder.HorizontalAlignment = "Center"
    $EncryptionTitleBorder.VerticalAlignment = "Top"
    $EncryptionTitleBorder.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
    $EncryptionTitleBorder.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $EncryptionTitleBorder.CornerRadius = [Windows.CornerRadius]::new(20)
    $EncryptionTitleBorder.BorderBrush = (ConvertTo-SolidColorBrush "#4682B4")
    $EncryptionTitleBorder.BorderThickness = [Windows.Thickness]::new(3)

    $EncryptionTitleTextBlock = New-Object Windows.Controls.TextBlock
    $EncryptionTitleTextBlock.Text = "Encryption and Decryption"
    $EncryptionTitleTextBlock.FontSize = 24
    $EncryptionTitleTextBlock.FontWeight = "Bold"
    $EncryptionTitleTextBlock.HorizontalAlignment = "Center"
    $EncryptionTitleTextBlock.VerticalAlignment = "Center"
    $EncryptionTitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")

    $EncryptionTitleBorder.Child = $EncryptionTitleTextBlock
    $EncryptionGrid.Children.Add($EncryptionTitleBorder)

    # Center panel for actions and input
    $EncryptionCenterStackPanel = New-Object Windows.Controls.StackPanel
    $EncryptionCenterStackPanel.HorizontalAlignment = "Center"
    $EncryptionCenterStackPanel.VerticalAlignment = "Top"
    $EncryptionCenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

    # File selection button
    $SelectFileButton = New-Object Windows.Controls.Button
    $SelectFileButton.Content = "Select File"
    $SelectFileButton.Width = 150
    $SelectFileButton.Height = 35
    $SelectFileButton.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $SelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $SelectFileButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $SelectFileButton.FontSize = 14
    $SelectFileButton.FontWeight = "Bold"
    $EncryptionCenterStackPanel.Children.Add($SelectFileButton)

    # File list box
    $EncryptionFileListBox = New-Object Windows.Controls.ListBox
    $EncryptionFileListBox.Width = 300
    $EncryptionFileListBox.Height = 100
    $EncryptionFileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $EncryptionFileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $EncryptionFileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $EncryptionFileListBox.BorderThickness = [Windows.Thickness]::new(2)
    $EncryptionCenterStackPanel.Children.Add($EncryptionFileListBox)

    # Text box for "Enter secret key"
    $FindLabel = New-Object Windows.Controls.TextBlock
    $FindLabel.Text = "Enter secret key: "
    $FindLabel.FontSize = 14
    $FindLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
    $FindLabel.HorizontalAlignment = "Center"
    $EncryptionCenterStackPanel.Children.Add($FindLabel)

    $FindTextBox = New-Object Windows.Controls.TextBox
    $FindTextBox.Width = 200
    $FindTextBox.FontSize = 14
    $FindTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $FindTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $FindTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
    $EncryptionCenterStackPanel.Children.Add($FindTextBox)

    # Buttons for Encrypt, Decrypt, Reset, and Back
    $ButtonGrid = New-Object Windows.Controls.Grid
    $ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
    $ButtonGrid.HorizontalAlignment = "Center"
    $ButtonGrid.VerticalAlignment = "Center"

    for ($row = 0; $row -lt 2; $row++) {
        $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    $EncryptButton = Create-StyledButton -Content "Encrypt" -Row 0 -Column 0
    $DecryptButton = Create-StyledButton -Content "Decrypt" -Row 0 -Column 1
    $ResetButton = Create-StyledButton -Content "Reset" -Row 1 -Column 0
    $BackButton = Create-StyledButton -Content "Back" -Row 1 -Column 1

    $ButtonGrid.Children.Add($EncryptButton)
    $ButtonGrid.Children.Add($DecryptButton)
    $ButtonGrid.Children.Add($ResetButton)
    $ButtonGrid.Children.Add($BackButton)

    $EncryptionCenterStackPanel.Children.Add($ButtonGrid)
    $EncryptionGrid.Children.Add($EncryptionCenterStackPanel)


    # Set Grid as content
    $EncryptionWindow.Content = $EncryptionGrid

    # File Selection Logic
    $SelectFileButton.Add_Click({
        $OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
        $OpenFileDialog.Multiselect = $true
        $OpenFileDialog.Title = "Select Files"

        if ($OpenFileDialog.ShowDialog()) {
            $EncryptionFileListBox.Items.Clear()
            foreach ($file in $OpenFileDialog.FileNames) {
                $EncryptionFileListBox.Items.Add($file)
            }
        }
    })

    # Reset Button Logic
    $EncryptButton.Add_Click({
        if ($EncryptionFileListBox.Items.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select files to encrypt.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $Password = $FindTextBox.Text
        if ([string]::IsNullOrWhiteSpace($Password)) {
            [System.Windows.Forms.MessageBox]::Show("Please enter a secret key.", "No Secret Key", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $successCount = 0
        foreach ($filePath in $EncryptionFileListBox.Items) {
            try {
                Encrypt-File -InputFile $filePath -Password $Password
                Write-Host "Success: File Encrypted successfully: $filePath" -ForegroundColor Green
                $successCount++
            } catch {
                Write-Host "Error: Failed to encrypt file: $filePath`n$_" -ForegroundColor Red
            }
        }
    
        if ($successCount -eq $EncryptionFileListBox.Items.Count) {
            [System.Windows.Forms.MessageBox]::Show("All files were successfully encrypted.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
      

    $DecryptButton.Add_Click({
        if ($EncryptionFileListBox.Items.Count -eq 0) {
            Write-Host "Warning: Please select files to decrypt." -ForegroundColor Yellow
            return
        }
    
        $Password = $FindTextBox.Text
        if ([string]::IsNullOrWhiteSpace($Password)) {
            Write-Host "Warning: Please enter a secret key." -ForegroundColor Yellow
            return
        }
    
        $successCount = 0
        foreach ($filePath in $EncryptionFileListBox.Items) {
            try {
                Decrypt-File -InputFile $filePath -Password $Password
                Write-Host "Success: File Decrypted successfully: $filePath" -ForegroundColor Green
                $successCount++
            } catch {
                Write-Host "Error: Failed to decrypt file: $filePath`n$_" -ForegroundColor Red
            }
        }
    
        if ($successCount -eq $EncryptionFileListBox.Items.Count) {
            [System.Windows.Forms.MessageBox]::Show("All files were successfully decrypted.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    })
    

    # Back Button Logic
    $BackButton.Add_Click({
        if ($null -eq $MainPageWindow) {
            [System.Windows.MessageBox]::Show("Main Page is not available.", "Error", "OK", "Error")
        } else {
            $EncryptionWindow.Hide()
            $MainPageWindow.ShowDialog() | Out-Null
        }
    })

    # Show Encryption Window (for standalone testing)
    $EncryptionWindow.ShowDialog() | Out-Null
}


# Main code for the application window (unchanged)
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
$form.ShowInTaskbar = $false
$form.Opacity = 0
$form.Size = New-Object System.Drawing.Size(1, 1)

# Main Window
$MainPageWindow = New-Object Windows.Window
$MainPageWindow.Title = "SHIFTIFY: Main Page"
$MainPageWindow.Height = 600
$MainPageWindow.Width = 400
$MainPageWindow.WindowStartupLocation = "CenterScreen"
$MainPageWindow.FontFamily = "Segoe UI"
$MainPageWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")
$MainPageWindow.ResizeMode = "NoResize"
$MainPageWindow.WindowStyle = "SingleBorderWindow"

# Main Grid
$MainGrid = New-Object Windows.Controls.Grid
$MainGrid.HorizontalAlignment = "Center"
$MainGrid.VerticalAlignment = "Center"

# Load the Logo Image
$LogoSource = New-Object System.Windows.Media.Imaging.BitmapImage
$LogoSource.BeginInit()
$LogoSource.UriSource = New-Object System.Uri("Shiftify Logo.png", [System.UriKind]::RelativeOrAbsolute)  
$LogoSource.EndInit()

# Create an Image Control for the Logo
$LogoImage = New-Object Windows.Controls.Image
$LogoImage.Source = $LogoSource
$LogoImage.Width = 800 # Adjust as needed
$LogoImage.Height = 290 # Adjust as needed
$LogoImage.HorizontalAlignment = "Center"
$LogoImage.VerticalAlignment = "Top"
$LogoImage.Margin = [Windows.Thickness]::new(0, -115, 0, 0)

# Add the Logo to the Main Grid
$MainGrid.Children.Add($LogoImage) | Out-Null

# Buttons
$ButtonStackPanel = New-Object Windows.Controls.StackPanel
$ButtonStackPanel.HorizontalAlignment = "Center"
$ButtonStackPanel.VerticalAlignment = "Top"
$ButtonStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

$BulkRenameButton = Create-Button -Content "Bulk Renaming" -TopMargin 0
$PrefixSuffixButton = Create-Button -Content "Prefix and Suffix" -TopMargin 10
$ReplaceButton = Create-Button -Content "Replacing" -TopMargin 10
$EncryptButton = Create-Button -Content "Encryption" -TopMargin 10

# Add buttons to the stack panel and suppress output
$ButtonStackPanel.Children.Add($BulkRenameButton) | Out-Null
$ButtonStackPanel.Children.Add($ReplaceButton) | Out-Null
$ButtonStackPanel.Children.Add($PrefixSuffixButton) | Out-Null
$ButtonStackPanel.Children.Add($EncryptButton) | Out-Null

$MainGrid.Children.Add($ButtonStackPanel) | Out-Null

# Button Logic
$BulkRenameButton.Add_Click({
    HandleBulkRenameClick
})

$ReplaceButton.Add_Click({
    Show-ReplaceWindow
})

$PrefixSuffixButton.Add_Click({
    ShowPrefixsuffixWindow
})

$EncryptButton.Add_Click({
    showEncryptDecryptWindow
})
# Show the main window and suppress output
$MainPageWindow.Content = $MainGrid
$MainPageWindow.ShowDialog() | Out-Null