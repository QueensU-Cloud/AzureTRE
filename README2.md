# Azure Trusted Research Environment - QueensU

This repo is for modifications and extensions of the Azure TRE accelerator provided by Microsoft. It is meant to hold any modifications to the baseline core infrastructure, as well as new TRE resource templates (workspaces, services, etc.).

## Using the repository
The primary branch for this forked repository is "queens/develop", all new branches should branch from this one, and merge to it. This allows upstream changes from the Microsoft repo to be synced without conflict. If upstream changes are desired in the Queen's development branch, [fetch changes from the upstream repo](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork), then merge the "main" branch into "queens/develop" - note that doing this is likely to result in merge conflicts, which will need to be resolved.

## Official Documentation
Microsoft provides documentation on the baseline TRE environment - it can be found [here](TODO). This is the best place to start learning about Azure TRE. Particularly useful docs include:

[TRE Overview](TODO)
[How to deploy TRE](TODO)
[How to author new workspace templates](TODO)

Additionally, TRE makes use of Porter, a "Cloud-Native Application Bundle" (CNAB) authoring and deployment tool. Porter is essential for aurthoring new TRE resources. A cursory understanding of the CNAB specification helps in using Porter.

[Porter Documentation](TODO)
[CNAB Spec](TODO)

## Supplemental Documentation
This section is broadly for additional insights, elaborations, etc. on the existing documentation, as well as any Queen's-specific information. Please add to it as needed, though note that this repo is public (required to remain a fork of the upstream public TRE repo).

### Makefile
The base TRE repo contains a "Makefile" with many useful operations for working with TRE. Some notable ones are:

all - Creates management / "bootstrap" infrastructure (ACR for porter images, Storage Account for terraform state), build and pushes core porter bundles, and deploys TRE core infrastructure.

mgmt-deploy / mgmt-destroy: deploys / destroys the management / "bootstrap" infrastructure: ACR for porter images, Storage Account for terraform state.

tre-deploy / tre-destroy: Deploys / destroys "core" infrastructure, that is the hub resource group and its resources. tre-deploy can be used to apply changes to core infrastructure templates without starting from scratch.

tre-stop / tre-start: Stops or "disables" some of the more expensive-to-run core TRE infrastructure, namely the Firewall and Application Gateway. "start" 
turns them back on again.

porter-build/install/uninstall/publish : analgous to the management plane running the corresponding Porter commands. Reads in environment variables from several ".env" files (devops/.env, templates/core/,env, templates/workspaces/<your_workspace>/.env) before running the command, emulating the management 
plane environment (specifically the "resource processor"). Note the management plane only uses Porter install and uninstall.

register-bundle-payload: Publishes already-built Porter bundle to management/bootstrap ACR, and outputs a JSON block to be used in registering the bundle with the TRE management plane (API). Requires DIR and BUNDLE_TYPE arguments (eg. make register-bundle DIR=templates/workspaces/imaging_annotations/ BUNDLE_TYPE=workspace)

register-bundle: Similar to above, rather than outputting JSON for manual Bundle registration, attempts to call TRE API and do so directly. Requires a token to authenticate to the API.


-Cost measures
service bus
tre-stop

-Note on Keyvaults

-WS authoring workflow
  - dev contaier
  - makefile operations
  - templates, scripts, etc
  - manifest
  - make porter build
  - publish
  - register json
  - app reg script
  - create
