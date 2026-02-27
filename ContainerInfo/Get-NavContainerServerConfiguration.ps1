<# 
 .Synopsis
  Retrieve the Server configuration from a NAV/BC Container as a powershell object
 .Description
  Returns all the settings of the middletier from a container.
 .Parameter containerName
  Name of the container for which you want to get the server configuration
 .Example
  Get-BcContainerServerConfiguration -ContainerName "MyContainer"
#>
Function Get-BcContainerServerConfiguration {
    Param (
        [String] $ContainerName = $bcContainerHelperConfig.defaultContainerName
    )
    Write-Host "Getting server configuration for container: $ContainerName"

    $serverConfig = Invoke-ScriptInBcContainer -containerName $containerName -ScriptBlock{ Param($ContainerName)
        
        # Check if BC service is running
        $service = Get-Service -Name "MicrosoftDynamicsNavServer`$*" -ErrorAction SilentlyContinue
        if ($service) {
            Write-Host "BC Service(s) found:"
            $service | ForEach-Object { Write-Host "  Name: $($_.Name) Status: $($_.Status) StartType: $($_.StartType)" }
        }
        else {
            Write-Host "WARNING: No BC service found!"
        }
        
        # Get server instances with detailed info
        Write-Host "Calling Get-NavServerInstance..."
        $serverInstances = @(Get-NavServerInstance)
        Write-Host "Get-NavServerInstance returned $($serverInstances.Count) instance(s)"
        if ($serverInstances.Count -gt 0) {
            $serverInstances | ForEach-Object { 
                Write-Host "  ServerInstance: $($_.ServerInstance) State: $($_.State) Version: $($_.Version)"
            }
        }
        else {
            Write-Host "WARNING: Get-NavServerInstance returned NO instances!"
            Write-Host "BC processes running:"
            Get-Process -Name "Microsoft.Dynamics.Nav.Server" -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Host "  PID: $($_.Id) StartTime: $($_.StartTime) CPU: $($_.CPU)"
            }
            if (-not (Get-Process -Name "Microsoft.Dynamics.Nav.Server" -ErrorAction SilentlyContinue)) {
                Write-Host "  No BC server process running!"
            }
        }
        
        $config = $serverInstances | Get-NAVServerConfiguration -AsXml
        $object = [ordered]@{ "ContainerName" = $ContainerName }
        if ($config) {
            $configCount = ($Config.configuration.appSettings.add | Measure-Object).Count
            Write-Host "NAVServerConfiguration returned $configCount settings"
            $Config.configuration.appSettings.add | ForEach-Object{
                $object += @{ "$($_.Key)" = $_.Value }
            }
        }
        else {
            Write-Host "WARNING: No configuration returned from Get-NAVServerConfiguration!"
            $object += @{ "ServerInstance" = "" }
        }
        $object | ConvertTo-Json -Depth 99 -compress
    } -argumentList $containerName | ConvertFrom-Json

    if ($null -eq $serverConfig) {
        Write-Host "WARNING: Get-BcContainerServerConfiguration returning null! Invoke-ScriptInBcContainer produced no parseable output."
    }
    else {
        Write-Host "Get-BcContainerServerConfiguration returning config with ServerInstance=$($serverConfig.ServerInstance)"
    }
    return $serverConfig
}
Set-Alias -Name Get-NavContainerServerConfiguration -Value Get-BcContainerServerConfiguration
Export-ModuleMember -Function Get-BcContainerServerConfiguration -Alias Get-NavContainerServerConfiguration
