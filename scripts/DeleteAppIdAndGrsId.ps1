function FindGRS {
    param (
        [string]$appId
    )

    $intuneLogList = Get-ChildItem -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs" -Filter "IntuneManagementExtension*.log" -File | Sort-Object LastWriteTime -Descending | Select-Object -ExpandProperty FullName

    if (!$intuneLogList) {
        Write-Error "Unable to find any Intune log files. Redeploy will probably not work as expected."
        return
    }

    foreach ($intuneLog in $intuneLogList) {
        $appMatch = Select-String -Path $intuneLog -Pattern "\[Win32App\]\[GRSManager\] App with id: $appId is not expired." -Context 0, 1

        if ($appMatch) {
            foreach ($match in $appMatch) {
                $Hash = ""
                $LineNumber = $match.LineNumber
                $Hash = Get-Content $intuneLog | Select-Object -Skip $LineNumber -First 1

                if ($hash) {
                    $hash = $hash.Replace('+', '\+')
                    return $hash
                }
            }
        }
    }
}

$appId = '010a1e71-f77d-4cc2-b7ec-8d655b6f98a0'
$TargetGrsID = FindGRS($appId)

 # Iterate through each registry hive
 foreach ($hive in $registryHives) {
    # Construct the full registry path
    $registryAppPath = Join-Path -Path $hive -ChildPath "HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\*\$modifiedTargetAppID"
    $registryGRSPath = Join-Path -Path $hive -ChildPath "HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\*\GRS\$TargetGrsID"

    # Check if the registry app key exists
    if (Test-Path -Path $registryAppPath) {
        # If it exists, delete the registry key and its subkeys recursively
        Remove-Item -Path $registryAppPath -Recurse -Force
        LogMessage "Registry key '$registryAppPath' deleted successfully."
    } else {
        LogMessage "Registry key '$registryAppPath' not found."
    }

     # Check if the registry grs key exists
    if (Test-Path -Path $registryGRSPath) {
        # If it exists, delete the registry key and its subkeys recursively
        Remove-Item -Path $registryGRSPath -Recurse -Force
        LogMessage "Registry key '$registryGRSPath' deleted successfully."
    } else {
        LogMessage "Registry key '$registryGRSPath' not found."
    }
}
