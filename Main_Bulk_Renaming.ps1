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
$MainPageWindow.Height = 350
$MainPageWindow.Width = 400
$MainPageWindow.WindowStartupLocation = "CenterScreen"
$MainPageWindow.FontFamily = "Segoe UI"
$MainPageWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD") # Color - Baby blue bg

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
$TitleBorder.Background = (ConvertTo-SolidColorBrush "#90CAF9") # Color - Lighter baby blue
$TitleBorder.CornerRadius = [Windows.CornerRadius]::new(20) # Slight rounding for the title
$TitleBorder.BorderBrush = (ConvertTo-SolidColorBrush "#4682B4") # Steel blue border for the title outline
$TitleBorder.BorderThickness = [Windows.Thickness]::new(3)      # Outline thickness for title

$TitleTextBlock = New-Object Windows.Controls.TextBlock
$TitleTextBlock.Text = "SHIFTIFY"
$TitleTextBlock.FontSize = 28
$TitleTextBlock.FontWeight = "Bold"
$TitleTextBlock.HorizontalAlignment = "Center"
$TitleTextBlock.VerticalAlignment = "Center"
$TitleTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1") # Navy blue text

$TitleBorder.Child = $TitleTextBlock
$MainGrid.Children.Add($TitleBorder)

# Add subtitle below the title
$SubTextBlock = New-Object Windows.Controls.TextBlock
$SubTextBlock.Text = "Rename. Replace. Encrypt."
$SubTextBlock.HorizontalAlignment = "Center"
$SubTextBlock.VerticalAlignment = "Top"
$SubTextBlock.FontSize = 16
$SubTextBlock.FontStyle = "Italic"
$SubTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1") # Navy blue text
$SubTextBlock.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

$MainGrid.Children.Add($SubTextBlock)

