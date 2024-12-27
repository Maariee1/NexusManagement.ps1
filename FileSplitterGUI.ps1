# Add necessary .NET types
Add-Type -AssemblyName PresentationFramework

# Function to create a SolidColorBrush from RGB values
function New-SolidColorBrush {
    param (
        [int]$R,
        [int]$G,
        [int]$B
    )
    $color = [System.Windows.Media.Color]::FromArgb(255, $R, $G, $B)
    return New-Object System.Windows.Media.SolidColorBrush($color)
}

# Create the main window
$window = New-Object System.Windows.Window
$window.Title = "File Splitter and Joiner"
$window.Width = 400
$window.Height = 400  # Reduced height
$window.ResizeMode = "NoResize"
$window.Background = New-SolidColorBrush -R 173 -G 216 -B 230 # LightBlue
$window.WindowStartupLocation = "CenterScreen"

# Create a grid for layout
$grid = New-Object System.Windows.Controls.Grid
$grid.Margin = "10"

# Define grid rows
$rowDefinitions = @(80, 30, 40, 40, 40, 40, 40) # Adjusted row heights for compact layout
foreach ($height in $rowDefinitions) {
    $row = New-Object System.Windows.Controls.RowDefinition
    $row.Height = [System.Windows.GridLength]::Auto
    $grid.RowDefinitions.Add($row)
}

# Title container (a Border for styling)
$titleBorder = New-Object System.Windows.Controls.Border
$titleBorder.BorderBrush = New-SolidColorBrush -R 0 -G 0 -B 0  # Black border
$titleBorder.BorderThickness = [System.Windows.Thickness]::new(2)
$titleBorder.Background = New-SolidColorBrush -R 70 -G 130 -B 180  # SteelBlue background
$titleBorder.Margin = "0,10,0,10"
$titleBorder.SetValue([System.Windows.Controls.Grid]::RowProperty, 0)

# Title TextBlock with styling
$titleText = New-Object System.Windows.Controls.TextBlock
$titleText.Text = "File Splitter and Joiner"
$titleText.FontSize = 24
$titleText.FontWeight = "Bold"
$titleText.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
$titleText.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255  # White text
$titleText.TextAlignment = "Center"
$titleText.VerticalAlignment = "Center"

# Add shadow effect to the title text
$dropShadowEffect = New-Object System.Windows.Media.Effects.DropShadowEffect
$dropShadowEffect.Color = [System.Windows.Media.Color]::FromArgb(100, 0, 0, 0)  # Semi-transparent black shadow
$dropShadowEffect.Direction = 320  # Angle of the shadow
$dropShadowEffect.ShadowDepth = 5  # Distance of shadow
$dropShadowEffect.BlurRadius = 10  # Blur of shadow

$titleText.Effect = $dropShadowEffect

# Add the TextBlock to the Border
$titleBorder.Child = $titleText

# Add the title border to the grid
$grid.Children.Add($titleBorder)

# Add motto text
$motto = New-Object System.Windows.Controls.TextBlock
$motto.Text = "Effortless File Management"
$motto.FontSize = 12
$motto.HorizontalAlignment = "Center"
$motto.Foreground = New-SolidColorBrush -R 0 -G 0 -B 128 # Navy
$motto.SetValue([System.Windows.Controls.Grid]::RowProperty, 1)
$grid.Children.Add($motto)

# Function to handle button clicks
function Handle-ButtonClick {
    param (
        [string]$Action
    )
    # Display a placeholder message for now
    [System.Windows.MessageBox]::Show("You clicked the $Action button! Add backend logic here.", "$Action Action", "OK", "Information")
}

# Create buttons
$buttonNames = @("Split", "Join", "Encrypt", "Decrypt", "Exit")
$buttonColors = @(
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 70; G = 130; B = 180 },  # SteelBlue
    @{ R = 0; G = 0; B = 139 }      # Darker Blue for Exit
)

for ($i = 0; $i -lt $buttonNames.Length; $i++) {
    # Button container (Border for styling)
    $buttonBorder = New-Object System.Windows.Controls.Border
    $buttonBorder.BorderThickness = [System.Windows.Thickness]::new(2)
    $buttonBorder.Margin = "0,5,0,5"
    $buttonBorder.HorizontalAlignment = "Center"
    $buttonBorder.Width = 130
    $buttonBorder.Height = 40
   
    $button = New-Object System.Windows.Controls.Button
    $button.Content = $buttonNames[$i]
    $button.Width = 120
    $button.Height = 30  # Reduced size for compactness
    $button.Margin = "0"
    $button.FontSize = 16
    $button.FontWeight = "Bold"
    $button.FontFamily = New-Object System.Windows.Media.FontFamily("Arial")
    $button.HorizontalAlignment = "Center"
    $button.Background = New-SolidColorBrush -R $buttonColors[$i].R -G $buttonColors[$i].G -B $buttonColors[$i].B
    $button.Foreground = New-SolidColorBrush -R 255 -G 255 -B 255 # White Text

    # Add click event handler using a scriptblock for context
    $button.Add_Click({
        $action = $button.Content
        Handle-ButtonClick -Action $action
    })

    $buttonBorder.Child = $button
    $buttonBorder.SetValue([System.Windows.Controls.Grid]::RowProperty, $i + 2)
    $grid.Children.Add($buttonBorder)
}

# Add the grid to the window
$window.Content = $grid

# Show the window
$window.ShowDialog()