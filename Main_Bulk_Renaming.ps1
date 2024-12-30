# Load necessary components for WPF application
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
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

# Function to simplify button creation
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

#----------------MAIN PAGE WINDOW -----------------------#
$MainPageWindow = New-Object Windows.Window
$MainPageWindow.Title = "SHIFTIFY: Main Page"
$MainPageWindow.Height = 500
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

# Title SHIFTIFY
$TitleBorder = New-Object Windows.Controls.Border
$TitleBorder.Width = 350
$TitleBorder.Height = 60
$TitleBorder.HorizontalAlignment = "Center"
$TitleBorder.VerticalAlignment = "Top"
$TitleBorder.Margin = [Windows.Thickness]::new(0, -25, 0, 0)
$TitleBorder.Background = (ConvertTo-SolidColorBrush "#90CAF9")
$TitleBorder.CornerRadius = [Windows.CornerRadius]::new(20)
$TitleBorder.BorderBrush = (ConvertTo-SolidColorBrush "#4682B4")
$TitleBorder.BorderThickness = [Windows.Thickness]::new(3)

$TitleTextBlock = New-Object Windows.Controls.TextBlock
$TitleTextBlock.Text = "SHIFTIFY"
$TitleTextBlock.FontSize = 28
$TitleTextBlock.FontWeight = "Bold"
$TitleTextBlock.HorizontalAlignment = "Center"
$TitleTextBlock.VerticalAlignment = "Center"
$TitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")

$TitleBorder.Child = $TitleTextBlock
$MainGrid.Children.Add($TitleBorder)

# Subtitle ONE LINER
$SubtitleTextBlock = New-Object Windows.Controls.TextBlock
$SubtitleTextBlock.Text = "Rename. Replace. Encrypt."
$SubtitleTextBlock.FontSize = 16
$SubtitleTextBlock.FontStyle = "Italic"
$SubtitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
$SubtitleTextBlock.HorizontalAlignment = "Center"
$SubtitleTextBlock.Margin = [Windows.Thickness]::new(0, 55, 0, 0)
$MainGrid.Children.Add($SubtitleTextBlock)

# Buttons
$ButtonStackPanel = New-Object Windows.Controls.StackPanel
$ButtonStackPanel.HorizontalAlignment = "Center"
$ButtonStackPanel.VerticalAlignment = "Top"
$ButtonStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

$BulkRenameButton = Create-Button -Content "Bulk Renaming" -TopMargin 0
$PrefixSuffixButton = Create-Button -Content "Prefix and Suffix" -TopMargin 10
$ReplaceButton = Create-Button -Content "Replacing" -TopMargin 10
$EncryptButton = Create-Button -Content "Encryption" -TopMargin 10


$ButtonStackPanel.Children.Add($BulkRenameButton)
$ButtonStackPanel.Children.Add($PrefixSuffixButton)
$ButtonStackPanel.Children.Add($ReplaceButton)
$ButtonStackPanel.Children.Add($EncryptButton)

$MainGrid.Children.Add($ButtonStackPanel)

$BulkRenameButton.Add_Click({
    $MainPageWindow.Hide()
    $BulkRenamingWindow.ShowDialog() | Out-Null
})

# Replace button logic for opening Replace window
$ReplaceButton.Add_Click({
    $MainPageWindow.Hide()
    $ReplaceWindow.ShowDialog() | Out-Null
})

# Encryption button logic for opening Encryption window
$EncryptButton.Add_Click({
    $MainPageWindow.Hide()
    $EncryptionWindow.ShowDialog() | Out-Null
})

# Encryption button logic for opening Encryption window
$PrefixSuffixButton.Add_Click({
    $MainPageWindow.Hide()
    $PrefixSuffixWindowWindow.ShowDialog() | Out-Null
})

# Set Grid as content
$MainPageWindow.Content = $MainGrid

#----------------BULK RENAMING WINDOW -----------------------#
$BulkRenamingWindow = New-Object Windows.Window
$BulkRenamingWindow.Title = "SHIFTIFY: Bulk Renaming"
$BulkRenamingWindow.Height = 500
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
$SelectFilesButton = Create-Button -Content "Select a File" -TopMargin 0
$SelectFilesButton.Width = 150
$SelectFilesButton.Height = 40
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

# Text box for base name
$BaseNameLabel = New-Object Windows.Controls.TextBlock
$BaseNameLabel.Text = "Enter Base Name:"
$BaseNameLabel.FontSize = 14
$BaseNameLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$BaseNameLabel.HorizontalAlignment = "Center"
$CenterStackPanel.Children.Add($BaseNameLabel)

$BaseNameTextBox = New-Object Windows.Controls.TextBox
$BaseNameTextBox.Width = 200
$BaseNameTextBox.FontSize = 14
$BaseNameTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$BaseNameTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$BaseNameTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$CenterStackPanel.Children.Add($BaseNameTextBox)

