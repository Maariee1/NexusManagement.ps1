# Load necessary components for WPF application
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

# Function to convert a hex color to a SolidColorBrush
function ConvertTo-SolidColorBrush {
    param ($hexColor)
    $colorConverter = [System.Windows.Media.ColorConverter]::new()
    $color = $colorConverter.ConvertFromString($hexColor)
    return New-Object System.Windows.Media.SolidColorBrush $color
}

# Create the main window for Main Page
$MainPageWindow = New-Object Windows.Window
$MainPageWindow.Title = "SHIFTIFY: Main Page"
$MainPageWindow.Height = 500
$MainPageWindow.Width = 400
$MainPageWindow.WindowStartupLocation = "CenterScreen"
$MainPageWindow.FontFamily = "Segoe UI"
$MainPageWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD") # Baby blue bg

# Default size of window
$MainPageWindow.ResizeMode = "NoResize"
$MainPageWindow.WindowStyle = "SingleBorderWindow"

# Create a Grid for Main Page
$MainGrid = New-Object Windows.Controls.Grid

# Add rounded title "SHIFTIFY"
$TitleBorder = New-Object Windows.Controls.Border
$TitleBorder.Width = 350
$TitleBorder.Height = 60
$TitleBorder.HorizontalAlignment = "Center"
$TitleBorder.VerticalAlignment = "Top"
$TitleBorder.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
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

# Add subtitle below the title
$SubTextBlock = New-Object Windows.Controls.TextBlock
$SubTextBlock.Text = "Rename. Replace. Encrypt."
$SubTextBlock.HorizontalAlignment = "Center"
$SubTextBlock.VerticalAlignment = "Top"
$SubTextBlock.FontSize = 16
$SubTextBlock.FontStyle = "Italic"
$SubTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
$SubTextBlock.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

$MainGrid.Children.Add($SubTextBlock)

# Function to create buttons with rounded corners
function Create-Button {
    param ($Content, $TopMargin)

    # Initialize the button
    $Button = New-Object Windows.Controls.Button
    $Button.Content = $Content
    $Button.Width = 200
    $Button.Height = 40
    $Button.HorizontalAlignment = "Center"
    $Button.VerticalAlignment = "Top"
    $Button.Margin = [Windows.Thickness]::new(0, $TopMargin, 0, 0)
    $Button.FontSize = 14
    $Button.FontWeight = "Bold"
    $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $Button.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.BorderThickness = [Windows.Thickness]::new(2)

    # Add hover effects **after** the button is fully initialized
    $Button.Add_MouseEnter({
        $Button.Background = (ConvertTo-SolidColorBrush "#64B5F6")
    })
    $Button.Add_MouseLeave({
        $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    })

    return $Button
}

# Create Buttons for Main Page
$BulkRenameButton = Create-Button -Content "Bulk Renaming" -TopMargin 140
$ReplacingButton = Create-Button -Content "Replacing" -TopMargin 190
$EncryptionButton = Create-Button -Content "Encryption" -TopMargin 240

# Add buttons to Main Grid
$MainGrid.Children.Add($BulkRenameButton)
$MainGrid.Children.Add($ReplacingButton)
$MainGrid.Children.Add($EncryptionButton)

# Assign Main Grid to the Main Page window content
$MainPageWindow.Content = $MainGrid

# Create the Bulk Renaming window
$BulkRenamingWindow = New-Object Windows.Window
$BulkRenamingWindow.Title = "SHIFTIFY: Bulk Renaming"
$BulkRenamingWindow.Height = 500
$BulkRenamingWindow.Width = 400
$BulkRenamingWindow.WindowStartupLocation = "CenterScreen"
$BulkRenamingWindow.FontFamily = "Segoe UI"
$BulkRenamingWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")

$BulkRenamingWindow.ResizeMode = "NoResize"
$BulkRenamingWindow.WindowStyle = "SingleBorderWindow"

