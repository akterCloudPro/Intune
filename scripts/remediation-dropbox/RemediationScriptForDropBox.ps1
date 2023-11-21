## Remediation script for DropBox
## Author: Akter Hossain
## Date: 22/11/2023

# Define the log file path
$logFilePath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\DropBoxSvcRemediationLog.txt"

# Create the log file if not available
if (!(Test-Path $logFilePath))
{
   New-Item -path $logFilePath -Force
   
} 

# Function to log messages to the log file
function LogMessage($message) {
    Add-Content -Path $logFilePath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
}

# Log the script's start
LogMessage "Script started."

# Define the service name
$serviceName = "DbxSvc"

# Function to check if a service is running
function IsServiceRunning($name) {
    try {
        $service = Get-Service -Name $name -ErrorAction Stop
        if ($service.Status -eq "Running") {
            return $true
        } else {
            return $false
        }
    }
    catch {
        return $false
    }
}

# Log the initial service status
$initialServiceStatus = IsServiceRunning $serviceName
if ($initialServiceStatus) {
    $initialStatusMessage = "$serviceName is initially running."
} else {
    $initialStatusMessage = "$serviceName is initially stopped."
}
LogMessage $initialStatusMessage

# Check if the service is not running
if (-Not $initialServiceStatus) {
    $attempts = 0
    $maxAttempts = 3

    # Try to start the service up to the maximum number of attempts
    while ($attempts -lt $maxAttempts) {
        $attempts++
        LogMessage "Attempt $attempts to start $serviceName..."
        try {
            Start-Service -Name $serviceName
        }
        catch {
            LogMessage "Failed to start $serviceName. Error: $_"
        }

        # Wait for 1 minutes ( 60 X 1)
        Start-Sleep -Seconds 60

        if (IsServiceRunning $serviceName) {
            LogMessage "$serviceName is now running."
            break
        }
    }

    # If the service still fails to start, uninstall and then reinstall.

    if (-Not (IsServiceRunning $serviceName)) {
        LogMessage "Service $serviceName failed to start after $attempts attempts. Uninstalling and then reinstalling..."

        try {
            # Placeholder comment for stopping the service
            Stop-Service -Name $serviceName
        }
        catch {
            LogMessage "Failed to stop $serviceName. Error: $_"
        }

        try {
            ##### Uninstall Apps-Service ####
            ## Uninstall apps from the file locaton
            $installationLocation = 'C:\Program Files (x86)\Dropbox\Client\DropboxUninstaller.exe'

            if (Test-Path $installationLocation -PathType leaf) {
                Start-Process -FilePath $installationLocation -ArgumentList '/S' -Wait
            } else {
            
            }

            ## Function to find GRS ID from Intune Management Extension logs
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
                                return $hash = ($Hash -split '=')[1].Trim()

                            }
                        }
                    }
                }
            }

            ## Removing the GRS ID for the specified App ID from the registry
            $appId = '010a1e71-f77d-4cc2-b7ec-8d655b6f98a0'
            $appVersion = '1'
            $targetAppID = "${appId}_${appVersion}"
            $registryHive = "HKLM:"
            $backslash = '\'
            $grsID = FindGRS($appId)
            $targetGrsID = $grsID+'='
            $grsRegistryPaths = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\*\GRS\*'

            foreach ($grsRegistryPath in $grsRegistryPaths) {

            Get-ChildItem -Path $grsRegistryPath | Remove-Item -Include $targetGrsID
            
            }
            
        }
        catch {
            LogMessage "Failed to uninstall $serviceName . Error: $_"
        }

         # Restart the IME Service
        Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service 
        LogMessage "$serviceName has been uninstalled, and now there is an attempt to reinstall the application"
    }
}

# Log the script's completion
LogMessage "Script completed."

