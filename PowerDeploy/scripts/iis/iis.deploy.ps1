[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$WebsiteName,
    
    [Parameter(Mandatory = $true, Position = 2)]
    [string]$WebsitePhysicalPath,

    [Parameter(Mandatory = $true, Position = 3)]
    [string]$AppPoolName,

    [Parameter(Mandatory = $true, Position = 4)]
    [string]$AppPoolUser,

    [Parameter(Mandatory = $true, Position = 5)]
    [string]$AppPoolPass,

    [Parameter(Mandatory = $true, Position = 6)]
    [string]$AppName,

    [Parameter(Mandatory = $false, Position = 7)]
    [string]$AppPhysicalPath,
    
    [Parameter(Mandatory = $false, Position = 8)]
    [string]$WebSiteRoot,

    [Parameter(Mandatory = $true, Position = 9)]
    [string]$PackagePath
)

$script:ErrorActionPreference = "Stop"

#$WebsiteName = "Test"
#$WebsitePhysicalPath = "C:\temp\xxx"
#$AppPoolName = "TestAppPool"
#$AppPoolUser = "deployer"
#$AppPoolPass = "testtest1234!"
#
#$AppName = "vdir3"
#$AppPhysicalPath = "c:\temp\vdir"
#
##$WebsiteRoot = "/sub1/sub2"
#$WebSiteRoot = "/"
#
#$PackagePath = "\\localhost\packages\SampleAppWeb_1.0.0.99\"

#Write-Host "WebSite: $WebsiteName"
#Write-Host "WebsitePhysicalPath: $WebSitePhysicalPath"
#Write-Host "AppPoolName: $"

#$psboundparameters | ft auto

#exist   

function xmlPeek($filePath, $xpath)
{ 
    [xml] $fileXml = Get-Content $filePath 
    $found = $fileXml.SelectSingleNode($xpath)

    if ($found.GetType().Name -eq 'XmlAttribute') { return $found.Value }

    return $found.InnerText
} 

Push-Location (Split-Path $MyInvocation.MyCommand.Path –Parent)

Import-Module WebAdministration

$website_path       = "IIS:\Sites\$WebsiteName"
$pool_path          = "IIS:\AppPools\$AppPoolName"

$package_xml        = Join-Path $PackagePath "package.xml"
$package_id         = xmlPeek $package_xml "package/@id"
$package_version    = xmlPeek $package_xml "package/@version"
$package_zip        = Join-Path $PackagePath "package.zip"

$target_folder_name = "{0}_v{1}" -f $package_id,$package_version

# create app pool if not existing
if ((Test-Path $pool_path) -eq $false)
{
    Write-Host "AppPool $AppPoolName not found, creating it with user $AppPoolUser"
    New-WebAppPool "$AppPoolName" | Out-Null

    Set-ItemProperty "$pool_path" -name processModel -value @{ userName = "$AppPoolUser"; password = "$AppPoolPass"; identitytype = 3 }
    Set-ItemProperty "$pool_path" -name managedRuntimeVersion -value v4.0 # TODO: pass .NET version
}

# create web site if not existing
if ((Test-Path $website_path) -eq $false)
{
    if ((Test-Path "$WebSitePhysicalPath") -eq $false)
    {
        Write-Host "Creating physical $WebSitePhysicalPath path for Web Site $WebsiteName"
        New-Item -Path "$WebSitePhysicalPath" -type Directory | Out-Null
    }
    
    Write-Host "Creating Web Site $WebsiteName"
    New-WebSite -Name "$WebsiteName" -physicalPath "$WebsitePhysicalPath" | Out-Null # todo: port & host mapping
    
    Write-Host "Assigning AppPool $AppPoolName to the Web Site $WebsiteName"
    Set-ItemProperty $website_path -name applicationPool -value $AppPoolName | Out-Null
}
else
{
    Write-Host "Web Site $WebsiteName does already exist"
}

if ($WebsiteRoot -eq "/" -or $WebSiteRoot -eq $null -or $WebSiteRoot -eq "") {
    # deploy the package to the root of the website
    # example: $WebSiteRoot = C:\inetpub\Website
    #
    # it copies the package to $WebSiteRoot\%PackageName%_%Version% and map the Website to the folder.
    # 
    # Example:
    # C:\inetpub\Website\Website_v1.0.0
    # C:\inetpub\Website\Website_v1.1.0
    #
    # The deployment process for "Root-Website"-Deployments just copies the package to the $WebsiteRoot 
    # and maps the WebSite to this folder.

    $target_path = Join-Path $WebsitePhysicalPath $target_folder_name

    Write-Host "Unzipping $package_zip to $target_path"

    .\7za.exe x "-o$($target_path)" "$package_zip" -aoa | Out-Null

    Write-Host "Update Web Site path to $target_path"
    Set-ItemProperty $website_path -name physicalPath -value "$target_path"

    # TODO: implement cleanup of older versions (for example leave last 5 versions)
    # http://stackoverflow.com/questions/10539311/keep-x-number-of-directories-and-delete-all-others-need-to-exclude-one-director
}
else
{
    # lets deploy in a more complex scenario

    # example:
    #  WebSiteName:         Default Web Site
    #  WebsitePhysicalPath: c:\inetpub\root
    #  WebsiteRoot:         "sub1/sub2"
    #  AppName:             "app"
    #  AppPhysicalPath:     "c:\iis_apps\app\app_v1.0"
    #
    # What happens:
    #  c:\inetpub\root\sub1\sub2 will be created physically. In this folder, it creates an WebApplication Named "app" pointing to "c:\iis_apps\app"
    # 
    # this lets you access your application with for example http://your-host/sub1/sub2/app

    $trimmed_website_root = $WebsiteRoot.Trim("/")

    Write-Host  "$WebsitePhysicalPath" "--- $trimmed_website_root"

    $path_to_vdir = Join-Path "$WebsitePhysicalPath" "$trimmed_website_root"

    if ((Test-Path $path_to_vdir) -eq $false)
    {
        New-Item -Path $path_to_vdir -Type Directory -Verbose
    }

    # unzip package to target path
    $target_path = Join-Path $AppPhysicalPath $target_folder_name
    .\tools\7za.exe x "-o$($target_path)" "$package_zip" -aoa | Out-Null

    # now we need to make sure that the web application points to the extracted path
    $site = "$WebsiteName/$trimmed_website_root"
    $web_app = Get-WebApplication -Site "$site" -ErrorAction "SilentlyContinue"

    # check wheter the web application is available: if not -> create web app, otherwhise just change the physical path mapping
    if ($web_app -eq $null)
    {
        Write-Host "Create new web application for $AppName with physical path $target_path in web site $site"
        New-WebApplication -Name "$AppName" -PhysicalPath "$target_path" -Site "$site"
    }
    else 
    {
        Write-Host "Update physical path of $site to $target_path"
        Set-ItemProperty "$site/$AppName" -name physicalPath -value "$target_path"
    }
}

Pop-Location