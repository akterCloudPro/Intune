## Remediation script for DropBox
## Author: Akter Hossain
## Date: 22/11/2023

# Define the log file path, service name, detection file, uninstall file, app Id and Version etc
$logFilePath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DropBoxSvcRemediationLog.txt"
$serviceName = "DbxSvc"
$uninstallerPath = 'C:\Program Files (x86)\Dropbox\Client\DropboxUninstaller.exe'
$appId = '010a1e71-f77d-4cc2-b7ec-8d655b6f98a0'
$appVersion = '1'

## Function to record log message
function Log-Message {
    param (
        [string]$Message,
        [string]$LogFilePath =$LogFilePath
    )

    # Create the log file if not available
    if (!(Test-Path $LogFilePath)) {
        New-Item -Path $LogFilePath -ItemType File -Force
    }

    # Log the message to the file
    Add-Content -Path $LogFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

# Log the script's start
LogMessage "====== Script started ======"

## Function : to Check service status
function GetServiceStatus {
    param (
        [string]$serviceName
    )
    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop
        return $service.Status -eq "Running"
    }
    catch {
        return $false
    }
}

## Function :: Uninstalling service/application

function UninstallService {
    param (
        [string]$uninstallerPath,
        [string]$arguments
    )
   
    try {

if (Test-Path $uninstallerPath -PathType leaf) {
                Start-Process -FilePath $uninstallerPath -ArgumentList $arguments -Wait
                LogMessage "Uninstallation completed successfully."
            } else {

                LogMessage "Experiencing issues with uninstalling. Uninstaller not found at: $uninstallerPath"
            }
} catch {
    LogMessage "Failed to uninstall."
}

    }


## Function :: Remove targeted registry keys
function RemoveRegistryKey {
    param (
        [string]$appId,
        [string]$appVersion,
        [string]$registryPath
    )

    $targetAppID = "${appId}_${appVersion}"
    [string[]]$registryHives = @("HKLM:")

    foreach ($hive in $registryHives) {
        $registryPath = Join-Path -Path $hive -ChildPath ${registryPath}${targetAppID}

        if (Test-Path -Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force
            Write-Host "Registry key '$registryPath' deleted successfully."
        } else {
            Write-Host "Registry key '$registryPath' not found."
        }
    }
}


## Function :: Get GRS registry keys from IME logs
function GetGrsRegistryKey {
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
                        return $hash = ($Hash -split '=')[1].Trim()

                    }
                }
            }
        }
    }


## Log Initial Service Status
$isServiceRunning = GetServiceStatus $serviceName
if ($isServiceRunning) {
    $initialServiceStatusMessage = "$serviceName is initially running."
} else {
    $initialServiceStatusMessage = "$serviceName is initially stopped."
}
LogMessage $initialServiceStatusMessage


## Attempt to start the service if it is initially found not-started.

if(-Not ($isServiceRunning)){

    $attempts = 0
    $maxAttempts = 3
    $intervals = 60

    while ($attempts -lt $maxAttempts) {
        $attempts++
        LogMessage "Attempt $attempts to start $serviceName..."
        try {
            Start-Service -Name $serviceName
        }
        catch {
            LogMessage "Failed to start $serviceName."
        }

        Start-Sleep -Seconds $intervals

        if (IsServiceRunning $serviceName) {
            LogMessage "$serviceName is now running."
            break
        }
    }

    if (-Not(IsServiceRunning $serviceName)) {
        LogMessage "Service $serviceName failed to start after $attempts attempts. Uninstalling and then reinstalling..."
       
        try{
            ## Call the UninstallService function with  
            $uninstallerPath = 'C:\Program Files (x86)\Dropbox\Client\DropboxUninstaller.exe'
            if (Test-Path $uninstallerPath -PathType Leaf) {
                $arguments = /S
                UninstallService -uninstallerPath $uninstallerPath -arguments $arguments
            } else {
                LogMessage "Uninstaller not found at: $uninstallerPath"
            }
           
            ## Removing GRS keys from the registry
            $grsKey = GetGrsRegistryKey -appId $appId
            $grsKey = $grsKey + '=' #added '=' as a fallabck which was missed in the collected value  
            $grsRegistryPaths = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\*\GRS\*'

            foreach ($grsRegistryPath in $grsRegistryPaths) {
                 Get-ChildItem -Path $grsRegistryPath | Remove-Item -Include $grsKey
             }

            ## Removing appID from the registry
            $registryPath = 'HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\*\'
            RemoveRegistryKey -appId $appId -appVersion $appVersion -registryPath $registryPath

            # Restart IME Service
            Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service        
        } catch{
           LogMessage "The uninstallation of the service was not successful"  
        }

  }
   
  }
