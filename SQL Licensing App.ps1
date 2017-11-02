. "C:\users\aowens\desktop\SQL Licensing Project\get_sqlversion.ps1"
. "C:\users\aowens\desktop\SQL Licensing Project\get_filename.ps1"
. "C:\users\aowens\desktop\SQL Licensing Project\get_savelocation.ps1"
#ERASE ALL THIS AND PUT XAML BELOW between the @" "@ 
$inputXML = @"
<Window x:Class="WpfApplication1.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication1"
        mc:Ignorable="d"
        Title="NVA Microsoft SQL Licensing Report" Height="514.23" Width="690.582">
    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="23*"/>
            <ColumnDefinition Width="24*"/>
        </Grid.ColumnDefinitions>
        <Image x:Name="image" HorizontalAlignment="Left" Height="120" Margin="147,35,0,0" VerticalAlignment="Top" Width="365" RenderTransformOrigin="0.5,0.5" Source="C:\users\aowens\desktop\SQL Licensing Project\nva logo 150dpi.jpg" Grid.ColumnSpan="2">
            <Image.RenderTransform>
                <TransformGroup>
                    <ScaleTransform/>
                    <SkewTransform/>
                    <RotateTransform Angle="0.055"/>
                    <TranslateTransform/>
                </TransformGroup>
            </Image.RenderTransform>
        </Image>
        <TextBlock x:Name="textBlock" HorizontalAlignment="Left" Margin="156,167,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Height="30" Width="349" TextAlignment="Center" Text="Choose 'Start' then navigate to the list of computers to audit:" Grid.ColumnSpan="2"/>
        <Button x:Name="button" Content="Start" HorizontalAlignment="Left" Margin="249,202,0,0" VerticalAlignment="Top" Width="75" RenderTransformOrigin="-2.354,2.994"/>
        <ListView x:Name="listView" HorizontalAlignment="Left" Height="230" Margin="12,240,0,0" VerticalAlignment="Top" Width="651" Grid.ColumnSpan="2">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="Computer Name" DisplayMemberBinding ="{Binding 'ComputerName'}" Width="200"/>
                    <GridViewColumn Header="#Cores" DisplayMemberBinding ="{Binding 'Cores'}" Width="50"/>
                    <GridViewColumn Header="SQL Version Installed" DisplayMemberBinding ="{Binding 'SQLVersionInstalled'}" Width="400"/>
                </GridView>
            </ListView.View>
        </ListView>
        <Button x:Name="button1" Content="Export..." Grid.Column="1" HorizontalAlignment="Left" Margin="10,202,0,0" VerticalAlignment="Top" Width="75"/>
        <TextBlock x:Name="ExportError1" Grid.Column="1" HorizontalAlignment="Left" Height="20" Margin="96,204,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="226" Text="No file to export! Start audit first!" Foreground="Red" Visibility="Hidden"/>
    </Grid>
</Window>

"@ 

$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML

#Check for a text changed value (which we cannot parse)
If ($xaml.SelectNodes("//*[@Name]") | ? TextChanged){write-error "This Snippet can't convert any lines which contain a 'textChanged' property. `n please manually remove these entries"
        $xaml.SelectNodes("//*[@Name]") | ? TextChanged | % {write-warning "Please remove the TextChanged property from this entry $($_.Name)"}
return}

#Read XAML

    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    write-host $error[0].Exception.Message -ForegroundColor Red
    if ($error[0].Exception.Message -like "*button*"){
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"}
}
catch{#if it broke some other way :D
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
        }

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}

Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}

#Get-FormVariables

#===========================================================================
# Use this space to add code to the various form elements in your GUI
#===========================================================================

$WPFbutton.Add_Click({
$WPFExportError1.Visibility = 'Hidden'
if (($WPFlistView.Items).Count -gt 1) {
    ($WPFlistView.Items).Clear()
}
$Computers = Get-Content -Path (Get-FileName -ErrorAction SilentlyContinue) -ErrorAction SilentlyContinue
foreach ($Computer in $Computers) {
Get-SQLVersion -Computer $Computer | % {$WPFlistView.AddChild($_)}
}
})

$WPFbutton1.Add_Click({
if (($WPFlistView.Items).Count -eq 0) {
$WPFExportError1.Visibility = 'Visible'
}
else {
$WPFExportError1.Visibility = 'Hidden'
$Path = Get-SaveLocation
($WPFlistView.Items) | Export-Csv -Path $Path -ErrorAction SilentlyContinue
}
})
    
#Reference 

#Adding items to a dropdown/combo box
    #$vmpicklistView.items.Add([pscustomobject]@{'VMName'=($_).Name;Status=$_.Status;Other="Yes"})
    
#Setting the text of a text box to the current PC name    
    #$WPFtextBox.Text = $env:COMPUTERNAME
    
#Adding code to a button, so that when clicked, it pings a system
# $WPFbutton.Add_Click({ Test-connection -count 1 -ComputerName $WPFtextBox.Text
# })
#===========================================================================
# Shows the form
#===========================================================================
#write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | out-null