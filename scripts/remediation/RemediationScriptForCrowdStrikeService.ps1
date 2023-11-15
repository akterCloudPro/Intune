## Remediation script for CrowdStrike Service
## Author: Akter Hossain
## Date: 15/11/2023

# Define the log file path
$logFilePath = "C:\TempLogs\CrowdStrikeRemediationLog.txt"

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
$serviceName = "CrowdStrike Falcon Sensor Service"

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
            # Placeholder comment for service start execution
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

    # If the service still failed to start, uninstall and reinstall
    if (-Not (IsServiceRunning $serviceName)) {
        LogMessage "Service $serviceName failed to start after $attempts attempts. Uninstalling and reinstalling..."

        try {
            # Placeholder comment for stopping the service
            Stop-Service -Name $serviceName
        }
        catch {
            LogMessage "Failed to stop $serviceName. Error: $_"
        }

        try {
            # Uninstall Apps-Service
            ###########################################################################
            ##                                                                       ##
            ## Uninstallation codes will go here: v5.10.9106 and Later               ##
            ## CsUninstallTool.exe MAINTENANCE_TOKEN=a0c76aa097218dc446082 /quiet    ## 
            ##                                                                       ##  
            ## For v4.26.8904 and Earlier                                            ##
            ## CsUninstallTool.exe PW="Ex@mpl3" /quiet                               ##
            ##                                                                       ##  
            ###########################################################################
                        
            # Define the appID of the registry key to delete
            $targetAppID = "App ID will be placed here"
            [string[]]$registryHives = @("HKLM:")
            $modifiedTargetAppID = $targetAppID + "_1"

            # Iterate through each registry hive
            foreach ($hive in $registryHives) {
                # Construct the full registry path
                $registryPath = Join-Path -Path $hive -ChildPath "HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\*\$modifiedTargetAppID"

                # Check if the registry key exists
                if (Test-Path -Path $registryPath) {
                    # If it exists, delete the registry key and its subkeys recursively
                    Remove-Item -Path $registryPath -Recurse -Force
                    LogMessage "Registry key '$registryPath' deleted successfully."
                } else {
                    LogMessage "Registry key '$registryPath' not found."
                }
            }


        }
        catch {
            LogMessage "Failed to uninstall $serviceName . Error: $_"
        }

         # Restart the IME Service
            Get-Service -DisplayName "Microsoft Intune Management Extension" | Restart-Service 

        LogMessage "$serviceName has been uninstalled and reinstalled."
    }
}

# Log the script's completion
LogMessage "Script completed."