# Buttons for Preview, Rename, Undo, Redo, Back
$ButtonGrid = New-Object Windows.Controls.Grid
$ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

for ($row = 0; $row -lt 2; $row++) {
    $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
}
for ($col = 0; $col -lt 2; $col++) {
    $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
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

$PreviewButton = Create-SmallButton -Content "Preview" -Row 0 -Column 0
$RenameButton = Create-SmallButton -Content "Rename" -Row 0 -Column 1
$UndoButton = Create-SmallButton -Content "Undo" -Row 1 -Column 0
$RedoButton = Create-SmallButton -Content "Redo" -Row 1 -Column 1

$ButtonGrid.Children.Add($PreviewButton)
$ButtonGrid.Children.Add($RenameButton)
$ButtonGrid.Children.Add($UndoButton)
$ButtonGrid.Children.Add($RedoButton)

$CenterStackPanel.Children.Add($ButtonGrid)

# Back button
$BackButton = New-Object Windows.Controls.Button
$BackButton.Content = "Back"
$BackButton.Width = 100
$BackButton.Height = 30
$BackButton.Margin = [Windows.Thickness]::new(0, 3, 0, 0)
$BackButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
$BackButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
$BackButton.FontSize = 12
$BackButton.FontWeight = "Bold"
$CenterStackPanel.Children.Add($BackButton)

$BulkGrid.Children.Add($CenterStackPanel)

$BulkRenamingWindow.Content = $BulkGrid

# Back button logic for Bulk Renaming page
$BackButton.Add_Click({
    $BulkRenamingWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

$SelectFilesButton.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select files to rename"
    $OpenFileDialog.Multiselect = $true 

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $FileListBox.Items.Clear()  # Clear any existing items in the list box
        foreach ($file in $OpenFileDialog.FileNames) {
            $FileListBox.Items.Add($file)  # Add each selected file path to the list box
        }
    }
})

# Bulk Rename button logic for opening Bulk Renaming window
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
})

# Redo button logic
$RedoButton.Add_Click({
    if ($redoStack.Count -gt 0) {
        $operationToRedo = $redoStack[-1]
        $redoStack = $redoStack[0..($redoStack.Count - 2)]

        # Perform the redo operation
        Perform-RedoOperation -operation $operationToRedo

        # Add the operation back to the undo stack
        $undoStack += ,$operationToRedo
    } else {
        [System.Windows.Forms.MessageBox]::Show("No actions to redo.", "Redo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

# Preview button logic
$PreviewButton.Add_Click({
    $MainPageWindow.Hide()
    $BulkRenamingWindow.Show()

    $FileListBox.Items.Add("Old Path: $filePath -> New Path: $newFilePath")
})

# Show the Main Page window
$MainPageWindow.ShowDialog() | Out-Null

#------------------PREFIX AND SUFFIX TOOL---------------------#

# Create the Prefix-Suffix window
$PrefixSuffixWindow = New-Object Windows.Window
$PrefixSuffixWindow.Title = "SHIFTIFY: Prefix and Suffix Tool"
$PrefixSuffixWindow.Height = 500
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
$CenterStackPanel = New-Object Windows.Controls.StackPanel
$CenterStackPanel.HorizontalAlignment = "Center"
$CenterStackPanel.VerticalAlignment = "Top"
$CenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

# File selection button
$SelectFileButton = Create-Button -Content "Select File" -Width 150 -Height 40
$CenterStackPanel.Children.Add($SelectFileButton)

# File list box
$FileListBox = New-Object Windows.Controls.ListBox
$FileListBox.Width = 300
$FileListBox.Height = 100
$FileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
$FileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$FileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$FileListBox.BorderThickness = [Windows.Thickness]::new(2)
$CenterStackPanel.Children.Add($FileListBox)

# Text box for prefix
$PrefixLabel = New-Object Windows.Controls.TextBlock
$PrefixLabel.Text = "Enter Prefix: "
$PrefixLabel.FontSize = 14
$PrefixLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$PrefixLabel.HorizontalAlignment = "Center"
$CenterStackPanel.Children.Add($PrefixLabel)

$PrefixTextBox = New-Object Windows.Controls.TextBox
$PrefixTextBox.Width = 200
$PrefixTextBox.FontSize = 14
$PrefixTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$PrefixTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$PrefixTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$CenterStackPanel.Children.Add($PrefixTextBox)

# Text box for suffix
$SuffixLabel = New-Object Windows.Controls.TextBlock
$SuffixLabel.Text = "Enter Suffix: "
$SuffixLabel.FontSize = 14
$SuffixLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$SuffixLabel.HorizontalAlignment = "Center"
$CenterStackPanel.Children.Add($SuffixLabel)

$SuffixTextBox = New-Object Windows.Controls.TextBox
$SuffixTextBox.Width = 200
$SuffixTextBox.FontSize = 14
$SuffixTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$SuffixTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$SuffixTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$CenterStackPanel.Children.Add($SuffixTextBox)

# Buttons for Preview, Rename, Undo, Redo, and Back
$ButtonGrid = New-Object Windows.Controls.Grid
$ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

for ($row = 0; $row -lt 3; $row++) {
    $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
}
for ($col = 0; $col -lt 2; $col++) {
    $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
}

$PreviewButton = Create-Button -Content "Preview" -Width 80
$PreviewButton.SetValue([Windows.Controls.Grid]::RowProperty, 0)
$PreviewButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)
$ButtonGrid.Children.Add($PreviewButton)

$RenameButton = Create-Button -Content "Rename" -Width 80
$RenameButton.SetValue([Windows.Controls.Grid]::RowProperty, 0)
$RenameButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)
$ButtonGrid.Children.Add($RenameButton)

$UndoButton = Create-Button -Content "Undo" -Width 80
$UndoButton.SetValue([Windows.Controls.Grid]::RowProperty, 1)
$UndoButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)
$ButtonGrid.Children.Add($UndoButton)

$RedoButton = Create-Button -Content "Redo" -Width 80
$RedoButton.SetValue([Windows.Controls.Grid]::RowProperty, 1)
$RedoButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)
$ButtonGrid.Children.Add($RedoButton)

