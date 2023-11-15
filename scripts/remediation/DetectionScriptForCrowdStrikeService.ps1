## Detection script for CrowdStrike Service
## Author: Akter Hossain
## Date: 15/11/2023

# Define the service name
$serviceName = "CrowdStrike Falcon Sensor Service"

# Check if the service exists
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    # Service exists, check if it is running
    $serviceStatus = (Get-Service -Name $serviceName).Status
    
    if ($serviceStatus -eq 'Running') {
        Write-Host "$serviceName is running."
        # Return Exit Code 0 (success)
        exit 0
    }
    else {
        Write-Host "$serviceName is not running."
        # Return Exit Code 1 (failure)
        exit 1
        Break
    }
}
else {
    Write-Host "$serviceName does not exist."
    # Return Exit Code 1 (failure)
    exit 1
    Break
}