# Create a Grid for Bulk Renaming Page
$BulkGrid = New-Object Windows.Controls.Grid

# Title for Bulk Renaming Page
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
$SelectFilesButton = Create-Button -Content "Select Files" -TopMargin 0
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

# Buttons for Preview, Rename, Undo, Back
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
$BackButton = Create-SmallButton -Content "Back" -Row 1 -Column 1

$ButtonGrid.Children.Add($PreviewButton)
$ButtonGrid.Children.Add($RenameButton)
$ButtonGrid.Children.Add($UndoButton)
$ButtonGrid.Children.Add($BackButton)

$CenterStackPanel.Children.Add($ButtonGrid)

$BulkGrid.Children.Add($CenterStackPanel)

$BulkRenamingWindow.Content = $BulkGrid

# File Selection Button Logic
$SelectFilesButton.Add_Click({
    # Open file dialog
    $OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $OpenFileDialog.Multiselect = $true
    $OpenFileDialog.Title = "Select Files"
    
    # Show the dialog and handle file selection
    if ($OpenFileDialog.ShowDialog()) {
        # Clear previous entries in the ListBox
        $FileListBox.Items.Clear()

        # Add selected file names to the ListBox
        foreach ($file in $OpenFileDialog.FileNames) {
            $FileListBox.Items.Add($file)
        }
    }
})

