# Blaise-Azure-Pipelines

## usage 
Azure devops pipelines are task monkeys for Concourse, each pipeline uses Parameters to target a different environment.

Requires:
- variable group name (created by TF) - this is usually the project name in GCP
- environment (created manually) - formal envs are (dev, preprod, prod), sandboxes are first names

### Environment deployments - Tags
Virual Machines (VMs) are labelled with tags via the start up script when the agent is registered with a virtual machine (See terraform)
Tags are used to target specific VMs via the yaml, the following snippet shows how to deploy to all VMs with the tag *data-entry*

```
 environment:  
        name: ${{parameters.Environment}}
        resourceType: virtualMachine
        tags: data-entry
```

### Azure hosted environemnt deployments

We use pre built environments to run automated tests, these are spun up as deployment is run and torn down once the deployment has finished. 

```
    pool: 
        vmImage: 'windows-latest'
```


### Templates
Reusable yaml steps are created within the templates folder, format for task templates is:

```
steps:
- task
  implementation
- task
  implementation
```

To use a template within a yaml file:

```
- template: /my_template.yml
    parameters:
        Additional parameters: which are needed
```

## Setting up a new pipeline 

### Via Azure CLI

From within this repo run
```
az pipelines create --name "A Name for your pipeline" --yml-path /Path_To_Your.yml
```

### Via Azure Devops Interface

Navigate to https://dev.azure.com and login with your ONS email

1. Go to *pipelines*
2. Click *New pipeline*
3. Select *Github (YAML)*
4. Select *ONSDigital/Blaise-Azure-Pipelines* repo
5. Select *Existing Azure Pipelines YAML File*
6. Select your yaml file in *Path* - If you are working from a branch change the Branch to point at that (by default Azure will always look at main, so you will not need to redo this when you merge)
7. Save the pipeline
