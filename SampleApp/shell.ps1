clear

Push-Location (Split-Path -parent $MyInvocation.MyCommand.path)

$xml = [xml](Get-Content "shell.settings")

if((get-module | where{$_.name -eq "PowerDeploy"} | Measure-Object).Count -gt 0)
{
    Remove-Module PowerDeploy
}

#if((get-module | where{$_.name -eq "PowerDeplo.Extensions"} | Measure-Object).Count -gt 0)
#{
#    Remove-Module PowerDeploy.Extensions
#}

Import-Module (Join-Path $xml.config.PowerDeployInstallDir "PowerDeploy.psm1") -DisableNameChecking

$config = @{
	ProjectDir = Resolve-Path $xml.config.ProjectDir;
	PowerDeployInstallDir = Resolve-Path $xml.config.PowerDeployInstallDir;
	update = $xml.config.update
}

$powerdeploy.config = $config


Write-Host "__________                         ________                .__                "
Write-Host "\______   \______  _  __ __________\______ \   ____ ______ |  |   ____ ___.__."
Write-Host " |     ___/  _ \ \/ \/ // __ \_  __ \    |  \_/ __ \\____ \|  |  /  _ <   |  |"
Write-Host " |    |  (  <_> )     /\  ___/|  | \/    `   \  ___/|  |_> >  |_(  <_> )___  |"
Write-Host " |____|   \____/ \/\_/  \___  >__| /_______  /\___  >   __/|____/\____// ____|"
Write-Host "                            \/             \/     \/|__|               \/     "
Write-Host "                                                             by tobias zürcher"
Write-Host ""

Show-PowerDeployHelp

Write-Host ""

#TODO: maybe show available packages/environments

Initialize-PowerDeploy $powerdeploy.config.ProjectDir

$Host.UI.RawUI.WindowTitle = "PowerDeploy for project " + $powerdeploy.project.id + " in $($powerdeploy.config.ProjectDir)"

# create some nice aliases
Set-Alias Build Invoke-Build -Scope Global -Force
Set-Alias b Invoke-Build -Scope Global -Force

Set-Alias Prepare Prepare-DeploymentUnit -Scope Global -Force
Set-Alias p Prepare-DeploymentUnit -Scope Global -Force

Set-Alias Configure Configure-Environment -Scope Global -Force
Set-Alias Config Configure-Environment -Scope Global -Force
Set-Alias c Configure-Environment -Scope Global -Force

Set-Alias Deploy Invoke-Deploy -Scope Global -Force
Set-Alias d Invoke-Deploy -Scope Global -Force

Set-Alias op Open-ProjectDir -Scope Global -Force

Set-Alias Help Show-PowerDeployHelp -Scope Global -Force