# Back button logic for Bulk Renaming page
$BackButton.Add_Click({
    $BulkRenamingWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

# Bulk Rename button logic for opening Bulk Renaming window
$BulkRenameButton.Add_Click({
    $MainPageWindow.Hide()
    $BulkRenamingWindow.ShowDialog() | Out-Null
})

# Create the Replace window
$ReplaceWindow = New-Object Windows.Window
$ReplaceWindow.Title = "SHIFTIFY: Replace"
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
$ReplaceTitleTextBlock.Text = "Replace"
$ReplaceTitleTextBlock.FontSize = 24
$ReplaceTitleTextBlock.FontWeight = "Bold"
$ReplaceTitleTextBlock.HorizontalAlignment = "Center"
$ReplaceTitleTextBlock.VerticalAlignment = "Center"
$ReplaceTitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")

$ReplaceTitleBorder.Child = $ReplaceTitleTextBlock
$ReplaceGrid.Children.Add($ReplaceTitleBorder)

# Center panel for Replace actions
$ReplaceCenterStackPanel = New-Object Windows.Controls.StackPanel
$ReplaceCenterStackPanel.HorizontalAlignment = "Center"
$ReplaceCenterStackPanel.VerticalAlignment = "Top"
$ReplaceCenterStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

# File selection button
$ReplaceSelectFilesButton = Create-Button -Content "Select File" -TopMargin 0
$ReplaceSelectFilesButton.Width = 150
$ReplaceSelectFilesButton.Height = 40
$ReplaceCenterStackPanel.Children.Add($ReplaceSelectFilesButton)

# Add logic to the Replace Select File button
$ReplaceSelectFilesButton.Add_Click({
    # Open file dialog for single file selection
    $OpenFileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $OpenFileDialog.Title = "Select a File"
    
    # Show the dialog and handle file selection
    if ($OpenFileDialog.ShowDialog()) {
        # Display the selected file in a TextBlock or ListBox
        $FileListBox.Items.Clear() # Ensure the list is cleared first
        $FileListBox.Items.Add($OpenFileDialog.FileName) # Add selected file
    }
})

# Text box for "Replace" and "With"
$ReplaceLabel = New-Object Windows.Controls.TextBlock
$ReplaceLabel.Text = "Replace:"
$ReplaceLabel.FontSize = 14
$ReplaceLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$ReplaceLabel.HorizontalAlignment = "Center"
$ReplaceCenterStackPanel.Children.Add($ReplaceLabel)

$ReplaceTextBox = New-Object Windows.Controls.TextBox
$ReplaceTextBox.Width = 200
$ReplaceTextBox.FontSize = 14
$ReplaceTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$ReplaceTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$ReplaceTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$ReplaceCenterStackPanel.Children.Add($ReplaceTextBox)

$WithLabel = New-Object Windows.Controls.TextBlock
$WithLabel.Text = "With:"
$WithLabel.FontSize = 14
$WithLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
$WithLabel.HorizontalAlignment = "Center"
$ReplaceCenterStackPanel.Children.Add($WithLabel)

$WithTextBox = New-Object Windows.Controls.TextBox
$WithTextBox.Width = 200
$WithTextBox.FontSize = 14
$WithTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$WithTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$WithTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
$ReplaceCenterStackPanel.Children.Add($WithTextBox)

# Preview display box
$ReplacePreviewListBox = New-Object Windows.Controls.ListBox
$ReplacePreviewListBox.Width = 300
$ReplacePreviewListBox.Height = 100
$ReplacePreviewListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
$ReplacePreviewListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$ReplacePreviewListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$ReplacePreviewListBox.BorderThickness = [Windows.Thickness]::new(2)
$ReplaceCenterStackPanel.Children.Add($ReplacePreviewListBox)

$ReplaceApplyButton.Add_Click({
    if (-not $FileListBox.SelectedItem) {
        [System.Windows.MessageBox]::Show("Please select a file.", "Error")
        return
    }
    if (-not $ReplaceTextBox.Text -or -not $WithTextBox.Text) {
        [System.Windows.MessageBox]::Show("Please fill in both 'Replace' and 'With' fields.", "Error")
        return
    }

    # Get the file path and the replace/with strings
    $SelectedFilePath = $FileListBox.SelectedItem
    $SelectedFileName = [System.IO.Path]::GetFileName($SelectedFilePath)
    $ReplaceString = $ReplaceTextBox.Text
    $WithString = $WithTextBox.Text

    # Perform the replacement in the file name
    if ($SelectedFileName -match [Regex]::Escape($ReplaceString)) {
        $UpdatedFileName = $SelectedFileName -replace [Regex]::Escape($ReplaceString), $WithString
        $NewFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($SelectedFilePath), $UpdatedFileName)

        try {
            # Rename the file
            Rename-Item -Path $SelectedFilePath -NewName $NewFilePath
            [System.Windows.MessageBox]::Show("File renamed successfully!", "Success")
        } catch {
            [System.Windows.MessageBox]::Show("Error renaming file: $_", "Error")
        }
    } else {
        [System.Windows.MessageBox]::Show("No match found for replacement.", "Error")
    }
})

# Buttons for Preview, Replace, Back
$ReplaceButtonGrid = New-Object Windows.Controls.Grid
$ReplaceButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

for ($row = 0; $row -lt 1; $row++) {
    $ReplaceButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
}
for ($col = 0; $col -lt 3; $col++) {
    $ReplaceButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
}

$ReplacePreviewButton = Create-SmallButton -Content "Preview" -Row 0 -Column 0
$ReplaceApplyButton = Create-SmallButton -Content "Replace" -Row 0 -Column 1
$ReplaceBackButton = Create-SmallButton -Content "Back" -Row 0 -Column 2

$ReplaceButtonGrid.Children.Add($ReplacePreviewButton)
$ReplaceButtonGrid.Children.Add($ReplaceApplyButton)
$ReplaceButtonGrid.Children.Add($ReplaceBackButton)

$ReplaceCenterStackPanel.Children.Add($ReplaceButtonGrid)

$ReplaceGrid.Children.Add($ReplaceCenterStackPanel)

$ReplaceWindow.Content = $ReplaceGrid

# Replace Back button logic
$ReplaceBackButton.Add_Click({
    $ReplaceWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

# Replace button logic for opening Replace window
$ReplacingButton.Add_Click({
    $MainPageWindow.Hide()
    $ReplaceWindow.ShowDialog() | Out-Null
})

# Show the main window
$MainPageWindow.ShowDialog() | Out-Null

