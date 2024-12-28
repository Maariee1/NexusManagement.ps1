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

# Show the main window
$MainPageWindow.ShowDialog() | Out-Null
