# Imaging Annotations Workspace

POC workspace provides a GPU-enabled Virtual Desktop environment for annotations of medical imaging data.

This workspace is based on the [Base workspace](./base.md), and additionally contains the following Azure resources:

- [Azure Virtual Destop](https://docs.microsoft.com/en-us/azure/virtual-desktop/) running [3DSlicer](https://www.slicer.org/)
  - GPU session host VM
- GPU VM backend server running [Monai Label](https://docs.monai.io/projects/label/en/latest/index.html#)
- [Datalake Gen 2 Filesystem](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction) in storage account for imaging data (NFS mount in backend server)

## Manual deployment for development and testing

1. Create a copy of `workspaces/imaging_annotations/.env.sample` with the name `.env` and update the variables with the appropriate values.

  | Environment variable name | Description |
  | ------------------------- | ----------- |
  | `ID` | A GUID to identify the workspace. The last 4 characters of this `ID` can be found in the resource names of the workspace resources; for example, a `ID` of `2e84dad0-9d4f-42bd-8e44-3d04095eab12` will result in a resource group name for workspace of `rg-<tre-id>-ab12`. |
  | `ADDRESS_SPACE` | The address space for the workspace virtual network, must be inside the `TRE_ADDRESS_SPACE` defined when deploying the TRE and not overlap with any other address spaces. |
  | `LOCATION` | Azure region in which the resources will be deployed. Most likely to be "canadacentral" |

2. Build and install the workspace:

  ```cmd
  make porter-build DIR=./templates/workspaces/imaging_annotations
  make porter-install DIR=./templates/workspaces/imaging_annotations
  ```

## Manual steps post-install

Some configuration of this environment requires manual work. These could potentially be automated in the future.

- Azure AD permissions to AVD environment:
  - Users / groups must be added to the AVD Application Pool manually. Navigate to the Desktop Application Pool in the Azure portal (avddag-<tre_name>-ws-<workspace_id>) and go to "Assignments". This allows users to connect to the AVD environment.
  - Users / groups must be assigned VM roles in Azure RBAC. Navigate to the Session Host VM in the Azure portal (avdhost-<workspace_id>) and go to "Access Control (IAM). Assign "Virtual Machine User Login" and/or "Virtual Machine Administrator Login" to the appropriate users / groups. This allows users to sign in to the AVD environment.
- Configure Storage Account permissions:
  - The Storage Account contains a Datalake Gen 2 Filesystem with POSIX-style file / directory permissions ("monai-data"). The script that creates it is supposed to also configure these permissions, but it doesn't work. For now, configure them in the portal by navigating to the storage account (stgws<workspace_id>), "Containers", "monai-data", "Manage ACL", and checking everything off. This is roughly equivalent to 777 / read-write-execute for all users (This should be refined in the future). More info available [here](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-access-control).

## Notes / Future Improvements

- NFSV3 and PremiumHns are preview features and must be enabled on the desired subscription:

```cmd
az feature register --namespace Microsoft.Storage --name AllowNFSV3
az feature register --namespace Microsoft.Storage --name PremiumHns
```

- Subscription/region cpu core quota for VM SKUs (Standard_NV4as_v4, Standard_NC6s_v3) may need to be increased to deploy VMs
- The AVD session host *sometimes* requires a restart to recognize either the AAD join or GPU driver extension (might be whichever was installed last). This restart could be built-in to the bundle as an install step, though this is not ideal.
- Bundle only deploys a single AVD Session Host - the number of session hosts could be parameterized in the future.
- More generally, resources in this workspace could be broken out into Workspace Services, allowing them to be used in other workspace templates / added to existing workspace instances.
