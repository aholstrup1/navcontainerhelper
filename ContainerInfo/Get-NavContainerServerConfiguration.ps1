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
        $config = Get-NavServerInstance | Get-NAVServerConfiguration -AsXml
        $object = [ordered]@{ "ContainerName" = $ContainerName }
        if ($config) {
            $Config.configuration.appSettings.add | ForEach-Object{
                Write-Host "Key: $($_.Key) Value: $($_.Value)"
                $object += @{ "$($_.Key)" = $_.Value }
            }
        }
        else {
            Write-Host "No configuration found for container $ContainerName."
            $object += @{ "ServerInstance" = "" }
        }
        $object | ConvertTo-Json -Depth 99 -compress
    } -argumentList $containerName | ConvertFrom-Json

    Write-Host "ServerConfig: $($serverConfig | Out-String)"
    return $serverConfig
}
Set-Alias -Name Get-NavContainerServerConfiguration -Value Get-BcContainerServerConfiguration
Export-ModuleMember -Function Get-BcContainerServerConfiguration -Alias Get-NavContainerServerConfiguration
