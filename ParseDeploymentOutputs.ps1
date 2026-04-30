# ParseDeploymentOutputs.ps1
# Parses Azure deployment outputs and sets them as GitHub Actions outputs

param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName
)

# Get deployment outputs
$deployment = az deployment sub show `
    --name $DeploymentName `
    --query properties.outputs `
    -o json | ConvertFrom-Json

# Extract web app name if it exists in outputs
if ($deployment.PSObject.Properties['webAppName']) {
    $webAppName = $deployment.webAppName.value
    Write-Host "WEB_APP_NAME=$webAppName"
    Write-Output "WEB_APP_NAME=$webAppName" >> $env:GITHUB_OUTPUT
}

# Extract SQL server name if it exists
if ($deployment.PSObject.Properties['sqlServerName']) {
    $sqlServerName = $deployment.sqlServerName.value
    Write-Host "SQL_SERVER_NAME=$sqlServerName"
    Write-Output "SQL_SERVER_NAME=$sqlServerName" >> $env:GITHUB_OUTPUT
}

# Extract SQL server FQDN
if ($deployment.PSObject.Properties['sqlServerFqdn']) {
    $sqlServerFqdn = $deployment.sqlServerFqdn.value
    Write-Host "SQL_SERVER_FQDN=$sqlServerFqdn"
    Write-Output "SQL_SERVER_FQDN=$sqlServerFqdn" >> $env:GITHUB_OUTPUT
}

# Extract database name
if ($deployment.PSObject.Properties['databaseName']) {
    $databaseName = $deployment.databaseName.value
    Write-Host "DATABASE_NAME=$databaseName"
    Write-Output "DATABASE_NAME=$databaseName" >> $env:GITHUB_OUTPUT
}

# Extract load testing resource name
if ($deployment.PSObject.Properties['loadTestingName']) {
    $loadTestingName = $deployment.loadTestingName.value
    Write-Host "LOAD_TESTING_NAME=$loadTestingName"
    Write-Output "LOAD_TESTING_NAME=$loadTestingName" >> $env:GITHUB_OUTPUT
}

Write-Host "Deployment outputs parsed successfully"
