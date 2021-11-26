# Azure Trusted Research Environment - QueensU

This repo is for modifications and extensions of the Azure TRE accelerator provided by Microsoft. It is meant to hold any modifications to the baseline core infrastructure, as well as new TRE resource templates (workspaces, services, etc.).

<br />  

## Using the repository
The primary branch for this forked repository is "queens/develop", all new branches should branch from this one, and merge to it. This allows upstream changes from the Microsoft repo to be synced without conflict. If upstream changes are desired in the Queen's development branch, [fetch changes from the upstream repo](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork), then merge the "main" branch into "queens/develop" - note that doing this is likely to result in merge conflicts, which will need to be resolved.

<br />  

## Official Documentation
Microsoft provides documentation on the baseline TRE environment - it can be found [here](https://microsoft.github.io/AzureTRE/). This is the best place to start learning about Azure TRE. Particularly useful docs include:

[TRE Overview](https://microsoft.github.io/AzureTRE/)

[How to deploy TRE](https://microsoft.github.io/AzureTRE/tre-admins/setup-instructions/getting-started/)

[Authentication and Authorization](https://microsoft.github.io/AzureTRE/tre-admins/auth/)

[How to author new workspace templates](https://microsoft.github.io/AzureTRE/tre-workspace-authors/authoring-workspace-templates/)

[Troubleshooting Guide](https://microsoft.github.io/AzureTRE/tre-admins/troubleshooting-guide/)

Additionally, TRE makes use of Porter, a "Cloud-Native Application Bundle" (CNAB) authoring and deployment tool. Porter is essential for aurthoring new TRE resources. A cursory understanding of the CNAB specification helps in using Porter.

[Porter Documentation](https://porter.sh/docs/)

[CNAB Specification](https://github.com/cnabio/cnab-spec)

<br />  

## Supplemental Documentation
This section is broadly for additional insights, elaborations, etc. on the existing documentation, as well as any Queen's-specific information. Please add to it as needed, though note that this repo is public (required to remain a fork of the upstream public TRE repo).

<br />  

### **Makefile**
The base TRE repo contains a "Makefile" with many useful operations for working with TRE. Some notable ones are:
<br />  
`all` - Creates management / "bootstrap" infrastructure (ACR for porter images, Storage Account for terraform state), build and pushes core porter bundles, and deploys TRE core infrastructure.

`mgmt-deploy` / mgmt-destroy: deploys / destroys the management / "bootstrap" infrastructure: ACR for porter images, Storage Account for terraform state.

`tre-deploy / tre-destroy`: Deploys / destroys "core" infrastructure, that is the hub resource group and its resources. tre-deploy can be used to apply changes to core infrastructure templates without starting from scratch.

`tre-stop / tre-start`: Stops or "disables" some of the more expensive-to-run core TRE infrastructure, namely the Firewall and Application Gateway. "start" 
turns them back on again.

`porter-build/install/uninstall/publish` : analgous to the management plane running the corresponding Porter commands. Reads in environment variables from several ".env" files (devops/.env, templates/core/,env, templates/workspaces/<your_workspace>/.env) before running the command, emulating the management 
plane environment (specifically the "resource processor"). Note the management plane only uses Porter install and uninstall.

`register-bundle-payload`: Publishes already-built Porter bundle to management/bootstrap ACR, and outputs a JSON block to be used in registering the bundle with the TRE management plane (API). Requires DIR and BUNDLE_TYPE arguments (eg. make register-bundle DIR=templates/workspaces/imaging_annotations/ BUNDLE_TYPE=workspace)

`register-bundle`: Similar to above, rather than outputting JSON for manual Bundle registration, attempts to call TRE API and do so directly. Requires a token to authenticate to the API.

<br />  

### **Cost measures**
The standard TRE environment is expensive! There are a couple measures taken during POC to mitigate these costs, and more measure can be taken depending on security / other requirements.

Downgrading the Service Bus: We changed the Service Bus SKU from "Premium" to "Standard", as the premimum SKU uses a reserved-capacity cost model that is very expensive and over-provisioned for POC purposes. Unfortunately, only the Premium SKU supports VNet integration / Private Links, so running Standard means the Service Bus will have a public endpoint

Makefile tre-stop and tre-start: As mentioned above, the Makefile has operations to "stop" and "start" the environment. Stopping the environment when not in use will pause billing on the stopped resources, notably the Azure Firewall, and the AppGateway, both of which are expensive. Just note that is the environment is stopped, it will most likely not work correctly until started again.

<br />  

### **Note on Key Vaults and Purge Protection**
The Base workspace, as well as the Core TRE infrastructure, use Azure Key Vaults. By default, these keyvaults have "Purge Protection" enabled in their templates. This may be desirable, but please note that deleting Key Vaults with Purge Protection enabled can cause naming collisions if the "same" keyvault (ie same name in same subscription, same secret names) is deployed.

For instance, you perform a manual porter install of your bundle to test it, something doesn't work correctly, so you uninstall, modify, and re-install. With Purge Protection enabled, any Key Vault secrets you initially deployed still exist in a "deleted" state, so the reinstall will fail citing that those secrets already exist as the cause.

<br />  

### **Workspace Authoring**

The official docs provide some [guidance on authoring new workspace templates / bundles](https://microsoft.github.io/AzureTRE/tre-workspace-authors/authoring-workspace-templates/). Below is a general workflow for doing so.

<br />  

#### **Dev environment**

[Docker](https://docs.docker.com/desktop/windows/release-notes/) is a must for any TRE development, including authoring new templates. It enables the use of the dev container provided by Microsoft, which contains all of the tooling needed to work with TRE. Note that it can take a while (~40 minutes) for the container image to build for the first time.
[VSCode](https://code.visualstudio.com/Download) is also highly reccommended, as it has features for development within a container. If you choose another IDE / COde Editor, make sure it is container-compatible.

Once the dev container is up and running, make a new branch off of queens/develop to hold the new template. It can be pulled into develop once it is completed.

The easiest way to get started is make a copy of the base workspace directory (templates/workspaces/base), as its Porter manifest and supporting files make it a "TRE-compatible" bundle. This applies to workspace-services and user resources as well. Starting from scratch with `porter init` is ok too, but TRE default parameters and credentials must be added, [as described here](https://microsoft.github.io/AzureTRE/tre-workspace-authors/authoring-workspace-templates/#workspace-bundle-manifest). A ".env" file is also necessary in the template directory, its values will be passed into Porter when using the Makefile, and simulates values that the TRE management plane would pass in when installing from the local environment.

templates/workspaces/<my_workspace>/.env
```
ID=abcd
ADDRESS_SPACE=10.1.7.0/24
LOCATION=canadacentral
```

<br />  

#### **Workspace bundle / template development**

With all that set up, bundles can be installed (deployed) from the dev container as they would be from the TRE management plane. This is useful for testing bundles locally before publishing them to ACR and having TRE deploy them. Next is to actually write the bundle - Terraform templates, scripts, helm charts, etc. are written in separate files, and the bundle manifest (porter.yaml) references them.  Any technologies available as [Porter "mixins"](https://porter.sh/mixins/) may be used, and note that there is an "exec" mixin that can run shell scripts in case a suitable mixin doesn't exist. Use the included templates as examples.

Once the bundle is written, build and install it using the Makefile:

```
make porter-build DIR=templates/workspaces/<my_workspace>
make porter-install DIR=templates/workspaces/<my_workspace>
```

Test the deployment. If any changes to the bundle are needed, first uninstall it with
```
make porter-uninstall DIR=templates/workspaces/<my_workspace>
```
Then re-build and install with the above commands.

<br />  

#### **Registering Templates and Creating Workspaces**

Once the bundle is in a good state, it's time to publish it to ACR and register it with the TRE management plane.
```
make register-bundle-payload DIR=templates/workspaces/<my_workspace>/ BUNDLE_TYPE=workspace
```
This will push the bundle to ACR, and output the JSON payload needed to register it with TRE. Payload-in-hand, navigate to the TRE API SwaggerUI ([set up as part of the core deployment](https://microsoft.github.io/AzureTRE/tre-admins/setup-instructions/deploying-azure-tre/#using-the-api-docs)) and make a POST request to the /workspace-templates endpoint with the payload in the body. This will register the template and allow it to be installed via the TRE API. Making a GET request to the same endpoint will show the newly-registered template.

Before actually creating the workspace through TRE, an Azure AD App Registration must be created. Assigning Azure AD users to this App Registration (or more accurately, to its corresponding "Enterprise Application") will grant them permissions to manage the instance of the workspace about to be created through the TRE API, ie adding workspace services, or deleting the workspace, [as described here](https://microsoft.github.io/AzureTRE/azure-tre-overview/user-roles/#tre-workspace-owner). A script is provided to do this:

```
scripts/workspace_app_reg.py --tre-name <my_TRE_id> --workspace-name <my_workspace_name>
```
Note that the parameters are used in naming only and may be anything, the registration will be named like "<tre-name> Workspace - <workspace_name>".
The script will output an App ID to be used when creating the workspace. Before doing so, navigate to the App Registration's corresponding Enterprise Application in Azure AD (Azure Portal), and assign users to either "Researcher" or "Owner" roles (assigning yourself as an Owner is reccomended).

Finally, the workspace may be created through the TRE API. Return to the SwaggerUI, and make a POST request to /workspaces with the following payload:
```json
{
  "templateName": "<my_workspace_template_name>",
  "properties": {
      "display_name": "the workspace display name",
      "description": "workspace description",
      "app_id": "<app_id from previous step>"
  }
}
```
The workspace ID will be returned in the response. Make a GET request to /workspaces/<workspace_id> to see the status of the deployment. Status should go from "not_deployed -> "deploying" -> "deployed" or "deployment_failed". When the status is failure, this endpoint will return an error message that should help in troubleshooting. If the deployment seems "stuck", check the Azure portal to see if resources are in fact being deployed, and consult the [troubleshooting guide](https://microsoft.github.io/AzureTRE/tre-admins/troubleshooting-guide/) to find where something may be stuck. 


