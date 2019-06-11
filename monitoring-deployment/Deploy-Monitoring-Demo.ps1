#requires -version 2

$subscriptionName = "Tieto Azure Public Cloud Operations Demo"
$resourceGroupName = "tm-demo-monitoring-rg"
$resourceGroupLocation = "West Europe"
$templateUri = "https://raw.githubusercontent.com/ondrejvaclavu/tieto-public/master/monitoring-deployment/azuredeploy.json"
$templateParameterUri = "https://raw.githubusercontent.com/ondrejvaclavu/tieto-public/master/monitoring-deployment/azuredeploy.parameters.json"

# Invoke login screen in case subcription is not accessible using current account
try {Get-AzSubscription -SubscriptionName $subscriptionName}
catch {Connect-AzAccount}

# Set context to specified subscription
if ((Get-AzContext).Subscription.Name -ne $subscriptionName) {
    Set-AzContext -SubscriptionName $subscriptionName
}

Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue

if ($notPresent)
{
    New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}

# Start the deployment
$deployActivity = "Deploying template"
Write-Progress -Activity $deployActivity
try {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParameterUri
}
catch {
    Write-Host "Template deployment failed:"
    Write-Error $_ -errorAction Stop
}
Write-Progress -Activity $deployActivity -Status "Ready" -Completed
Write-Host "Template has been successfully deployed."