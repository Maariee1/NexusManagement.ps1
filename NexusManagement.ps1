# Load required .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create Main Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Remote Desktop Manager"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Listbox for Computers
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 10)
$listBox.Size = New-Object System.Drawing.Size(360, 120)
$form.Controls.Add($listBox)

# Textbox for IP Address
$ipTextbox = New-Object System.Windows.Forms.TextBox
$ipTextbox.Location = New-Object System.Drawing.Point(10, 140)
$ipTextbox.Size = New-Object System.Drawing.Size(260, 20)
$ipTextbox.Text = "Enter IP or Computer Name"
$ipTextbox.ForeColor = [System.Drawing.Color]::Gray
$form.Controls.Add($ipTextbox)

# Placeholder behavior
$ipTextbox.Add_GotFocus({ if ($ipTextbox.Text -eq "Enter IP or Computer Name") { $ipTextbox.Text = ""; $ipTextbox.ForeColor = [System.Drawing.Color]::Black } })
$ipTextbox.Add_LostFocus({ if ([string]::IsNullOrWhiteSpace($ipTextbox.Text)) { $ipTextbox.Text = "Enter IP or Computer Name"; $ipTextbox.ForeColor = [System.Drawing.Color]::Gray } })

# Add Computer Button
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Add"
$btnAdd.Location = New-Object System.Drawing.Point(280, 140)
$btnAdd.Add_Click({
    $ip = $ipTextbox.Text
    if (![string]::IsNullOrWhiteSpace($ip) -and $ip -ne "Enter IP or Computer Name") {
        $listBox.Items.Add($ip)
        $ipTextbox.Clear()
        $ipTextbox.Text = "Enter IP or Computer Name"
        $ipTextbox.ForeColor = [System.Drawing.Color]::Gray
    }
})
$form.Controls.Add($btnAdd)

# Remove Selected Computer Button
$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = "Remove"
$btnRemove.Location = New-Object System.Drawing.Point(10, 170)
$btnRemove.Add_Click({
    if ($listBox.SelectedItem) { $listBox.Items.Remove($listBox.SelectedItem) }
})
$form.Controls.Add($btnRemove)

# Connect Button
$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(130, 170)
$btnConnect.Add_Click({
    if ($listBox.SelectedItem) {
        Start-Process "mstsc.exe" -ArgumentList "/v:$($listBox.SelectedItem)"
    }
})
$form.Controls.Add($btnConnect)

# Show Form
$form.ShowDialog()

