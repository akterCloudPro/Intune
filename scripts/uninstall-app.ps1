Get-WmiObject -Class Win32_Product | Select-Object -Property Name
$App = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -eq "Google Chrome"}
$App.Uninstall()
