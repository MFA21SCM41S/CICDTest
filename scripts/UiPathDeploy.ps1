Param (
    [string] $packages_path = "",
    [string] $orchestrator_url = "https://cloud.uipath.com/manansorganization/",
    [string] $orchestrator_tenant = "DefaultTenant",
    [string] $account_name = "Test11",
    [string] $client_id = "24fe29d0-1b3b-4a9f-bea0-ba52162ebb66",
    [string] $client_secret = "ymJgyFxJa31D*Mxc",
    [string] $folder_organization_unit = "",
    [string] $language = "",
    [string] $entryPoints = "",
    [string] $disableTelemetry = "",
    [string] $uipathCliFilePath = ""
)

function WriteLog {
    Param ($message, [switch] $err)
    $now = Get-Date -Format "G"
    $line = "$now`t$message"
    $line | Add-Content $debugLog -Encoding UTF8
    if ($err) {
        Write-Host $line -ForegroundColor red
    } else {
        Write-Host $line
    }
}

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$debugLog = "$scriptPath\orchestrator-package-deploy.log"

if ($uipathCliFilePath -ne "") {
    $uipathCLI = "$uipathCliFilePath"
    if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
        WriteLog "UiPath cli file path provided does not exist in the provided path $uipathCliFilePath.`r`nDo not provide uipathCliFilePath parameter if you want the script to auto download the cli from UiPath Public feed"
        exit 1
    }
} else {
    $cliVersion = "22.10.8438.32859"
    $uipathCLI = "$scriptPath\uipathcli\$cliVersion\tools\uipcli.exe"
    
    if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
        WriteLog "UiPath CLI does not exist in this folder. Attempting to download it..."
        try {
            if (-not(Test-Path -Path "$scriptPath\uipathcli\$cliVersion" -PathType Leaf)){
                New-Item -Path "$scriptPath\uipathcli\$cliVersion" -ItemType "directory" -Force | Out-Null
            }
            Invoke-WebRequest "https://uipath.pkgs.visualstudio.com/Public.Feeds/_apis/packaging/feeds/1c781268-d43d-45ab-9dfc-0151a1c740b7/nuget/packages/UiPath.CLI.Windows/versions/$cliVersion/content" -OutFile "$scriptPath\\uipathcli\\$cliVersion\\cli.zip"
            Expand-Archive -LiteralPath "$scriptPath\\uipathcli\\$cliVersion\\cli.zip" -DestinationPath "$scriptPath\\uipathcli\\$cliVersion"
            WriteLog "UiPath CLI is downloaded and extracted in folder $scriptPath\uipathcli\\$cliVersion"
            
            if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
                WriteLog "Unable to locate UiPath CLI after it is downloaded."
                exit 1
            }
        }
        catch {
            WriteLog ("Error Occurred : " + $_.Exception.Message) -err $_.Exception
            exit 1
        }
    }
}

WriteLog "-----------------------------------------------------------------------------"
WriteLog "Orchestrator URL: $orchestrator_url"
WriteLog "Tenant: $orchestrator_tenant"
WriteLog "Account Name: $account_name"
WriteLog "Organization Unit: $folder_organization_unit"
WriteLog "uipcli location :   $uipathCLI"

$ParamList = @(
    "package", "deploy", $packages_path, $orchestrator_url, $orchestrator_tenant,
    # "--quiet",
    "-t", $client_secret, "-a", $client_id
)

if ($account_name -eq "") {
    $ParamList += @(
        "--accountName", $account_name, "--folder", $folder_organization_unit, "--lang", $language,
        "--entryPoints", $entryPoints, "--disableTelemetry", $disableTelemetry
    )
}

$ParamMask = $ParamList -join " "
WriteLog "Executing $uipathCLI $ParamMask"

try {
    Start-Process $uipathCLI -ArgumentList $ParamMask -Wait -NoNewWindow -PassThru
}
catch {
    WriteLog ("Error Occurred : " + $_.Exception.Message) -err $_.Exception
    exit 1
}

if ($LASTEXITCODE -eq 0) {
    WriteLog "Done!"
    exit 0
}
else {
    WriteLog "Unable to deploy the project. Exit code $LASTEXITCODE" -err
    exit $LASTEXITCODE
}
