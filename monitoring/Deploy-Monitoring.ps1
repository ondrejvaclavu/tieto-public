#requires -version 2

<#
.SYNOPSIS

    Azure Managed Framework - deployment script

.DESCRIPTION

    This script deploys Tieto Azure Managed framework for monitoring

.PARAMETER Environment
    Specify customer or test environment

.PARAMETER TemplatePath
    Specify path to folder with templates and parameter files

.PARAMETER TemplateFile
    Specify template file name

.PARAMETER ParameterFile
    Specify parameter file name

.PARAMETER AlertsTemplateFile
    Used only if -AlertsOnly is enabled. Specify a custom alerts template file.

.PARAMETER EnvironmentConfigFile
    Specify environment configuration file name

.PARAMETER DeleteExistingConfiguration
    Define if existing configuration should be deleted before deployment

.PARAMETER AlertsOnly
    Deploy only alert rules and action groups to an existing environment.

.INPUTS

None

.OUTPUTS

None


.NOTES

  Version:        1.0

  Author:         Ondrej Vaclavu

  Creation Date:  6/6/2019

.EXAMPLE

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [string]
    $Environment,

    [Parameter(Mandatory = $false)]
    [string]
    $EnvironmentConfigFile = "environmentsConfig.json",

    [Parameter(Mandatory = $false)]
    [string]
    $TemplatePath = "https://tmfw-functions.azurewebsites.net/getgithubrepo/1a67d82b2828207e5b3642cfd09cf29f08ae82a7/tieto-public-cloud/azure-managed-framework/master/monitoring",

    [Parameter(Mandatory = $false)]
    [string]
    $TemplateFile = "azuredeploy.json",
    
    [Parameter(Mandatory = $false)]
    [string]
    $ParameterFile = "azuredeploy.parameters.json",

    [Parameter(Mandatory = $false)]
    [string]
    $AlertsTemplateFile = "alerts/monitoring-logalerts.json",

    [Parameter(Mandatory = $false)]
    [switch]
    $DeleteExistingConfiguration,

    [Parameter(Mandatory = $false)]
    [switch]
    $EnableDiagnosticSettings,

    [Parameter(Mandatory = $false)]
    [switch]
    $AlertsOnly
)

# Read environment configuration file
$parameters = Invoke-RestMethod -Uri "$TemplatePath\$EnvironmentConfigFile"

# Read config for specified environment
$envConfig = $parameters.environments | where-object {$_.name -like $Environment}

# Set variables based on config parameters
if ($envConfig.name.count -eq 1) {
    $subscriptionName = $envConfig.subscriptionName
    $resourceGroupName = $envConfig.resourceGroupName
    $resourceGroupLocation = $envConfig.resourceGroupLocation
    if ($envConfig.alertsTemplateFile) {$alertsTemplateFile = $envConfig.alertsTemplateFile}
    if ($envConfig.templateFile) {$templateFile = $envConfig.templateFile}
    if ($envConfig.parameterFile) {$parameterFile = $envConfig.parameterFile}
} else {
    Write-Error "Unknown environment specified." -ErrorAction Stop
}

# Set template URI variables
if ($AlertsOnly) {
    $templateUri = "$templatePath/$alertsTemplateFile"
} else {
    $templateUri = "$templatePath/$templateFile"
}
$templateParameterUri = "$templatePath/$parameterFile"

# Read additional parameters from template parameter file
$templateParams = Invoke-RestMethod -Uri $templateParameterUri
$workspaceName = $templateParams.parameters.workspaceName.value
if ($templateParams.parameters.enabledSolutions.value) {
    $enabledSolutions = $templateParams.parameters.enabledSolutions.value
} else {
    $enabledSolutions = @("all")
}

# Invoke login screen in case subcription is not accessible using current account
try {
    Get-AzSubscription -SubscriptionName $subscriptionName -ErrorAction Stop
}
catch {
    Connect-AzAccount
}

# Set context to specified subscription
if ((Get-AzContext).Subscription.Name -ne $subscriptionName) {
    Set-AzContext -SubscriptionName $subscriptionName
}

# Create a resource group if not exists
Get-AzResourceGroup -Name $resourceGroupName -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent)
{
    New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}

# Enables diagnostic settings on all resources for specified solution
if ($EnableDiagnosticSettings) {
    $workspace = Get-AzOperationalInsightsWorkspace -Name $workspaceName -ResourceGroupName $resourceGroupName
    if (($enabledSolutions -contains "azuresql-basic") -or ($enabledSolutions -contains "all")) {
        Get-AzResource -ResourceType "Microsoft.Sql/servers/databases" | Set-AzDiagnosticSetting -Enabled $true -Name "tm-diagnostics" -WorkspaceId $workspace.ResourceId -MetricCategory "Basic"
        Get-AzResource -ResourceType "Microsoft.Sql/servers/elasticpools" | Set-AzDiagnosticSetting -Enabled $true -Name "tm-diagnostics" -WorkspaceId $workspace.ResourceId -MetricCategory "Basic"
    }
}

# Delete previous configuration if specified
if ($DeleteExistingConfiguration) {
    # Delete alert rules
    $deleteAlertsActivity = "Deleting existing alert rules"
    Write-Progress -Activity $deleteAlertsActivity
    $alertRules = Get-AzScheduledQueryRule -ResourceGroupName $resourceGroupName -WarningAction SilentlyContinue
    for ($i = 0; $i -le $alertRules.count-1; $i++) {
        $percentComplete = ([Math]::Round(($i+1)/$alertRules.count*100))
        Write-Progress -Activity $deleteAlertsActivity -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
        Remove-AzScheduledQueryRule -ResourceId $alertRules[$i].Id -WarningAction SilentlyContinue
    }
    Write-Progress -Activity $deleteAlertsActivity -Status "Ready" -Completed

    # Delete action groups
    $deleteActionsActivity = "Deleting existing action groups"
    Write-Progress -Activity $deleteActionsActivity
    $actionGroups = Get-AzActionGroup -ResourceGroupName $resourceGroupName -WarningAction SilentlyContinue
    for ($i = 0; $i -le $actionGroups.count-1; $i++) {
        $percentComplete = ([Math]::Round(($i+1)/$actionGroups.count*100))
        Write-Progress -Activity $deleteActionsActivity -Status "$percentComplete% Complete:" -PercentComplete $percentComplete
        Remove-AzActionGroup -ResourceId $actionGroups[$i].Id -WarningAction SilentlyContinue
    }
    Write-Progress -Activity $deleteActionsActivity -Status "Ready" -Completed
}

# Start the deployment
$deployActivity = "Deploying template"
Write-Progress -Activity $deployActivity
try {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateUri $templateUri -TemplateParameterUri $templateParameterUri
}
catch {
    Write-Host "Template deployment failed:"
    Write-Error $_ -ErrorAction Stop
}
Write-Progress -Activity $deployActivity -Status "Ready" -Completed
Write-Host "Template has been successfully deployed."