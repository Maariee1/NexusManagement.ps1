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

# Create the main window
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

# Create a Grid
$Grid = New-Object Windows.Controls.Grid

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
$Grid.Children.Add($TitleBorder)

# Add subtitle below the title
$SubTextBlock = New-Object Windows.Controls.TextBlock
$SubTextBlock.Text = "Rename. Replace. Encrypt."
$SubTextBlock.HorizontalAlignment = "Center"
$SubTextBlock.VerticalAlignment = "Top"
$SubTextBlock.FontSize = 16
$SubTextBlock.FontStyle = "Italic"
$SubTextBlock.Foreground = (ConvertTo-SolidColorBrush "#0D47A1") # Navy blue text
$SubTextBlock.Margin = [Windows.Thickness]::new(0, 100, 0, 0)

$Grid.Children.Add($SubTextBlock)

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
    $Button.Style = $null # Ensures no template overrides default style

    # Set rounded corners on the button using BorderBrush and CornerRadius
    $Button.Template = [Windows.ControlTemplate]::new()
    $Button.Template.VisualTree = {
        $ButtonBorder = New-Object Windows.Controls.Border
        $ButtonBorder.Background = $Button.Background
        $ButtonBorder.BorderBrush = $Button.BorderBrush
        $ButtonBorder.BorderThickness = $Button.BorderThickness
        $ButtonBorder.CornerRadius = [Windows.CornerRadius]::new(12)  # Apply rounded corners
        $ButtonBorder.Child = $Button.Content

        return $ButtonBorder
    }

    # Add hover effects
    $Button.MouseEnter.Add({
        $Button.Background = (ConvertTo-SolidColorBrush "#64B5F6") # Color - Darker baby blue
    })
    $Button.MouseLeave.Add({
        $Button.Background = (ConvertTo-SolidColorBrush "#90CAF9") # Color - Original baby blue
    })

    return $Button
}

# Create Buttons 
$BulkRenameButton = Create-Button -Content "Bulk Renaming" -TopMargin 140
$ReplacingButton = Create-Button -Content "Replacing" -TopMargin 190
$EncryptionButton = Create-Button -Content "Encryption" -TopMargin 240

# Add buttons to Grid
$Grid.Children.Add($BulkRenameButton)
$Grid.Children.Add($ReplacingButton)
$Grid.Children.Add($EncryptionButton)

# Assign Grid to the main window content
$MainPageWindow.Content = $Grid

# Placeholder for future pages
function Show-BulkRenamingPage {
    [System.Windows.MessageBox]::Show("Bulk Renaming Page - To process hehe!", "SHIFTIFY")
}

function Show-ReplacingPage {
    [System.Windows.MessageBox]::Show("Replacing Page - To process hehe!", "SHIFTIFY")
}

function Show-EncryptionPage {
    [System.Windows.MessageBox]::Show("Encryption Page - To process hehe!", "SHIFTIFY")
}

# Add event handlers
$BulkRenameButton.Add_Click({ Show-BulkRenamingPage })
$ReplacingButton.Add_Click({ Show-ReplacingPage })
$EncryptionButton.Add_Click({ Show-EncryptionPage })

# Show the main page window
$MainPageWindow.ShowDialog() | Out-Null
