# Blaise Azure DevOps Pipelines

We use Azure DevOps pipelines to build and deploy C# applications, and execute scripts on Windows VMs. Blaise is Windows based and provides a .NET Framework API. We provision VMs via GCP and install an Azure DevOps agent on them. This allows us to deploy our applications onto the VMs and execute any necessary scripts. We call the Azure DevOps pipelines from Concourse via an authenicated HTTPS request.

Azure DevOps is integrated with our GitHub repositories. Changes to the pipeline yaml configuration files in the repositories, will be reflected within Azure DevOps.

Some of the Azure DevOps pipeline yaml configuration files are stored in the repositories they relate to, such as the [rest-api]() and [nuget](). This resposotory stores Azure DevOps pipeline yaml configuration files that don't directly relate to a service, such as configuring Blaise and running integration tests.

Azure DevOps pipeline require at least the following parameters:

- `VarGroup` - Contains various environment variables and is created by [Terraform](). It's usually the GCP project name.
- `Environment` - Informs Azure DevOps which VMs to execute the pipeline on. Created manually in the Azure DevOps web UI and is `dev`, `preprod`, and `prod` for the formal environments. Sandboxes is usually the developers first name.

## Environment deployment tags

VMs (Virual Machines) are labelled with tags via a startup script when the Azure DevOps agent is registered with the VM. The VM startup scripts are stored in the [Terraform]() respository. Tags are used to target specific VMs via the yaml, the following snippet shows how to deploy to all VMs with the tag `data-entry`.

```
environment:
  name: ${{parameters.Environment}}
  resourceType: virtualMachine
  tags: data-entry
```

## Hosted environemnt deployment

Not all deployments are targetted at our VMs in GCP. Integration tests for example are run from VMs hosted by Azure DevOps. Example yaml snippet:

```
pool:
  vmImage: 'windows-2019'
```

## Templates

Reusable yaml steps are created within the templates folder, task step format as follows:

```
steps:
- task
  implementation
- task
  implementation
```

To use a template within a yaml file:

```
- template: /templates/my_template.yml
  parameters:
    Parameter1: Value1
    Parameter2: Value2
```

## Setting up a new pipeline

### Via Azure DevOps CLI

Install the [Azure DevOps CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and run the following command from this repository:

```
az pipelines create --name "A name for your pipeline" --yml-path pipelines/pipeline_yaml_file.yml
```

### Via Azure DevOps web UI

1. Navigate to https://dev.azure.com and login with your ONS email
1. Go to *pipelines*
1. Click *New pipeline*
1. Select *Github (YAML)*
1. Select *ONSDigital/Blaise-Azure-Pipelines* repo
1. Select *Existing Azure Pipelines YAML File*
1. Select your yaml file in *Path* - If you are working from a branch change the Branch to point at that (by default Azure will always look at main, so you will not need to redo this when you merge)
1. Save the pipeline

### Create a new user role
1. Add the permissions to the `UserRoles.json` file in the `UserRoles` folder
2. Ensure that the new role does not contain `root` (see example below) as this will prevent it from propagating to CATI
```angular2html
{
   "name":"TO Appointments",
   "description":"Role for TO Appointments",
   "permissions":[
      "root",
      "CATI",
      "CATI.viewappointments",
      "CATI.selectfromcaseinfo"
   ]
},
```