# Function to create buttons with rounded corners
function Create-Button {
    param ($Content, $TopMargin)

    $Button = New-Object Windows.Controls.Button
    $Button.Content = $Content
    $Button.Width = 200
    $Button.Height = 40
    $Button.HorizontalAlignment = "Center"
    $Button.VerticalAlignment = "Top"
    $Button.Margin = [Windows.Thickness]::new(0, $TopMargin, 0, 0)
    $Button.FontSize = 14
    $Button.FontWeight = "Bold"
    $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9") # Color - Baby blue
    $Button.Foreground = (ConvertTo-SolidColorBrush "#0D47A1") # Color - Navy blue text
    $Button.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1") # Color - Navy blue border
    $Button.BorderThickness = [Windows.Thickness]::new(2)
    $Button.Padding = [Windows.Thickness]::new(5)

    # Add hover effects
    $Button.MouseEnter.Add({
        $Button.Background = (ConvertTo-SolidColorBrush "#64B5F6") # Color - Darker baby blue
    })
    $Button.MouseLeave.Add({
        $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9") # Color - Original baby blue
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
$BulkRenamingWindow.Height = 400
$BulkRenamingWindow.Width = 500
$BulkRenamingWindow.WindowStartupLocation = "CenterScreen"
$BulkRenamingWindow.FontFamily = "Segoe UI"
$BulkRenamingWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD") # Color - Baby blue bg

$BulkRenamingWindow.ResizeMode = "NoResize"
$BulkRenamingWindow.WindowStyle = "SingleBorderWindow"

# Create a Grid for Bulk Renaming Page
$BulkGrid = New-Object Windows.Controls.Grid

# Title for Bulk Renaming Page
$BulkTitleBorder = New-Object Windows.Controls.Border
$BulkTitleBorder.Width = 450
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

# File selection area
$FileSelectionStackPanel = New-Object Windows.Controls.StackPanel
$FileSelectionStackPanel.Orientation = "Vertical"
$FileSelectionStackPanel.HorizontalAlignment = "Center"
$FileSelectionStackPanel.VerticalAlignment = "Top"
$FileSelectionStackPanel.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

$SelectFilesButton = Create-Button -Content "Select Files" -TopMargin 0
$SelectFilesButton.Width = 100
$SelectFilesButton.Height = 40
$FileSelectionStackPanel.Children.Add($SelectFilesButton)

$FileListBox = New-Object Windows.Controls.ListBox
$FileListBox.Width = 300
$FileListBox.Height = 100
$FileListBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
$FileListBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
$FileListBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
$FileListBox.BorderThickness = [Windows.Thickness]::new(2)
$FileSelectionStackPanel.Children.Add($FileListBox)

$BulkGrid.Children.Add($FileSelectionStackPanel)

# Buttons for Bulk Renaming actions
$ActionsGrid = New-Object Windows.Controls.Grid
$ActionsGrid.HorizontalAlignment = "Center"
$ActionsGrid.VerticalAlignment = "Bottom"
$ActionsGrid.Margin = [Windows.Thickness]::new(0, 0, 0, 30)

# Define 3x3 layout (di dikit-dikit)
for ($row = 0; $row -lt 3; $row++) {
    $RowDefinition = New-Object Windows.Controls.RowDefinition
    $ActionsGrid.RowDefinitions.Add($RowDefinition)
}
for ($col = 0; $col -lt 3; $col++) {
    $ColDefinition = New-Object Windows.Controls.ColumnDefinition
    $ActionsGrid.ColumnDefinitions.Add($ColDefinition)
}

function Create-SmallButton {
    param ($Content, $Row, $Column)

    $Button = New-Object Windows.Controls.Button
    $Button.Content = $Content
    $Button.Width = 70
    $Button.Height = 25
    $Button.FontSize = 12
    $Button.FontWeight = "Bold"
    $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $Button.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $Button.BorderThickness = [Windows.Thickness]::new(2)
    $Button.Margin = [Windows.Thickness]::new(5)

    [Windows.Controls.Grid]::SetRow($Button, $Row)
    [Windows.Controls.Grid]::SetColumn($Button, $Column)

    return $Button
}

$PreviewButton = Create-SmallButton -Content "Preview" -Row 0 -Column 0
$RenameButton = Create-SmallButton -Content "Rename" -Row 0 -Column 1
$UndoButton = Create-SmallButton -Content "Undo" -Row 0 -Column 2
$AddPrefixButton = Create-SmallButton -Content "Add Prefix" -Row 1 -Column 0
$AddSuffixButton = Create-SmallButton -Content "Add Suffix" -Row 1 -Column 1
$BackButton = Create-SmallButton -Content "Back" -Row 1 -Column 2

$ActionsGrid.Children.Add($PreviewButton)
$ActionsGrid.Children.Add($RenameButton)
$ActionsGrid.Children.Add($UndoButton)
$ActionsGrid.Children.Add($AddPrefixButton)
$ActionsGrid.Children.Add($AddSuffixButton)
$ActionsGrid.Children.Add($BackButton)

$BulkGrid.Children.Add($ActionsGrid)

# Assign Bulk Grid to Bulk Renaming window content
$BulkRenamingWindow.Content = $BulkGrid

# Placeholder for button actions
$SelectFilesButton.Add_Click({
    $FileDialog = New-Object Microsoft.Win32.OpenFileDialog
    $FileDialog.Multiselect = $true
    if ($FileDialog.ShowDialog()) {
        $FileListBox.Items.Clear()
        foreach ($file in $FileDialog.FileNames) {
            $FileListBox.Items.Add($file)
        }
    }
})

$BackButton.Add_Click({
    $BulkRenamingWindow.Hide()
    $MainPageWindow.ShowDialog() | Out-Null
})

$BulkRenameButton.Add_Click({
    $MainPageWindow.Hide()
    $BulkRenamingWindow.ShowDialog() | Out-Null
})

# Show the main page window
$MainPageWindow.ShowDialog() | Out-Null
