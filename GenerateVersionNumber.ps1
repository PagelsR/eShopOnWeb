# GenerateVersionNumber.ps1
# Generates a version number based on date and build count

param(
    [string]$BuildNumber = "1"
)

$date = Get-Date -Format "yyyy.MM.dd"
$version = "$date.$BuildNumber"

Write-Output $version
