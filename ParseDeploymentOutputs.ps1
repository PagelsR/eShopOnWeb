# ParseDeploymentOutputs.ps1
# Parses Azure deployment outputs and sets them as GitHub Actions outputs

param(
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

# Get deployment outputs
$deployment = az deployment group show `
    --name $DeploymentName `
    --resource-group $ResourceGroupName `
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

# Extract catalog database name
if ($deployment.PSObject.Properties['AZURE_SQL_CATALOG_DATABASE_NAME']) {
    $catalogDbName = $deployment.AZURE_SQL_CATALOG_DATABASE_NAME.value
    Write-Host "CATALOG_DB_NAME=$catalogDbName"
    Write-Output "CATALOG_DB_NAME=$catalogDbName" >> $env:GITHUB_OUTPUT
}

# Extract identity database name
if ($deployment.PSObject.Properties['AZURE_SQL_IDENTITY_DATABASE_NAME']) {
    $identityDbName = $deployment.AZURE_SQL_IDENTITY_DATABASE_NAME.value
    Write-Host "IDENTITY_DB_NAME=$identityDbName"
    Write-Output "IDENTITY_DB_NAME=$identityDbName" >> $env:GITHUB_OUTPUT
}

Write-Host "Deployment outputs parsed successfully"
