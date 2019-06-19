# Monitoring framework

## Documentation
Links to existing documentation here

## Framework description
Monitoring framework deploys the following resources:

- Log Analytics workspace
- Automation account
- Update management solution
- Performance counters collection for Windows and Linux VMs
- Alert rules for defined solutions
- Action groups
    - ServiceNow integration
    - Email to distribution list

## Monitoring framework deployment
Use **Deploy to Azure** button to deploy monitoring framework.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fondrejvaclavu%2Ftieto-public%2Fmaster%2Fmonitoring%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>

### Scripted deployment
#### Prerequisites
-   Azure Az PowerShell

#### Add customer environment
Edit environmentsConfig.json file and add the customized following code:
```json
{
    "name" : "SomeShortName",
    "subscriptionName" : "Subscription name",
    "resourceGroupName" : "some-rg",
    "workspaceName" : "some-workspace",
    "enabledSolutions" : ["solution1","solution2"]
}
```

#### Deployment script
```powershell
Deploy-Monitoring.ps1 -Environment <Environment name> [-DeleteExistingConfiguration] [-EnableDiagnosticSettings] [-AlertsOnly]
```
#### Deployment instructions
Run Deploy-Monitoring.ps1 script with the following parameters:
```powershell
Deploy-Monitoring.ps1 -Environment <environment name>
```
If you want to delete existing alert rules and action groups, add -DeleteExistingConfiguration parameter, e.g.:
```powershell
Deploy-Monitoring.ps1 -Environment <environment name> -DeleteExistingConfiguration
```

## Alerts and action groups - Standalone deployment
Deploys alert rules and action groups to an existing environment.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Ftmfw-functions.azurewebsites.net%2Fgetgithubrepo%2F1a67d82b2828207e5b3642cfd09cf29f08ae82a7%2Ftieto-public-cloud%2Fazure-managed-framework%2Fmaster%2Fmonitoring%2Falerts%2Fmonitoring-logalerts.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>

#### Deployment instructions
Run Deploy-Monitoring.ps1 script with the following parameters:
```powershell
Deploy-Monitoring.ps1 -Environment <environment name> -AlertsOnly
```

## Known limitations
-	Currently only one action group per action rule is supported
-   Diagnostics settings are automatically enabled only for resources located in the subscription with monitoring framework.
