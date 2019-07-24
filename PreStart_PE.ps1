<# 
********************************************************************************************************* 
			             Created by Tyler Lane, 9/7/2018		 	                
*********************************************************************************************************
Modified by   |  Date   | Revision | Comments                                                       
_________________________________________________________________________________________________________
Tyler Lane    | 9/7/18  |   v1.0   | First version
Tyler Lane    | 6/26/19 |   v1.1   | Cleaned up code, added comments, prepared for collaboration                                                 
_________________________________________________________________________________________________________
.NAME
	PreStart_PE
.SYNOPSIS 
    This is an SCCM task sequence pre-start GUI intended to capture data relevant to the post-OSD use of
	the PC. The GUI presents options to label the computer with Department, Category, and Function, which 
	is then stamped in the registry after OSD. This information is automatically inventoried in SCCM as 
	an Installed Software and can be used to create device collections. 
	
	This script has one variant for PE and another for within Windows, as indicated by the name. This
	variant also provides the option to clean the hard drive (helpful in avoiding errors imaging a device
	with non-bitlocker encryption), maintaning direct associations after OSD, and configuring the PC
	as an autologon device using a domain account. 
.PARAMETERS 
    None
.EXAMPLE 
    None 
.NOTES 
	Search for "DATA_REQUIRED" to see any data points that need filled in for the script to work properly
#>

# Enable environmental variables
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction SilentlyContinue

# Retrieve Service Account Info
$Domain = "" <# DATA_REQUIRED #>
$UserName = "" <# DATA_REQUIRED #>
$FullUserName = $UserName+"@"+$Domain
$Password = "" <# DATA_REQUIRED #>

# Map network drives
net use "" /delete /yes <# DATA_REQUIRED : Network path where tag csv files are stored #>
net use L: /delete /yes
net use L: "" /user:$FullUserName $Password <# DATA_REQUIRED : Network path where tag csv files are stored #>

# Script Blocks - Button Actions

$ScriptBlockRunButton = {

	# Disable Run button until the process is complete
	$RunButton.Enabled = $false
	
	# Collection form variables
	
	$ComputerName = $TextBox1.Text
	$Department = $DropDown1.SelectedItem.ToString()
	$Category = $DropDown2.SelectedItem.ToString()
	$Function = $DropDown3.SelectedItem.ToString()

	# Set SMS data as TS variables
	
	$TSEnv.Value("OSDDepartment") = "$Department"
	$TSEnv.Value("OSDCategory") = "$Category"
	$TSEnv.Value("OSDFunction") = "$Function"
	$TSEnv.Value("OSDComputerDescription") = "$Department - $Category - $Function"
	
		# The PC name needs to be saved to a file and called later. This is because if it is an unknown PC it will overwrite the variable with a blank name if the option is ignored when starting the imaging process.
		Add-Content "X:\Windows\Temp\ComputerName.txt" "$ComputerName" -Force
	
	# Run DiskPart if the tickbox is checked
	If ($checkBox1.Checked) { 

	Diskpart.exe /s X:\Windows\System32\Clean_Disk_0.txt

		}
	
	# Set variable to clear all direct deployments if the tickbox is NOT checked
	If (($checkBox2.Checked) -eq $False) { 

	$TSEnv.Value("SMSTS_ClearDeployments") = "True"

		}
		
	# Set variable to configure the PC as autologon if the tickbox is checked
	If ($checkBox3.Checked) { 

	$TSEnv.Value("IS_AUTOLOGON") = "True"

		}

    # Disconnect mapped drives
    net use "" /delete /yes <# DATA_REQUIRED : Network path where tag csv files are stored #>
    net use L: /delete /yes
	
	# Close form when work is complete
	$Form.close()

			}

# Form Building

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Form = New-Object System.Windows.Forms.Form
$Form.width = 385
$Form.height = 360
$Form.Text = ”Computer Configuration”
$Form.StartPosition = "CenterScreen"
$Form.ControlBox = $false

# DropDown Values

$Department = Get-Content "" <# DATA_REQUIRED : Network path to specific csv file #>
$Category = Get-Content "" <# DATA_REQUIRED : Network path to specific csv file #>

[array]$DropDownArray1 = $Department
[array]$DropDownArray2 = $Category

# Function to populate the Function dropdown based on the selection in the Category dropdown
Function Populate-DropDown{

    $DropDown3.Items.Clear()
    $CurrentCategory = $DropDown2.SelectedItem
    [array]$FunctionList = Get-Content "" <# DATA_REQUIRED : Network path to specific csv file #>
    ForEach ($Function in $FunctionList) { [void] $DropDown3.Items.Add($Function) }
	
}

# Form Building - Wrap in function