$BackButton = Create-Button -Content "Back" -Width 80
$BackButton.SetValue([Windows.Controls.Grid]::RowProperty, 1)
$BackButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 2)

$BackButton.HorizontalAlignment = "Center"
$ButtonGrid.Children.Add($BackButton)

$CenterStackPanel.Children.Add($ButtonGrid)
$PrefixSuffixGrid.Children.Add($CenterStackPanel)

# Set Grid as content
$PrefixSuffixWindow.Content = $PrefixSuffixGrid

# File Selection Logic
$SelectFileButton.Add_Click({
    $OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $OpenFileDialog.Multiselect = $true
    $OpenFileDialog.Title = "Select Files"

    if ($OpenFileDialog.ShowDialog()) {
        $FileListBox.Items.Clear()
        foreach ($file in $OpenFileDialog.FileNames) {
            $FileListBox.Items.Add($file)
        }
    }
})

# Back Button Logic
$BackButton.Add_Click({
    $PrefixSuffixWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

# Show Prefix-Suffix Window (for standalone testing)
$PrefixSuffixWindow.ShowDialog() | Out-Null


#------------------ REPLACE WINDOW ---------------------#

# Create the Replace window
$ReplaceWindow = New-Object Windows.Window
$ReplaceWindow.Title = "SHIFTIFY: Text Substitution Tool"
$ReplaceWindow.Height = 500
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
$CenterStackPanel = New-Object Windows.Controls.StackPanel
$CenterStackPanel.HorizontalAlignment = "Center"
$CenterStackPanel.VerticalAlignment = "Top"
$CenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

# File selection button
$SelectFileButton = Create-Button -Content "Select File" -Width 150 -Height 40
$CenterStackPanel.Children.Add($SelectFileButton)

# File list box
$FileListBox = New-Object Windows.Controls.ListBox
$FileListBox.Width = 300
$FileListBox.Height = 100
$FileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
$FileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$FileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$FileListBox.BorderThickness = [Windows.Thickness]::new(2)
$CenterStackPanel.Children.Add($FileListBox)

# Text box for "Find"
$FindLabel = New-Object Windows.Controls.TextBlock
$FindLabel.Text = "Find:"
$FindLabel.FontSize = 14
$FindLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$FindLabel.HorizontalAlignment = "Center"
$CenterStackPanel.Children.Add($FindLabel)

$FindTextBox = New-Object Windows.Controls.TextBox
$FindTextBox.Width = 200
$FindTextBox.FontSize = 14
$FindTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$FindTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$FindTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$CenterStackPanel.Children.Add($FindTextBox)

# Text box for "Substitute With"
$SubstituteWithLabel = New-Object Windows.Controls.TextBlock
$SubstituteWithLabel.Text = "Substitute With:"
$SubstituteWithLabel.FontSize = 14
$SubstituteWithLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$SubstituteWithLabel.HorizontalAlignment = "Center"
$CenterStackPanel.Children.Add($SubstituteWithLabel)

$SubstituteWithTextBox = New-Object Windows.Controls.TextBox
$SubstituteWithTextBox.Width = 200
$SubstituteWithTextBox.FontSize = 14
$SubstituteWithTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$SubstituteWithTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$SubstituteWithTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$CenterStackPanel.Children.Add($SubstituteWithTextBox)

# Buttons for Apply, Replace, and Back
$ButtonGrid = New-Object Windows.Controls.Grid
$ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

for ($row = 0; $row -lt 1; $row++) {
    $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
}
for ($col = 0; $col -lt 3; $col++) {
    $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
}

$ApplyButton = Create-Button -Content "Apply" -Width 100
$ApplyButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)
$ButtonGrid.Children.Add($ApplyButton)

$ReplaceButton = Create-Button -Content "Substitute" -Width 100
$ReplaceButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)
$ButtonGrid.Children.Add($ReplaceButton)

