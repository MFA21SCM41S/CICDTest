Param (
    [string] $orchestrator_url = "",
	[string] $orchestrator_tenant = "",
	[string] $project_path = "",
    [string] $input_path = "",
	[string] $testset = "",
	[string] $result_path = "",
    [string] $accountForApp = "",
    [string] $applicationId = "",
    [string] $applicationSecret = "",
    [string] $applicationScope = "",
    [string] $account_name = "",
	[string] $UserKey = "",
    [string] $orchestrator_user = "",
	[string] $orchestrator_pass = "",
	[string] $folder_organization_unit = "",
	[string] $language = "",
    [string] $environment = "",
    [string] $disableTelemetry = "",
    [string] $timeout = "",
    [string] $out = "",
    [string] $traceLevel = "",
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
$debugLog = "$scriptPath\orchestrator-test-run.log"

if($uipathCliFilePath -ne ""){
    $uipathCLI = "$uipathCliFilePath"
    if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
        WriteLog "UiPath cli file path provided does not exist in the provided path $uipathCliFilePath.`r`nDo not provide uipathCliFilePath parameter if you want the script to auto-download the cli from UiPath Public feed"
        exit 1
    }
} else {
    $cliVersion = "22.10.8438.32859";
    $uipathCLI = "$scriptPath\uipathcli\$cliVersion\tools\uipcli.exe"
    if (-not(Test-Path -Path $uipathCLI -PathType Leaf)) {
        WriteLog "UiPath CLI does not exist in this folder. Attempting to download it..."
        try {
            if (-not(Test-Path -Path "$scriptPath\uipathcli\$cliVersion" -PathType Leaf)){
                New-Item -Path "$scriptPath\uipathcli\$cliVersion" -ItemType "directory" -Force | Out-Null
            }
            Invoke-WebRequest "https://uipath.pkgs.visualstudio.com/Public.Feeds/_apis/packaging/feeds/1c781268-d43d-45ab-9dfc-0151a1c740b7/nuget/packages/UiPath.CLI.Windows/versions/$cliVersion/content" -OutFile "$scriptPath\\uipathcli\\$cliVersion\\cli.zip";
            Expand-Archive -LiteralPath "$scriptPath\\uipathcli\\$cliVersion\\cli.zip" -DestinationPath "$scriptPath\\uipathcli\\$cliVersion";
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
WriteLog "uipcli location :   $uipathCLI"

$ParamList = New-Object 'Collections.Generic.List[string]'

if($orchestrator_url -eq "" -or $orchestrator_tenant -eq "") {
    WriteLog "Fill the required parameters (orchestrator_url, orchestrator_tenant)"
    exit 1
}

if($accountForApp -eq "" -or $applicationId -eq "" -or $applicationSecret -eq "" -or $applicationScope -eq "") {
    if($account_name -eq "" -or $UserKey -eq "") {
        if($orchestrator_user -eq "" -or $orchestrator_pass -eq "") {
            WriteLog "Fill the required parameters (External App OAuth, API Access, or Username & Password)"
            exit 1
        }
    }
}

if($project_path -eq "" -and $testset -eq "") {
    WriteLog "Either TestSet or Project path is required to fill"
    exit 1
}

$ParamList.Add("test")
$ParamList.Add("run")
$ParamList.Add($orchestrator_url)
$ParamList.Add($orchestrator_tenant)

if($project_path -ne ""){
    $ParamList.Add("--project-path")
    $ParamList.Add($project_path)
}
if($input_path -ne ""){
    $ParamList.Add("--input_path")
    $ParamList.Add($input_path)
}
if($testset -ne ""){
    $ParamList.Add("--testset")
    $ParamList.Add($testset)
}
if($result_path -ne ""){
    $ParamList.Add("--result_path")
    $ParamList.Add($result_path)
}
if($accountForApp -ne ""){
    $ParamList.Add("--accountForApp")
    $ParamList.Add($accountForApp)
}
if($applicationId -ne ""){
    $ParamList.Add("--applicationId")
    $ParamList.Add($applicationId)
}
if($applicationSecret -ne ""){
    $ParamList.Add("--applicationSecret")
    $ParamList.Add($applicationSecret)
}
if($applicationScope -ne ""){
    $ParamList.Add("--applicationScope")
    $ParamList.Add("`"$applicationScope`"")
}
if($account_name -ne ""){
    $ParamList.Add("--accountName")
    $ParamList.Add($account_name)
}
if($UserKey -ne ""){
    $ParamList.Add("--token")
    $ParamList.Add($UserKey)
}
if($orchestrator_user -ne ""){
    $ParamList.Add("--username")
    $ParamList.Add($orchestrator_user)
}
if($orchestrator_pass -ne ""){
    $ParamList.Add("--password")
    $ParamList.Add($orchestrator_pass)
}
if($folder_organization_unit -ne ""){
    $ParamList.Add("--organizationUnit")
    $ParamList.Add($folder_organization_unit)
}
if($environment -ne ""){
    $ParamList.Add("--environment")
    $ParamList.Add($environment)
}
if($timeout -ne ""){
    $ParamList.Add("--timeout")
    $ParamList.Add($timeout)
}
if($out -ne ""){
    $ParamList.Add("--out")
    $ParamList.Add($out)
}
if($language -ne ""){
    $ParamList.Add("--language")
    $ParamList.Add($language)
}
if($traceLevel -ne ""){
    $ParamList.Add("--traceLevel")
    $ParamList.Add($traceLevel)
}
if($disableTelemetry -ne ""){
    $ParamList.Add("--disableTelemetry")
    $ParamList.Add($disableTelemetry)
}

$ParamMask = New-Object 'Collections.Generic.List[string]'
$ParamMask.AddRange($ParamList)

$secretIndex = $ParamMask.IndexOf("--password");
if($secretIndex -ge 0){
    $ParamMask[$secretIndex + 1] = ("*" * 15)
}
$secretIndex = $ParamMask.IndexOf("--token");
if($secretIndex -ge 0){
    $ParamMask[$secretIndex + 1] = $UserKey.Substring(0, [Math]::Min($UserKey.Length, 4)) + ("*" * 15)
}
$secretIndex = $ParamMask.IndexOf("--applicationId");
if($secretIndex -ge 0){
    $ParamMask[$secretIndex + 1] = $applicationId.Substring(0, [Math]::Min($applicationId.Length, 4)) + ("*" * 15)
}
$secretIndex = $ParamMask.IndexOf("--applicationSecret");
if($secretIndex -ge 0){
    $ParamMask[$secretIndex + 1] = ("*" * 15)
}

WriteLog "Executing $uipathCLI $ParamMask"
& "$uipathCLI" $ParamList.ToArray()

if($LASTEXITCODE -eq 0){
    WriteLog "Done!"
    Exit 0
} else {
    WriteLog "Unable to run the test. Exit code $LASTEXITCODE"
    Exit 1
}