Function LaunchGUI {

# Form Building - Add Text Boxes

$TextBox1 = New-Object System.Windows.Forms.TextBox
$TextBox1.Location = New-Object System.Drawing.Size(130,35)
$TextBox1.Size = New-Object System.Drawing.Size(220,30)
$TextBox1.Text = ($TSEnv.Value("OSDComputerName"))

$Form.Controls.Add($Textbox1)

$TextBox1label = new-object System.Windows.Forms.Label
$TextBox1label.Location = new-object System.Drawing.Size(10,38)
$TextBox1label.size = new-object System.Drawing.Size(100,20)
$TextBox1label.Text = "Computer Name"
$Form.Controls.Add($Textbox1label)

# Form Building - Add DropDown Boxes

$DropDown1 = New-Object System.Windows.Forms.ComboBox
$DropDown1.Location = New-Object System.Drawing.Size(130,65)
$DropDown1.Size = New-Object System.Drawing.Size(220,30)

ForEach ($Item in $DropDownArray1) {
    $DropDown1.Items.Add($Item) | Out-Null
}

$Form.Controls.Add($DropDown1)

$DropDown1Label = New-Object System.Windows.Forms.Label
$DropDown1Label.Location = New-Object System.Drawing.Size(10,68)
$DropDown1Label.Size = New-Object System.Drawing.Size(100,20)
$DropDown1Label.Text = "Department"
$Form.Controls.Add($DropDown1Label)

$DropDown2 = New-Object System.Windows.Forms.ComboBox
$DropDown2.Location = New-Object System.Drawing.Size(130,95)
$DropDown2.Size = New-Object System.Drawing.Size(220,30)

ForEach ($Item in $DropDownArray2) {
    $DropDown2.Items.Add($Item) | Out-Null
}

$Form.Controls.Add($DropDown2)

$DropDown2Label = new-object System.Windows.Forms.Label
$DropDown2Label.Location = new-object System.Drawing.Size(10,98)
$DropDown2Label.size = new-object System.Drawing.Size(100,30)
$DropDown2Label.Text = "Category"
$Form.Controls.Add($DropDown2Label)

$DropDown3 = New-Object System.Windows.Forms.ComboBox
$DropDown3.Location = New-Object System.Drawing.Size(130,125)
$DropDown3.Size = New-Object System.Drawing.Size(220,30)

$DropDown2.Add_SelectedIndexChanged({Populate-DropDown}) 

$Form.Controls.Add($DropDown3)

$DropDown3Label = New-Object System.Windows.Forms.Label
$DropDown3Label.Location = New-Object System.Drawing.Size(10,128)
$DropDown3Label.Size = New-Object System.Drawing.Size(100,20)
$DropDown3Label.Text = "Function"
$Form.Controls.Add($DropDown3Label)

# Form Building - Add Tickbox Area

$checkBox1 = New-Object System.Windows.Forms.CheckBox
$checkBox1.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 130
$System_Drawing_Size.Height = 20
$checkBox1.Size = $System_Drawing_Size
$checkBox1.TabIndex = 0
$checkBox1.Text = "Clean Hard Drive"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 105
$System_Drawing_Point.Y = 170
$checkBox1.Location = $System_Drawing_Point
$checkBox1.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox1.Name = "checkBox1"

$form.Controls.Add($checkBox1)

$checkBox2 = New-Object System.Windows.Forms.CheckBox
$checkBox2.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 130
$System_Drawing_Size.Height = 20
$checkBox2.Size = $System_Drawing_Size
$checkBox2.TabIndex = 0
$checkBox2.Text = "In-Place Reimage"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 105
$System_Drawing_Point.Y = 200
$checkBox2.Location = $System_Drawing_Point
$checkBox2.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox2.Name = "checkBox2"

$checkBox3 = New-Object System.Windows.Forms.CheckBox
$checkBox3.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 150
$System_Drawing_Size.Height = 20
$checkBox3.Size = $System_Drawing_Size
$checkBox3.TabIndex = 0
$checkBox3.Text = "Configure As Autologon"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 105
$System_Drawing_Point.Y = 230
$checkBox3.Location = $System_Drawing_Point
$checkBox3.DataBindings.DefaultDataSourceUpdateMode = 0
$checkBox3.Name = "checkBox3"

$form.Controls.Add($checkBox3)

$form.Controls.Add($checkBox2)

# Form Building - Add Information Tooltip

$ToolTip1 = New-Object System.Windows.Forms.ToolTip
$ToolTip1.InitialDelay = 0 
$ToolTip1.AutoPopDelay = 30000
$ToolTipText = { Switch ($this.name) { "Information1"  {$tip = 

"Clean Hard Drive: 

If the hard drive is encrypted with a non-bitlocker solution or the task
sequence is being started from PE, select this option.

In-Place Reimage:

If the computer is having issues and needs to be reimaged, but will stay 
with the same user, select this option and it will retain all direct 
software deployments"
} } $tooltip1.SetToolTip($this,$tip) }

$Information1 = New-Object system.Windows.Forms.Label
$Information1.Image = [System.Drawing.SystemIcons]::Information
$Information1.Location = New-Object System.Drawing.Size(260,190)
$Information1.Size = New-Object System.Drawing.Size(42,42)
$Information1.name="Information1"
$Information1.add_MouseHover($ToolTipText)
$form.controls.add($Information1)

# Form Building - Add Buttons

$RunButton = new-object System.Windows.Forms.Button
$RunButton.Location = new-object System.Drawing.Size(125,265)
$RunButton.Size = new-object System.Drawing.Size(110,35)
$RunButton.Text = "Configure PC"
$RunButton.Add_Click({Invoke-Command -ScriptBlock $ScriptBlockRunButton})
$Form.DialogResult = "OK"

$form.Controls.Add($RunButton)

# Other Stuff

$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog() 

}

# Call The Function
$option = @()
$option = LaunchGUI