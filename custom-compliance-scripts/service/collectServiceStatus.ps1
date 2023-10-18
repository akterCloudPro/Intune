$serviceName = "NaturalAuthentication"
$serviceExist = $false
$serviceRunning = $false

# Check if the service exists
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    # Get the service status
    $service = Get-Service -Name $serviceName
    $serviceExist = $true
    # Get the service status value as true (running) or false (not-running) based on the status code
    $serviceStatus = $service.Status
    if ($serviceStatus -eq '4') {
        $serviceRunning = $true
    } 
    else {
    $serviceRunning = $false 
} 
}
$output = @{ "NaturalAuthentication Service running" = $serviceRunning; "NaturalAuthentication Service Available"= $serviceExist}
return $output | ConvertTo-Json -Compress