$BackButton = Create-Button -Content "Back" -Width 100
$BackButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 3)
$ButtonGrid.Children.Add($BackButton)


$CenterStackPanel.Children.Add($ButtonGrid)
$ReplaceGrid.Children.Add($CenterStackPanel)

# Set Grid as content
$ReplaceWindow.Content = $ReplaceGrid

# File Selection Logic
$SelectFileButton.Add_Click({
    $OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $OpenFileDialog.Multiselect = $true
    $OpenFileDialog.Title = "Select Files"

    if ($OpenFileDialog.ShowDialog()) {
        $FileListBox.Items.Clear()
        foreach ($file in $OpenFileDialog.FileNames) {
            $FileListBox.Items.Add($file)
        }
    }
})

# Back button logic for Replace page
$BackButton.Add_Click({
    $ReplaceWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

# Show Replace Window (for standalone testing)
$ReplaceWindow.ShowDialog() | Out-Null  

#------------------ENCRYPTION AND DECRYPTION---------------------#

# Create the Encryption window
$EncryptionWindow = New-Object Windows.Window
$EncryptionWindow.Title = "SHIFTIFY: Text Substitution Tool"
$EncryptionWindow.Height = 500
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
$CenterStackPanel = New-Object Windows.Controls.StackPanel
$CenterStackPanel.HorizontalAlignment = "Center"
$CenterStackPanel.VerticalAlignment = "Top"
$CenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

# File selection button
$SelectFileButton = Create-Button -Content "Select File" -Width 150 -Height 40
$CenterStackPanel.Children.Add($SelectFileButton)

# File list box
$FileListBox = New-Object Windows.Controls.ListBox
$FileListBox.Width = 300
$FileListBox.Height = 100
$FileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
$FileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$FileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$FileListBox.BorderThickness = [Windows.Thickness]::new(2)
$CenterStackPanel.Children.Add($FileListBox)

# Text box for "Enter secret key"
$FindLabel = New-Object Windows.Controls.TextBlock
$FindLabel.Text = "Enter secret key: "
$FindLabel.FontSize = 14
$FindLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$FindLabel.HorizontalAlignment = "Center"
$CenterStackPanel.Children.Add($FindLabel)

$FindTextBox = New-Object Windows.Controls.TextBox
$FindTextBox.Width = 200
$FindTextBox.FontSize = 14
$FindTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$FindTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$FindTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$CenterStackPanel.Children.Add($FindTextBox)

# Buttons for Apply, Encrypt, and Back
$ButtonGrid = New-Object Windows.Controls.Grid
$ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

for ($row = 0; $row -lt 1; $row++) {
    $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
}
for ($col = 0; $col -lt 3; $col++) {
    $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
}

$ApplyButton = Create-Button -Content "Apply" -Width 100
$ApplyButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)
$ButtonGrid.Children.Add($ApplyButton)

$EncryptButton = Create-Button -Content "Substitute" -Width 100
$EncryptButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)
$ButtonGrid.Children.Add($EncryptButton)

$BackButton = Create-Button -Content "Back" -Width 100
$BackButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 3)
$ButtonGrid.Children.Add($BackButton)

$CenterStackPanel.Children.Add($ButtonGrid)
$EncryptionGrid.Children.Add($CenterStackPanel)

# Set Grid as content
$EncryptionWindow.Content = $EncryptionGrid

# File Selection Logic
$SelectFileButton.Add_Click({
    $OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $OpenFileDialog.Multiselect = $true
    $OpenFileDialog.Title = "Select Files"

    if ($OpenFileDialog.ShowDialog()) {
        $FileListBox.Items.Clear()
        foreach ($file in $OpenFileDialog.FileNames) {
            $FileListBox.Items.Add($file)
        }
    }
})

# Back Button Logic
$BackButton.Add_Click({
    if ($null -eq $MainPageWindow) {
        # Handle the null case if $MainPageWindow is not initialized
        [System.Windows.MessageBox]::Show("Main Page is not available.", "Error", "OK", "Error")
    } else {
        $EncryptionWindow.Hide() # Adjusted to the updated variable name
        $MainPageWindow.ShowDialog() | Out-Null
    }
})

# Back button logic for Encryption page
$BackButton.Add_Click({
    $EncryptionWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

# Show Encryption Window (for standalone testing)
$EncryptionWindow.ShowDialog() | Out-Null 