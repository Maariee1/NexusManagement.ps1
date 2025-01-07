
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
    param ($Content, $TopMargin, $Width = 250, $Height = 55)
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

    # Define a ControlTemplate with rounded corners
    $template = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $borderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    
    # Set corner radius
    $borderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(15))  # Rounded corners with radius 15
    
    # Set background and border
    $borderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $Button.Background)
    $borderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $Button.BorderBrush)
    $borderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $Button.BorderThickness)

    # ContentPresenter to display button content
    $contentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $contentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $contentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)
    
    # Add the ContentPresenter to the border
    $borderFactory.AppendChild($contentPresenterFactory)

    # Set the template's visual tree to the border
    $template.VisualTree = $borderFactory
    
    # Apply the template to the button
    $Button.Template = $template

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
    $BulkRenamingWindow.Height = 600
    $BulkRenamingWindow.Width = 500
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
    $SelectFilesButton.Margin = [Windows.Thickness]::new(0, 10, 0, 10)

    # Set the Button's Base Style (background, font, etc.)
    $SelectFilesButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $SelectFilesButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $SelectFilesButton.FontSize = 14
    $SelectFilesButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $SelectFilesButton.FontWeight = "Bold"

    # Define a ControlTemplate for rounded corners
    $selectFilesTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $selectFilesBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])

    # Set the corner radius for rounded corners
    $selectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10

    # Set the background and border for the button
    $selectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $SelectFilesButton.Background)
    $selectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $SelectFilesButton.BorderBrush)
    $selectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $SelectFilesButton.BorderThickness)

    # ContentPresenter to display button content
    $selectFilesContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $selectFilesContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $selectFilesContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $selectFilesBorderFactory.AppendChild($selectFilesContentPresenterFactory)

    # Set the visual tree of the button to the border
    $selectFilesTemplate.VisualTree = $selectFilesBorderFactory

    # Apply the ControlTemplate to the button
    $SelectFilesButton.Template = $selectFilesTemplate

    # Add hover effect for the button (change background color on hover)
    $SelectFilesButton.Add_MouseEnter({
        $SelectFilesButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Change to lighter blue on hover
    })
    $SelectFilesButton.Add_MouseLeave({
        $SelectFilesButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Return to original color when mouse leaves
    })

    # Add the button to the stack panel
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
    $BaseNameLabel.FontWeight = "Bold"
    $BaseNameLabel.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $BaseNameLabel.VerticalAlignment = "Center"
    $BaseNamePanel.Children.Add($BaseNameLabel)

    # Basename Text Box
    $BaseNameTextBox = New-Object Windows.Controls.TextBox
    $BaseNameTextBox.Width = 170
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
    
    # Buttons for Apply, Back

    # Initialize ButtonGrid for layout
    for ($row = 0; $row -lt 2; $row++) {
        $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    # Apply Button (Apply)
    $RenameButton = New-Object Windows.Controls.Button
    $RenameButton.Content = "Apply"
    $RenameButton.Width = 130
    $RenameButton.Height = 35
    $RenameButton.Margin = [Windows.Thickness]::new(0, 1, 0, 0)
    $RenameButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $RenameButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $RenameButton.FontSize = 14
    $RenameButton.FontWeight = "Bold"
    $RenameButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $RenameButton.BorderThickness = [Windows.Thickness]::new(1)

    # Define rounded corners for Apply button
    $RenameButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $RenameButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $RenameButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $RenameButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $RenameButton.Background)
    $RenameButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $RenameButton.BorderBrush)
    $RenameButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $RenameButton.BorderThickness)

    # ContentPresenter to display button content
    $RenameButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $RenameButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $RenameButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $RenameButtonBorderFactory.AppendChild($RenameButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $RenameButtonTemplate.VisualTree = $RenameButtonBorderFactory

    # Apply the ControlTemplate to the Apply button
    $RenameButton.Template = $RenameButtonTemplate

    # Hover effect for Apply button
    $RenameButton.Add_MouseEnter({
        $RenameButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Lighter blue on hover
    })
    $RenameButton.Add_MouseLeave({
        $RenameButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Original color
    })

    # Set position in ButtonGrid
    [Windows.Controls.Grid]::SetRow($RenameButton, 0)
    [Windows.Controls.Grid]::SetColumn($RenameButton, 0)
    $ButtonGrid.Children.Add($RenameButton)

    # Back Button (Bulk Renaming)
    $BackButton = New-Object Windows.Controls.Button
    $BackButton.Content = "Back"
    $BackButton.Width = 130
    $BackButton.Height = 35
    $BackButton.Margin = [Windows.Thickness]::new(0, 1, 0, 0)
    $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Darker Blue
    $BackButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")  # White Text
    $BackButton.FontSize = 14
    $BackButton.FontWeight = "Bold"
    $BackButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $BackButton.BorderThickness = [Windows.Thickness]::new(1)
    $BackButton.HorizontalAlignment = "Center"

    # Define rounded corners for Back button
    $BackButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $BackButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $BackButton.Background)
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $BackButton.BorderBrush)
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $BackButton.BorderThickness)

    # ContentPresenter to display button content
    $BackButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $BackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $BackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $BackButtonBorderFactory.AppendChild($BackButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $BackButtonTemplate.VisualTree = $BackButtonBorderFactory

    # Apply the ControlTemplate to the Back button
    $BackButton.Template = $BackButtonTemplate

    # Hover effect for Back button
    $BackButton.Add_MouseEnter({
        $BackButton.Background = (ConvertTo-SolidColorBrush "#0D47A1")  # Darker shade on hover
    })
    $BackButton.Add_MouseLeave({
        $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Original color
    })

    # Set position in ButtonGrid
    [Windows.Controls.Grid]::SetRow($BackButton, 0)
    [Windows.Controls.Grid]::SetColumn($BackButton, 1)
    $ButtonGrid.Children.Add($BackButton)

    # Add the ButtonGrid to the main StackPanel
    $CenterStackPanel.Children.Add($ButtonGrid)

    # Add title for Output TextBox
    $OutputTitle = New-Object Windows.Controls.TextBlock
    $OutputTitle.Text = "Renamed Files:"
    $OutputTitle.FontSize = 14
    $OutputTitle.FontWeight = "Bold"
    $OutputTitle.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
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
    $OutputTextBox.IsReadOnly = $true  # Makes the TextBox read-only
    $OutputTextBox.VerticalScrollBarVisibility = "Auto"
    $OutputTextBox.HorizontalScrollBarVisibility = "Auto"

    # Add the Output TextBox after the ButtonGrid
    $CenterStackPanel.Children.Add($OutputTextBox)

    # Back button logic for Bulk Renaming page
    $BackButton.Add_Click({
        $BulkRenamingWindow.Hide()
        $MainPageWindow.ShowDialog() | Out-Null
    })

    # Add the CenterStackPanel to the BulkGrid
    $BulkGrid.Children.Add($CenterStackPanel)

    # Set the content of the BulkRenamingWindow
    $BulkRenamingWindow.Content = $BulkGrid
    
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
            }
        }
    })
    
    # Event handler for selection change on ListBox item
    $FileListBox.Add_SelectionChanged({
        # Get the selected file path
        $clickedFile = $FileListBox.SelectedItem
        
        if ($clickedFile) {
            # Open the file using the default application
            Start-Process $clickedFile
        }
    })
    
    # Rename button logic
    $RenameButton.Add_Click({
        $MainPageWindow.Hide()
        $BulkRenamingWindow.Show()
    
        $baseName = $BaseNameTextBox.Text
    
        # Check if any files have been selected
        if ($FileListBox.Items.Count -eq 0) {
            Write-Host "Error: Please select a file to rename." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please select files before proceeding.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if ([string]::IsNullOrWhiteSpace($baseName)) {
            Write-Host "Error: Please enter a base name." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please enter a base name.", "No Base Name", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        # Get selected files from the FileListBox
        $selectedFiles = $FileListBox.Items
    
        # Perform the batch renaming operation
        $batchOperation = Rename-WithBaseName -selectedFiles $selectedFiles -baseName $baseName
    
        # Display the renamed files in the OutputTextBox
        $OutputTextBox.Text = ""  # Clear previous output
    
        $FileListBox.Items.Clear()  # Clear the existing file list

        foreach ($operation in $batchOperation) {
            # Extract the file name part only (not the full path)
            $originalFileName = [System.IO.Path]::GetFileName($operation.OriginalPath)
            $newFileName = [System.IO.Path]::GetFileName($operation.NewPath)

            # Display the renaming result in the OutputTextBox
            $OutputTextBox.Text += "Renamed '$originalFileName' to '$newFileName'`r`n"

            # Add the new file path to the FileListBox
            $FileListBox.Items.Add($operation.NewPath)
        }
            [System.Windows.Forms.MessageBox]::Show("All files were successfully renamed.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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
    $ReplaceWindow.Height = 600
    $ReplaceWindow.Width = 500
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
    $ReplaceSelectFileButton.Margin = [Windows.Thickness]::new(0, 10, 0, 10)
    $ReplaceSelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceSelectFileButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceSelectFileButton.FontSize = 14
    $ReplaceSelectFileButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceSelectFileButton.FontWeight = "Bold"

    # Define a ControlTemplate for rounded corners (same as for $SelectFilesButton)
    $replaceSelectFilesTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $replaceSelectFilesBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])

    # Set the corner radius for rounded corners
    $replaceSelectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10

    # Set the background and border for the button
    $replaceSelectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $ReplaceSelectFileButton.Background)
    $replaceSelectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $ReplaceSelectFileButton.BorderBrush)
    $replaceSelectFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $ReplaceSelectFileButton.BorderThickness)

    # ContentPresenter to display button content
    $replaceSelectFilesContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $replaceSelectFilesContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $replaceSelectFilesContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $replaceSelectFilesBorderFactory.AppendChild($replaceSelectFilesContentPresenterFactory)

    # Set the visual tree of the button to the border
    $replaceSelectFilesTemplate.VisualTree = $replaceSelectFilesBorderFactory

    # Apply the ControlTemplate to the button
    $ReplaceSelectFileButton.Template = $replaceSelectFilesTemplate

    # Add hover effect for the button (same as for $SelectFilesButton)
    $ReplaceSelectFileButton.Add_MouseEnter({
        $ReplaceSelectFileButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Change to lighter blue on hover
    })
    $ReplaceSelectFileButton.Add_MouseLeave({
        $ReplaceSelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Return to original color when mouse leaves
    })

    # Add the button to the replace stack panel
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
    $ReplaceLabel.FontWeight = "Bold"
    $ReplaceLabel.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $ReplaceWithPanel.Children.Add($ReplaceLabel)

    $ReplaceTextBox = New-Object Windows.Controls.TextBox
    $ReplaceTextBox.Width = 100
    $ReplaceTextBox.FontSize = 14
    $ReplaceTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $ReplaceTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceTextBox.Margin = [Windows.Thickness]::new(0, 0, 10, 0)
    $ReplaceWithPanel.Children.Add($ReplaceTextBox)

    # Label for "With"
    $SubstituteWithLabel = New-Object Windows.Controls.TextBlock
    $SubstituteWithLabel.Text = "With:"
    $SubstituteWithLabel.FontSize = 14
    $SubstituteWithLabel.FontWeight = "Bold"
    $SubstituteWithLabel.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $SubstituteWithLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $ReplaceWithPanel.Children.Add($SubstituteWithLabel)

    # Text Box
    $SubstituteWithTextBox = New-Object Windows.Controls.TextBox
    $SubstituteWithTextBox.Width = 90
    $SubstituteWithTextBox.FontSize = 14
    $SubstituteWithTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $SubstituteWithTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceWithPanel.Children.Add($SubstituteWithTextBox)

    $ReplaceCenterStackPanel.Children.Add($ReplaceWithPanel)

    # Buttons for Apply, Back
    # Initialize ReplaceButtonGrid for layout
    $ReplaceButtonGrid = New-Object Windows.Controls.Grid
    $ReplaceButtonGrid.Margin = [Windows.Thickness]::new(0, 10, 0, 0)

    for ($row = 0; $row -lt 2; $row++) {
        $ReplaceButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ReplaceButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    # Apply Button (Apply)
    $ReplaceApplyButton = New-Object Windows.Controls.Button
    $ReplaceApplyButton.Content = "Apply"
    $ReplaceApplyButton.Width = 130
    $ReplaceApplyButton.Height = 35
    $ReplaceApplyButton.Margin = [Windows.Thickness]::new(0, 1, 0, 0)
    $ReplaceApplyButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $ReplaceApplyButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceApplyButton.FontSize = 14
    $ReplaceApplyButton.FontWeight = "Bold"
    $ReplaceApplyButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceApplyButton.BorderThickness = [Windows.Thickness]::new(1)

    # Define rounded corners for Apply button
    $ReplaceApplyButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $ReplaceApplyButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $ReplaceApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $ReplaceApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $ReplaceApplyButton.Background)
    $ReplaceApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $ReplaceApplyButton.BorderBrush)
    $ReplaceApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $ReplaceApplyButton.BorderThickness)

    # ContentPresenter to display button content
    $ReplaceApplyButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $ReplaceApplyButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $ReplaceApplyButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $ReplaceApplyButtonBorderFactory.AppendChild($ReplaceApplyButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $ReplaceApplyButtonTemplate.VisualTree = $ReplaceApplyButtonBorderFactory

    # Apply the ControlTemplate to the Apply button
    $ReplaceApplyButton.Template = $ReplaceApplyButtonTemplate

    # Hover effect for Apply button
    $ReplaceApplyButton.Add_MouseEnter({
        $ReplaceApplyButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Lighter blue on hover
    })
    $ReplaceApplyButton.Add_MouseLeave({
        $ReplaceApplyButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Original color
    })

    # Set position in ReplaceButtonGrid
    [Windows.Controls.Grid]::SetRow($ReplaceApplyButton, 0)
    [Windows.Controls.Grid]::SetColumn($ReplaceApplyButton, 0)
    $ReplaceButtonGrid.Children.Add($ReplaceApplyButton)

    # Back Button (Replace)
    $ReplaceBackButton = New-Object Windows.Controls.Button
    $ReplaceBackButton.Content = "Back"
    $ReplaceBackButton.Width = 130
    $ReplaceBackButton.Height = 35
    $ReplaceBackButton.Margin = [Windows.Thickness]::new(0, 1, 0, 0)
    $ReplaceBackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Darker Blue
    $ReplaceBackButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")  # White Text
    $ReplaceBackButton.FontSize = 14
    $ReplaceBackButton.FontWeight = "Bold"
    $ReplaceBackButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $ReplaceBackButton.BorderThickness = [Windows.Thickness]::new(1)
    $ReplaceBackButton.HorizontalAlignment = "Center"

    # Define rounded corners for Back button
    $ReplaceBackButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $ReplaceBackButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $ReplaceBackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $ReplaceBackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $ReplaceBackButton.Background)
    $ReplaceBackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $ReplaceBackButton.BorderBrush)
    $ReplaceBackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $ReplaceBackButton.BorderThickness)

    # ContentPresenter to display button content
    $ReplaceBackButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $ReplaceBackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $ReplaceBackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $ReplaceBackButtonBorderFactory.AppendChild($ReplaceBackButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $ReplaceBackButtonTemplate.VisualTree = $ReplaceBackButtonBorderFactory

    # Apply the ControlTemplate to the Back button
    $ReplaceBackButton.Template = $ReplaceBackButtonTemplate

    # Hover effect for Back button
    $ReplaceBackButton.Add_MouseEnter({
        $ReplaceBackButton.Background = (ConvertTo-SolidColorBrush "#0D47A1")  # Darker shade on hover
    })
    $ReplaceBackButton.Add_MouseLeave({
        $ReplaceBackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Original color
    })

    # Set position in ReplaceButtonGrid
    [Windows.Controls.Grid]::SetRow($ReplaceBackButton, 0)
    [Windows.Controls.Grid]::SetColumn($ReplaceBackButton, 1)
    $ReplaceButtonGrid.Children.Add($ReplaceBackButton)

    # Add the ReplaceButtonGrid to the main StackPanel
    $ReplaceCenterStackPanel.Children.Add($ReplaceButtonGrid)

    # Add title for Output TextBox
    $OutputTitle = New-Object Windows.Controls.TextBlock
    $OutputTitle.Text = "Renamed Files:"
    $OutputTitle.FontSize = 14
    $OutputTitle.FontWeight = "Bold"
    $OutputTitle.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
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

    # Replace Back button logic
    $ReplaceBackButton.Add_Click({
        $ReplaceWindow.Close()  # Close the current Replace window
        $MainPageWindow.ShowDialog() | Out-Null # Open the main window
    })

    # Add the ReplaceCenterStackPanel to the ReplaceGrid
    $ReplaceGrid.Children.Add($ReplaceCenterStackPanel)

    # Set the content of the ReplaceWindow
    $ReplaceWindow.Content = $ReplaceGrid

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

    $ReplaceFileListBox.Add_SelectionChanged({
        # Get the selected file path
        $clickedFile = $ReplaceFileListBox.SelectedItem
        
        if ($clickedFile) {
            # Open the file using the default application
            Start-Process $clickedFile
        }
    })

    $ReplaceApplyButton.Add_Click({
        $patternToFind = $ReplaceTextBox.Text
        $replacementWord = $SubstituteWithTextBox.Text
    
        # Check if any files have been selected
        if ($ReplaceFileListBox.Items.Count -eq 0) {
            Write-Host "Error: Please select a file to rename." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please select files before proceeding.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        if (-not $patternToFind -or -not $replacementWord) {
            Write-Host "Error: Both 'Replace' and 'With' fields must be filled." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Both 'Replace' and 'With' fields must be filled.", "Incomplete Fill in Fields", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $selectedFiles = $ReplaceFileListBox.Items
        $batchOperation = Rename-WithPatternReplacement -selectedFiles $selectedFiles -patternToFind $patternToFind -replacementWord $replacementWord
    
        # Display the renamed files in the OutputTextBox
        $ReplaceOutputTextBox.Text = ""  # Clear previous output
        $renamedCount = 0  # Initialize renamed count
    
        $ReplaceFileListBox.Items.Clear()

        foreach ($operation in $batchOperation) {
            $originalFileName = [System.IO.Path]::GetFileName($operation.OriginalPath)
            $newFileName = [System.IO.Path]::GetFileName($operation.NewPath)
    
            if ($originalFileName -ne $newFileName) {
                # Display the renaming result in the OutputTextBox
                $ReplaceOutputTextBox.Text += "Renamed '$originalFileName' to '$newFileName'`r`n"
                $renamedCount++

                $ReplaceFileListBox.Items.Add($operation.Newpath)
            }
        }
    
        if ($renamedCount -gt 0) {
            [System.Windows.Forms.MessageBox]::Show("All files were successfully renamed.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            [System.Windows.Forms.MessageBox]::Show("No files were renamed. Ensure the 'Replace' word exists in the selected file names.", "No Changes", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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
    $PrefixSuffixWindow.Height = 600
    $PrefixSuffixWindow.Width = 500
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

   # Prefix Suffix Select File button
    $PrefixSuffixSelectFileButton = New-Object Windows.Controls.Button
    $PrefixSuffixSelectFileButton.Content = "Select File"
    $PrefixSuffixSelectFileButton.Width = 130
    $PrefixSuffixSelectFileButton.Height = 35
    $PrefixSuffixSelectFileButton.Margin = [Windows.Thickness]::new(0, 10, 0, 10)
    $PrefixSuffixSelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $PrefixSuffixSelectFileButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $PrefixSuffixSelectFileButton.FontSize = 14
    $PrefixSuffixSelectFileButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $PrefixSuffixSelectFileButton.FontWeight = "Bold"

    # Define a ControlTemplate for rounded corners (same as the previous buttons)
    $prefixSuffixFilesTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $prefixSuffixFilesBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])

    # Set the corner radius for rounded corners
    $prefixSuffixFilesBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10

    # Set the background and border for the button
    $prefixSuffixFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $PrefixSuffixSelectFileButton.Background)
    $prefixSuffixFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $PrefixSuffixSelectFileButton.BorderBrush)
    $prefixSuffixFilesBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $PrefixSuffixSelectFileButton.BorderThickness)

    # ContentPresenter to display button content
    $prefixSuffixFilesContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $prefixSuffixFilesContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $prefixSuffixFilesContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $prefixSuffixFilesBorderFactory.AppendChild($prefixSuffixFilesContentPresenterFactory)

    # Set the visual tree of the button to the border
    $prefixSuffixFilesTemplate.VisualTree = $prefixSuffixFilesBorderFactory

    # Apply the ControlTemplate to the button
    $PrefixSuffixSelectFileButton.Template = $prefixSuffixFilesTemplate

    # Add hover effect for the button (same as previous buttons)
    $PrefixSuffixSelectFileButton.Add_MouseEnter({
        $PrefixSuffixSelectFileButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Change to lighter blue on hover
    })
    $PrefixSuffixSelectFileButton.Add_MouseLeave({
        $PrefixSuffixSelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Return to original color when mouse leaves
    })

    # Add the click event to open file dialog and add files to the list box
    $PrefixSuffixSelectFileButton.Add_Click({
        $dialog = New-Object Windows.Forms.OpenFileDialog
        $dialog.Multiselect = $true
        $dialog.ShowDialog() | Out-Null
        $dialog.FileNames | ForEach-Object { $PrefixSuffixFileListBox.Items.Add($_) }
    })

    # Add the button to the PrefixSuffixCenterStackPanel
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
    $PrefixLabel.FontWeight = "Bold"
    $PrefixLabel.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $PrefixLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $PrefixStackPanel.Children.Add($PrefixLabel)

    $PrefixTextBox = New-Object Windows.Controls.TextBox
    $PrefixTextBox.Width = 210
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
    $SuffixLabel.FontWeight = "Bold"
    $SuffixLabel.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $SuffixLabel.Margin = [Windows.Thickness]::new(0, 0, 5, 0)
    $SuffixStackPanel.Children.Add($SuffixLabel)

    $SuffixTextBox = New-Object Windows.Controls.TextBox
    $SuffixTextBox.Width = 210
    $SuffixTextBox.FontSize = 14
    $SuffixTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $SuffixTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $SuffixStackPanel.Children.Add($SuffixTextBox)

    $PrefixSuffixCenterStackPanel.Children.Add($SuffixStackPanel)
   
    # Buttons for Apply, Back
    # Initialize ButtonGrid for layout
    $ButtonGrid = New-Object Windows.Controls.Grid
    $ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)

    for ($row = 0; $row -lt 2; $row++) {
        $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    # Apply Button (Apply)
    $ApplyButton = Create-SmallButton -Content "Apply" -Row 0 -Column 0
    $ApplyButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")

    # Define rounded corners for Apply button
    $ApplyButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $ApplyButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $ApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $ApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $ApplyButton.Background)
    $ApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $ApplyButton.BorderBrush)
    $ApplyButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $ApplyButton.BorderThickness)

    # ContentPresenter to display button content
    $ApplyButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $ApplyButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $ApplyButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $ApplyButtonBorderFactory.AppendChild($ApplyButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $ApplyButtonTemplate.VisualTree = $ApplyButtonBorderFactory

    # Apply the ControlTemplate to the Apply button
    $ApplyButton.Template = $ApplyButtonTemplate

    # Hover effect for Apply button
    $ApplyButton.Add_MouseEnter({
        $ApplyButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Lighter blue on hover
    })
    $ApplyButton.Add_MouseLeave({
        $ApplyButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Original color
    })
    
    # Back Button (Back)
    $BackButton = Create-SmallButton -Content "Back" -Row 0 -Column 1
    $BackButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Darker Blue, like in Replace code

    # Define rounded corners for Back button
    $BackButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $BackButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $BackButton.Background)
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $BackButton.BorderBrush)
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $BackButton.BorderThickness)

    # ContentPresenter to display button content
    $BackButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $BackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $BackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $BackButtonBorderFactory.AppendChild($BackButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $BackButtonTemplate.VisualTree = $BackButtonBorderFactory

    # Apply the ControlTemplate to the Back button
    $BackButton.Template = $BackButtonTemplate

    # Hover effect for Back button
    $BackButton.Add_MouseEnter({
        $BackButton.Background = (ConvertTo-SolidColorBrush "#0D47A1")  # Darker shade on hover
    })
    $BackButton.Add_MouseLeave({
        $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Original color
    })

    # Adjusting margin between buttons to match Replace layout
    $ApplyButton.Margin = [Windows.Thickness]::new(0, 0, -30, 0)  # Add margin to match the ReplaceButtonGrid spacing
    $BackButton.Margin = [Windows.Thickness]::new(0, 0, 30, 0)  # Add margin to match the ReplaceButtonGrid spacing

    # Add Buttons to Grid
    $ButtonGrid.Children.Add($ApplyButton)
    $ButtonGrid.Children.Add($BackButton)

    # Add Buttons Grid to the PrefixSuffixCenterStackPanel
    $PrefixSuffixCenterStackPanel.Children.Add($ButtonGrid)

    # Add title for Renamed Files Output
    $RenamedFilesTitle = New-Object Windows.Controls.TextBlock
    $RenamedFilesTitle.Text = "Renamed Files:"
    $RenamedFilesTitle.FontSize = 14
    $RenamedFilesTitle.FontWeight = "Bold"
    $RenamedFilesTitle.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $RenamedFilesTitle.HorizontalAlignment = "Center"
    $RenamedFilesTitle.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $PrefixSuffixCenterStackPanel.Children.Add($RenamedFilesTitle)

    # Layout for Output TextBox
    $SuffixPrefixOutputTextBox = New-Object Windows.Controls.TextBox
    $SuffixPrefixOutputTextBox.Width = 300
    $SuffixPrefixOutputTextBox.Height = 100
    $SuffixPrefixOutputTextBox.FontSize = 12
    $SuffixPrefixOutputTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $SuffixPrefixOutputTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $SuffixPrefixOutputTextBox.Margin = [Windows.Thickness]::new(0, 10, 0, 0)
    $SuffixPrefixOutputTextBox.BorderThickness = [Windows.Thickness]::new(2)
    $SuffixPrefixOutputTextBox.IsReadOnly = $true
    $SuffixPrefixOutputTextBox.VerticalScrollBarVisibility = "Auto"
    $SuffixPrefixOutputTextBox.HorizontalScrollBarVisibility = "Auto"
    $PrefixSuffixCenterStackPanel.Children.Add($SuffixPrefixOutputTextBox)

    # Add the PrefixSuffixCenterStackPanel to the PrefixSuffixGrid
    $PrefixSuffixGrid.Children.Add($PrefixSuffixCenterStackPanel)

    # Set Grid as content
    $PrefixSuffixWindow.Content = $PrefixSuffixGrid

    # Apply Button logic (same as in your original code)
    $ApplyButton.Add_Click({

        # Get the prefix and suffix values from the textboxes
        $prefix = $PrefixTextBox.Text
        $suffix = $SuffixTextBox.Text

        # Check if any files have been selected
        if ($PrefixSuffixFileListBox.Items.Count -eq 0) {
            Write-Host "Error: Please select a file to rename." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please select files before proceeding.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        # Ensure both prefix and suffix are entered
        if (-not $prefix -and -not $suffix) {
            Write-Host "Error: Both prefix and suffix cannot be empty." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Both prefix and suffix cannot be empty.", "Incomplete Fill in Fields", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
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

        $PrefixSuffixFileListBox.Items.Clear()

        # Process each operation in batch
        foreach ($operation in $batchOperation) {
            # Extract the old and new filenames from the operation
            $originalFileName = [System.IO.Path]::GetFileName($operation.OriginalPath)  # Get original file name
            $newFileName = [System.IO.Path]::GetFileName($operation.NewPath)  # Get new file name
            # Format the renaming message
            $renamingMessage = "Renamed '$originalFileName' to '$newFileName'"
            # Display the message in the output TextBox, appending to existing content
            $SuffixPrefixOutputTextBox.AppendText($renamingMessage + "`r`n")

            $PrefixSuffixFileListBox.Items.Add($operation.NewPath)
        }

        [System.Windows.Forms.MessageBox]::Show("All files were successfully renamed.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    })

    # Back Button Logic (close the current window and show the MainPageWindow)
    $BackButton.Add_Click({
        $PrefixSuffixWindow.Close()
        $MainPageWindow.ShowDialog() | Out-Null
    })

    # Event handler for selection change on ListBox item
    $PrefixSuffixFileListBox.Add_SelectionChanged({
        # Get the selected file path
        $clickedFile = $PrefixSuffixFileListBox.SelectedItem
        
        if ($clickedFile) {
            # Open the file using the default application
            Start-Process $clickedFile
        }
    })

    # Show the Prefix-Suffix window
    $PrefixSuffixWindow.ShowDialog()
}

function showEncryptDecryptWindow {
    param()
    $MainPageWindow.Hide() 

    $EncryptionWindow = New-Object Windows.Window
    $EncryptionWindow.Title = "SHIFTIFY: Encryption and Decryption Tool"
    $EncryptionWindow.Height = 600
    $EncryptionWindow.Width = 500
    $EncryptionWindow.WindowStartupLocation = "CenterScreen"
    $EncryptionWindow.FontFamily = "Segoe UI"
    $EncryptionWindow.Background = (ConvertTo-SolidColorBrush "#E3F2FD")
    $EncryptionWindow.ResizeMode = "NoResize"
    $EncryptionWindow.WindowStyle = "SingleBorderWindow"

    # Create a Grid for Encryption Page
    $EncryptionGrid = New-Object Windows.Controls.Grid

    # Load the Logo Image
    $LogoSource = New-Object System.Windows.Media.Imaging.BitmapImage
    $LogoSource.BeginInit()
    $LogoSource.UriSource = New-Object System.Uri("Shiftify Logo.png", [System.UriKind]::RelativeOrAbsolute)
    $LogoSource.EndInit()

    # Create an Image Control for the Logo
    $LogoImage = New-Object Windows.Controls.Image
    $LogoImage.Source = $LogoSource
    $LogoImage.Width = 500 # Adjust as needed
    $LogoImage.Height = 200 # Adjust as needed
    $LogoImage.HorizontalAlignment = "Center"
    $LogoImage.VerticalAlignment = "Bottom"
    $LogoImage.Margin = [Windows.Thickness]::new(0, 2, 0, -22)

    # Add the Logo to the Main Grid (or use a DockPanel for more control)
    $EncryptionGrid.Children.Add($LogoImage)

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

    # Encryption Title Text Block
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
    $SelectFileButton.Margin = [Windows.Thickness]::new(0, 10, 0, 10)
    $SelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")
    $SelectFileButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $SelectFileButton.FontSize = 14
    $SelectFileButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $SelectFileButton.FontWeight = "Bold"

    # Define a ControlTemplate for rounded corners (same as previous buttons)
    $selectFileTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $selectFileBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])

    # Set the corner radius for rounded corners
    $selectFileBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10

    # Set the background and border for the button
    $selectFileBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $SelectFileButton.Background)
    $selectFileBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $SelectFileButton.BorderBrush)
    $selectFileBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $SelectFileButton.BorderThickness)

    # ContentPresenter to display button content
    $selectFileContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $selectFileContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $selectFileContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $selectFileBorderFactory.AppendChild($selectFileContentPresenterFactory)

    # Set the visual tree of the button to the border
    $selectFileTemplate.VisualTree = $selectFileBorderFactory

    # Apply the ControlTemplate to the button
    $SelectFileButton.Template = $selectFileTemplate

    # Add hover effect for the button (same as previous buttons)
    $SelectFileButton.Add_MouseEnter({
        $SelectFileButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Change to lighter blue on hover
    })
    $SelectFileButton.Add_MouseLeave({
        $SelectFileButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Return to original color when mouse leaves
    })

    # Add the button to the EncryptionCenterStackPanel
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
    $FindLabel.FontWeight = "Bold"
    $FindLabel.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")
    $FindLabel.Margin = [Windows.Thickness]::new(0, 10, 0, 5)
    $FindLabel.HorizontalAlignment = "Center"
    $EncryptionCenterStackPanel.Children.Add($FindLabel)

    # Text Box for Find
    $FindTextBox = New-Object Windows.Controls.TextBox
    $FindTextBox.Width = 200
    $FindTextBox.FontSize = 14
    $FindTextBox.Background = (ConvertTo-SolidColorBrush "#FFFFFF")
    $FindTextBox.BorderBrush = (ConvertTo-SolidColorBrush "#90CAF9")
    $FindTextBox.Margin = [Windows.Thickness]::new(0, 0, 0, 10)
    $EncryptionCenterStackPanel.Children.Add($FindTextBox)

    # Buttons for Encrypt, Decrypt, and Back
    # Initialize ButtonGrid for layout
    $ButtonGrid = New-Object Windows.Controls.Grid
    $ButtonGrid.Margin = [Windows.Thickness]::new(0, 20, 0, 0)
    $ButtonGrid.HorizontalAlignment = "Center"
    $ButtonGrid.VerticalAlignment = "Center"

    # Define Rows and Columns
    for ($row = 0; $row -lt 2; $row++) {
        $ButtonGrid.RowDefinitions.Add([Windows.Controls.RowDefinition]::new())
    }
    for ($col = 0; $col -lt 2; $col++) {
        $ButtonGrid.ColumnDefinitions.Add([Windows.Controls.ColumnDefinition]::new())
    }

    # Encrypt Button
    $EncryptButton = Create-StyledButton -Content "Encrypt" -Row 0 -Column 0
    $EncryptButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")

    # Define rounded corners for Encrypt button
    $EncryptButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $EncryptButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $EncryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $EncryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $EncryptButton.Background)
    $EncryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $EncryptButton.BorderBrush)
    $EncryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $EncryptButton.BorderThickness)

    # ContentPresenter to display button content
    $EncryptButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $EncryptButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $EncryptButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $EncryptButtonBorderFactory.AppendChild($EncryptButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $EncryptButtonTemplate.VisualTree = $EncryptButtonBorderFactory

    # Apply the ControlTemplate to the Encrypt button
    $EncryptButton.Template = $EncryptButtonTemplate

    # Hover effect for Encrypt button
    $EncryptButton.Add_MouseEnter({
        $EncryptButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Lighter blue on hover
    })
    $EncryptButton.Add_MouseLeave({
        $EncryptButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Original color
    })

    # Decrypt Button
    $DecryptButton = Create-StyledButton -Content "Decrypt" -Row 0 -Column 1
    $DecryptButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")

    # Define rounded corners for Decrypt button
    $DecryptButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $DecryptButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $DecryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $DecryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $DecryptButton.Background)
    $DecryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $DecryptButton.BorderBrush)
    $DecryptButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $DecryptButton.BorderThickness)

    # ContentPresenter to display button content
    $DecryptButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $DecryptButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $DecryptButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $DecryptButtonBorderFactory.AppendChild($DecryptButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $DecryptButtonTemplate.VisualTree = $DecryptButtonBorderFactory

    # Apply the ControlTemplate to the Decrypt button
    $DecryptButton.Template = $DecryptButtonTemplate

    # Hover effect for Decrypt button
    $DecryptButton.Add_MouseEnter({
        $DecryptButton.Background = (ConvertTo-SolidColorBrush "#64B5F6")  # Lighter blue on hover
    })
    $DecryptButton.Add_MouseLeave({
        $DecryptButton.Background = (ConvertTo-SolidColorBrush "#90CAF9")  # Original color
    })

    # Back Button (Center Below Encrypt and Decrypt)
    $BackButton = Create-StyledButton -Content "Back" -Row 1 -Column 0
    $BackButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")
    $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Darker Blue
    $BackButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")  # White Text

    # Define rounded corners for Back button
    $BackButtonTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
    $BackButtonBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(10))  # Rounded corners with radius 10
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $BackButton.Background)
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $BackButton.BorderBrush)
    $BackButtonBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $BackButton.BorderThickness)

    # ContentPresenter to display button content
    $BackButtonContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
    $BackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
    $BackButtonContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

    # Append ContentPresenter to the border
    $BackButtonBorderFactory.AppendChild($BackButtonContentPresenterFactory)

    # Set the visual tree of the button to the border
    $BackButtonTemplate.VisualTree = $BackButtonBorderFactory

    # Apply the ControlTemplate to the Back button
    $BackButton.Template = $BackButtonTemplate

    # Hover effect for Back button
    $BackButton.Add_MouseEnter({
        $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Darker shade on hover
    })
    $BackButton.Add_MouseLeave({
        $BackButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Original color
    })

    [Windows.Controls.Grid]::SetColumnSpan($BackButton, 2)  # Span both columns to center

    # Add Buttons to Grid
    $ButtonGrid.Children.Add($EncryptButton)
    $ButtonGrid.Children.Add($DecryptButton)
    $ButtonGrid.Children.Add($BackButton)

    # Add the Grid to the Parent Container
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

    $EncryptionFileListBox.Add_SelectionChanged({
        # Get the selected file path
        $clickedFile = $EncryptionFileListBox.SelectedItem
        
        if ($clickedFile) {
            # Open the file using the default application
            Start-Process $clickedFile
        }
    })

    # Encryption Button Logic
    $EncryptButton.Add_Click({
        if ($EncryptionFileListBox.Items.Count -eq 0) {
            Write-Host "Error: Please select a file to encrypt." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please select files to encrypt.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $Password = $FindTextBox.Text
        if ([string]::IsNullOrWhiteSpace($Password)) {
            Write-Host "Error: Please enter a secret key." -ForegroundColor Red
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
      
    # Decryption Button Logic
    $DecryptButton.Add_Click({
        if ($EncryptionFileListBox.Items.Count -eq 0) {
            Write-Host "Error: Please select a file to decrypt." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please select files to decrypt.", "No Files Selected", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $Password = $FindTextBox.Text

        if ([string]::IsNullOrWhiteSpace($Password)) {
            Write-Host "Error: Please enter a secret key." -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show("Please enter a secret key.", "No Secret Key", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
    
        $successCount = 0
        $passwordCorrect = $true

        foreach ($filePath in $EncryptionFileListBox.Items) {
            try {
                Decrypt-File -InputFile $filePath -Password $Password
                Write-Host "Success: File Decrypted successfully: $filePath" -ForegroundColor Green
                $successCount++
            } catch {
                if ($_.Exception.Message -match "Incorrect password") {
                    Write-Host "Error: Incorrect password provided." -ForegroundColor Red
                    $passwordCorrect = $false
                    break
                } else {
                    Write-Host "Error: Failed to decrypt file: $filePath`n$_" -ForegroundColor Red
                }
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
$MainPageWindow.Width = 500
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
$LogoImage.Width = 900 # Adjust as needed
$LogoImage.Height = 420 # Adjust as needed
$LogoImage.HorizontalAlignment = "Center"
$LogoImage.VerticalAlignment = "Top"
$LogoImage.Margin = [Windows.Thickness]::new(0, -150, 0, 0)

# Add the Logo to the Main Grid
$MainGrid.Children.Add($LogoImage) | Out-Null

# Define the button grid
$ButtonGrid = New-Object Windows.Controls.Grid
$ButtonGrid.HorizontalAlignment = "Center"
$ButtonGrid.VerticalAlignment = "Top"
$ButtonGrid.Margin = [Windows.Thickness]::new(0, 160, 0, 0)

# Define rows and columns for the grid
for ($i = 0; $i -lt 3; $i++) {
    $RowDefinition = New-Object Windows.Controls.RowDefinition
    $RowDefinition.Height = "Auto"  # Auto-sized rows
    $ButtonGrid.RowDefinitions.Add($RowDefinition) | Out-Null
}
for ($i = 0; $i -lt 2; $i++) {
    $ColumnDefinition = New-Object Windows.Controls.ColumnDefinition
    $ColumnDefinition.Width = "Auto"  # Auto-sized columns
    $ButtonGrid.ColumnDefinitions.Add($ColumnDefinition) | Out-Null
}

# Create buttons with spacing adjustments
$BulkRenameButton = Create-Button -Content "Bulk Renaming" -TopMargin 0 -Width 180 -Height 50
$BulkRenameButton.Margin = [Windows.Thickness]::new(8)  # Add space around the button

$PrefixSuffixButton = Create-Button -Content "Prefix & Suffix" -TopMargin 0 -Width 180 -Height 50
$PrefixSuffixButton.Margin = [Windows.Thickness]::new(8)

$ReplaceButton = Create-Button -Content "Replacing" -TopMargin 0 -Width 180 -Height 50
$ReplaceButton.Margin = [Windows.Thickness]::new(8)

$EncryptButton = Create-Button -Content "Encryption & Decryption" -TopMargin 0 -Width 180 -Height 50
$EncryptButton.Margin = [Windows.Thickness]::new(8)

# Set the grid positions for each button
$BulkRenameButton.SetValue([Windows.Controls.Grid]::RowProperty, 0)
$BulkRenameButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)

$ReplaceButton.SetValue([Windows.Controls.Grid]::RowProperty, 0)
$ReplaceButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)

$PrefixSuffixButton.SetValue([Windows.Controls.Grid]::RowProperty, 1)
$PrefixSuffixButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 0)

$EncryptButton.SetValue([Windows.Controls.Grid]::RowProperty, 1)
$EncryptButton.SetValue([Windows.Controls.Grid]::ColumnProperty, 1)

# Add the buttons to the grid
$ButtonGrid.Children.Add($BulkRenameButton) | Out-Null
$ButtonGrid.Children.Add($ReplaceButton) | Out-Null
$ButtonGrid.Children.Add($PrefixSuffixButton) | Out-Null
$ButtonGrid.Children.Add($EncryptButton) | Out-Null

# Add the grid to the main grid
$MainGrid.Children.Add($ButtonGrid) | Out-Null

# Create the Exit Button
$ExitButton = New-Object Windows.Controls.Button
$ExitButton.Content = "Exit"
$ExitButton.Width = 180
$ExitButton.Height = 50
$ExitButton.FontSize = 14
$ExitButton.FontWeight = "Bold"
$ExitButton.Margin = [Windows.Thickness]::new(8)

# Set the Exit Button's unique style
$ExitButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Darker Blue
$ExitButton.Foreground = (ConvertTo-SolidColorBrush "#0D47A1")  # White Text
$ExitButton.BorderBrush = (ConvertTo-SolidColorBrush "#0D47A1")  # Even Darker Blue Border
$ExitButton.BorderThickness = [Windows.Thickness]::new(2)

# Define a ControlTemplate with rounded corners
$exitTemplate = New-Object System.Windows.Controls.ControlTemplate([System.Windows.Controls.Button])
$exitBorderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Border])

# Set corner radius
$exitBorderFactory.SetValue([System.Windows.Controls.Border]::CornerRadiusProperty, [System.Windows.CornerRadius]::new(15))  # Rounded corners with radius 15

# Set background and border
$exitBorderFactory.SetValue([System.Windows.Controls.Border]::BackgroundProperty, $ExitButton.Background)
$exitBorderFactory.SetValue([System.Windows.Controls.Border]::BorderBrushProperty, $ExitButton.BorderBrush)
$exitBorderFactory.SetValue([System.Windows.Controls.Border]::BorderThicknessProperty, $ExitButton.BorderThickness)

# ContentPresenter to display button content
$exitContentPresenterFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.ContentPresenter])
$exitContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::HorizontalAlignmentProperty, [System.Windows.HorizontalAlignment]::Center)
$exitContentPresenterFactory.SetValue([System.Windows.Controls.ContentPresenter]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)

# Add the ContentPresenter to the border
$exitBorderFactory.AppendChild($exitContentPresenterFactory)

# Set the template's visual tree to the border
$exitTemplate.VisualTree = $exitBorderFactory

# Apply the template to the ExitButton
$ExitButton.Template = $exitTemplate

# Add a hover effect for the Exit button
$ExitButton.Add_MouseEnter({
    $ExitButton.Background = (ConvertTo-SolidColorBrush "#0D47A1")  # Darker shade on hover
})
$ExitButton.Add_MouseLeave({
    $ExitButton.Background = (ConvertTo-SolidColorBrush "#6FA8DC")  # Original color
})

# Add the Exit button's click event
$ExitButton.Add_Click({
    $MainPageWindow.Close()
})

# Set the Exit Button's grid position
$ExitButton.SetValue([Windows.Controls.Grid]::RowProperty, 2)
$ExitButton.SetValue([Windows.Controls.Grid]::ColumnSpanProperty, 2)

# Add the Exit Button to the grid
$ButtonGrid.Children.Add($ExitButton) | Out-Null

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

