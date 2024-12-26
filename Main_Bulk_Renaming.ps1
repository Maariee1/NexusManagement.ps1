#Load necessary assemblies for WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore

#XAML layout 
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="SHIFTIFY: Bulk Renaming Tool" Height="450" Width="700" WindowStartupLocation="CenterScreen" FontFamily="Segoe UI">
    <Grid Background="#E3F2FD">
        <!-- Title -->
        <TextBlock Text="SHIFTIFY: " HorizontalAlignment="Center" VerticalAlignment="Top" 
                   FontSize="26" FontWeight="Bold" Foreground="#1565C0" Margin="0,10,0,0"/>

        <!-- Input Fields -->
        <TextBlock Text="Folder Path:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="20,60,0,0" FontSize="14"/>
        <Border BorderBrush="#1565C0" BorderThickness="2" CornerRadius="5" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="100,60,0,0" Width="450" Height="30">
            <TextBox Name="FolderPath" Width="448" Height="28" Background="White" Foreground="Black"/>
        </Border>
        <Button Name="BrowseButton" Content="Browse" Width="80" Height="30" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="570,60,0,0" Background="#64B5F6" Foreground="White" BorderBrush="#1565C0" BorderThickness="2"/>

        <!-- Buttons -->
        <Button Name="PreviewButton" Content="Preview" Width="100" Height="30" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="100,150,0,0" Background="#64B5F6" Foreground="White" BorderBrush="#1565C0" BorderThickness="2"/>
        <Button Name="RenameButton" Content="Rename" Width="100" Height="30" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="220,150,0,0" Background="#64B5F6" Foreground="White" BorderBrush="#1565C0" BorderThickness="2"/>
        <Button Name="UndoButton" Content="Undo" Width="100" Height="30" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="340,150,0,0" Background="#64B5F6" Foreground="White" BorderBrush="#1565C0" BorderThickness="2"/>
        <Button Name="SuffixButton" Content="Add Suffix" Width="100" Height="30" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="460,150,0,0" Background="#64B5F6" Foreground="White" BorderBrush="#1565C0" BorderThickness="2"/>
        <Button Name="PrefixButton" Content="Add Prefix" Width="100" Height="30" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="580,150,0,0" Background="#64B5F6" Foreground="White" BorderBrush="#1565C0" BorderThickness="2"/>

        <!-- Output Display -->
        <TextBlock Text="Renaming files:" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="20,220,0,0" FontSize="14"/>
        <Border BorderBrush="#1565C0" BorderThickness="2" CornerRadius="5" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="20,240,0,0" Width="640" Height="120">
            <TextBox Name="OutputBox" Width="638" Height="118" Background="White" Foreground="Black" TextWrapping="Wrap" IsReadOnly="True"/>
        </Border>
    </Grid>
</Window>
"@


#Parse the XAML
[xml]$xamlObject = $XAML
$reader = (New-Object System.Xml.XmlNodeReader $xamlObject)
$Window = [Windows.Markup.XamlReader]::Load($reader)

#Map UI elements to PowerShell variables
$FolderPath = $Window.FindName("FolderPath")
$BrowseButton = $Window.FindName("BrowseButton")
$PreviewButton = $Window.FindName("PreviewButton")
$RenameButton = $Window.FindName("RenameButton")
$UndoButton = $Window.FindName("UndoButton")
$SuffixButton = $Window.FindName("SuffixButton")
$PrefixButton = $Window.FindName("PrefixButton")
$OutputBox = $Window.FindName("OutputBox")

#Global variables to track changes
$FileBackup = @{}

#Event Handlers
$BrowseButton.Add_Click({
    $folder = (New-Object -ComObject Shell.Application).BrowseForFolder(0, "Select Folder", 0).Self.Path
    if ($folder) { $FolderPath.Text = $folder }
})

$PreviewButton.Add_Click({
    $path = $FolderPath.Text
    if (-not (Test-Path $path)) {
        $OutputBox.Text = "Error: Folder path is invalid."
        return
    }
    $files = Get-ChildItem -Path $path -File
    $output = "Renaming files:`n"
    foreach ($file in $files) {
        $output += "$($file.Name)`n"
    }
    $OutputBox.Text = $output
})

$RenameButton.Add_Click({
    $path = $FolderPath.Text
    if (-not (Test-Path $path)) {
        $OutputBox.Text = "Error: Folder path is invalid."
        return
    }
    $files = Get-ChildItem -Path $path -File
    $FileBackup = @{ }
    foreach ($file in $files) {
        $newName = $file.Name
        $FileBackup[$file.FullName] = $file.Name
        Rename-Item -Path $file.FullName -NewName $newName
    }
    $OutputBox.Text = "Renaming completed!"
})

$UndoButton.Add_Click({
    foreach ($file in $FileBackup.GetEnumerator()) {
        Rename-Item -Path $file.Key -NewName $file.Value
    }
    $FileBackup.Clear()
    $OutputBox.Text = "Undo completed!"
})

$SuffixButton.Add_Click({
    $path = $FolderPath.Text
    if (-not (Test-Path $path)) {
        $OutputBox.Text = "Error: Folder path is invalid."
        return
    }
    $files = Get-ChildItem -Path $path -File
    $FileBackup = @{ }
    foreach ($file in $files) {
        $newName = "$($file.BaseName)_suffix$($file.Extension)"
        $FileBackup[$file.FullName] = $file.Name
        Rename-Item -Path $file.FullName -NewName $newName
    }
    $OutputBox.Text = "Suffix added to files!"
})

$PrefixButton.Add_Click({
    $path = $FolderPath.Text
    if (-not (Test-Path $path)) {
        $OutputBox.Text = "Error: Folder path is invalid."
        return
    }
    $files = Get-ChildItem -Path $path -File
    $FileBackup = @{ }
    foreach ($file in $files) {
        $newName = "prefix_$($file.Name)"
        $FileBackup[$file.FullName] = $file.Name
        Rename-Item -Path $file.FullName -NewName $newName
    }
    $OutputBox.Text = "Prefix added to files!"
})

#Show the window
$Window.ShowDialog() | Out-Null
