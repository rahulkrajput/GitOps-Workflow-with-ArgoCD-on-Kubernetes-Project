# Provision Azure AKS using Terraform & Azure DevOps

## Step-01: Introduction
- Create Azure DevOps Pipeline to create AKS cluster using Terraform
- Terraform Manifests Validate
- Provision Prod AKS Cluster


## Step-02: Install Azure Market Place Plugins in Azure DevOps
- Install below listed plugins in your respective Azure DevOps Organization
- [Plugin: Terraform by Microsoft Devlabs](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks)



## Step-03: Review Terraform Manifests
### 01-main.tf
- Comment Terraform Backend, because we are going to configure that in Azure DevOps

### 02-variables.tf
- Two variables we will define in Azure DevOps and use it
  - Environment 
  - SSH Public Key (We Define SSH Variable here, but we fetch ssh key From Azure Devops Secure File)
 

### 03-resource-group.tf
- We are going to create resource groups for each environment with **terraform-aks-envname**
- Example Name:
  - terraform-aks-prod
  

### 04-aks-versions-datasource.tf
- We will get the latest version of AKS using this datasource. 
- `include_preview = false` will ensure that preview versions are not listed

### 05-aks-administrators-azure-ad.tf
- We are going to create Azure AD Group per environment for AKS Admins
- To create this group we need to ensure Azure AD Directory Write permission is there for our Service Principal (Service Connection) created in Azure DevOps
- Provide Permission to create Azure AD Groups

### 06-aks-cluster.tf
- Name of the AKS Cluster going to be **ResourceGroupName-Cluster**
- Example Names:
  - terraform-aks-prod-cluster
  
### 07-outputs.tf  
- We will put out output values very simple
- Resource Group 
  - Location
  - Name
  - ID
- AKS Cluster 
  - AKS Versions
  - AKS Latest Version
  - AKS Cluster ID
  - AKS Cluster Name
  - AKS Cluster Kubernetes Version
- AD Group
  - ID
  - Object ID
 
 


## Step-04: Create Github Repository

### Create Github Repository in Github
- Create Repository in your github
- Name: CI-CD-Pipeline-with-Azure-DevOps-Project
- Descritpion: Provision AKS Cluster using Azure DevOps Pipelines
- Repository Type: Public or Private (As Per Requirement)
- Click on **Create Repository**

### Create files, Initialize Local Repo, Push to Remote Git Repo
```
# Create folder in local desktop

mkdir CI-CD-Pipeline-with-Azure-DevOps-Project
cd CI-CD-Pipeline-with-Azure-DevOps-Project

# Create new folders inside "CI-CD-Pipeline-with-Azure-DevOps-Project" in local desktop
kubernetes-cluster-manifests (Create Yaml Files for Deployment on AKS Cluster)
terraform-manifests (Create Terraform Files for Provision AKS Cluster)
Pipelines (It is used for Save Pipeline, while Creating of AKS Cluster via Azure Devops Pipeline)



# Initialize Git Repo
cd CI-CD-Pipeline-with-Azure-DevOps-Project
git init

# Add Files & Commit to Local Repo
git add .
git commit -am "CI-CD-Pipeline-with-Azure-DevOps-Project"

# Add Remote Origin and Push to Remote Repo
git remote add origin https://github.com/rahulkrajput/CI-CD-Pipeline-with-Azure-DevOps-Project.git
git push --set-upstream origin master 

```     


## Step-05: Create New Azure DevOps Project for IAC
- Go to -> Azure DevOps -> Select Organization -> CI-CD-Pipeline-For-Provision-AKS-Cluster ->  Create New Project
- Project Name: Provision Terraform AKS Cluster
- Project Descritpion: Provision Azure AKS Cluster using Azure DevOps & Terraform
- Visibility: Private
- Click on **Create**

## Step-06: Create Azure RM Service Connection for Terraform Commands
- This is a pre-requisite step required during Azure Pipelines
- Go to -> Azure DevOps -> Select Organization -> Select project **Provision Terraform AKS Cluster**
- Go to **Project Settings**
- Go to Pipelines -> Service Connections -> Create Service Connection
- Choose a Service Connection type: Azure Resource Manager
- Identity type: App registration (automatic)
- Credential: Workload identity federation (automatic)
- Scope Level: Subscription
- Subscription: Select_Your_Subscription
- Resource Group: No need to select any resource group
- Service Connection Name: terraform-aks-cluster-svc-conn
- Description: Azure RM Service Connection for provisioning AKS Cluster using Terraform on Azure DevOps
- Security: Grant access permissions to all pipelines (check it - leave to default)
- Click on **SAVE**


## Step-07: Provide Permission to create Azure AD Groups
- Provide permission for Service connection created in previous step to create Azure AD Groups
- Go to -> Azure DevOps -> Select Organization -> Select project **Provision Terraform AKS Cluster**
- Go to **Project Settings** -> Pipelines -> Service Connections 
- Open **terraform-aks-cluster-svc-conn**
- Click on **Manage App registration**, new tab will be opened 
- Click on **View API Permissions**
- Click on **Add Permission**
- Select an API: Microsoft APIs
- Microsoft APIs: Use **Microsoft Graph**
- Click on **Application Permissions**
- Select permissions : "Directory" and click on it 
- Check **Directory.ReadWrite.All** and click on **Add Permission**
- Click on **Grant Admin consent for Default Directory**



## Step-08: Create SSH Public Key for Linux VMs
- Create this out of your git repository 
- **Important Note:**  We should not have these files in our git repos for security Reasons
```
# Create Folder
mkdir $HOME/ssh-keys-terraform-aks-devops

# Create SSH Keys
ssh-keygen \
    -m PEM \
    -t rsa \
    -b 4096 \
    -C "azureuser@myserver" \
    -f ~/ssh-keys-terraform-aks-devops/aks-terraform-devops-ssh-key-ubuntu \

Note: We will have passphrase as : empty when asked

# List Files
ls -lrt $HOME/ssh-keys-terraform-aks-devops
Private File: aks-terraform-devops-ssh-key-ubuntu (To be stored safe with us)
Public File: aks-terraform-devops-ssh-key-ubuntu.pub (To be uploaded to Azure DevOps)
```

## Step-09: Upload file to Azure DevOps as Secure File
- Go to Azure DevOps -> CI-CD-Pipeline-For-Provision-AKS-Cluster -> Provision Terraform AKS Cluster -> Pipelines -> Library
- Secure File -> Upload file named **aks-terraform-devops-ssh-key-ubuntu.pub**
- Open the file and click on **Pipeline permissions -> Click on three dots -> Confirm open access -> Click on Open access**
- Click on **SAVE**


## Step-10: Create Azure Pipeline to Provision AKS Cluster
- Go to -> Azure DevOps -> Select Organization -> Select project 
- Go to Pipelines -> Pipelines -> Create Pipeline
### Where is your Code?
- Github
- Select Your Repository
- Provide your github password
- Click on **Approve and Install** on Github
### Configure your Pipeline
- Select Pipeline: Starter Pipeline  
- Pipeline Name: 01-Provision-and-Destroy-Terraform-AKS-Cluster-Pipeline.yml
- Design your Pipeline As Per Need
### Pipeline Save and Run
- Click on **Save and Run**
- Commit Message: Provision Prod AKS Cluster via terraform
- Click on **Job** and Verify Pipeline

### Verify new Storage Account in Azure Mgmt Console

- Verify Storage Account
- Verify Storage Container
- Verify tfstate file got created in storage container

### Verify new AKS Cluster in Azure Mgmt Console
- Verify Resource Group 
- Verify AKS Cluster
- Verify AD Group
- Verify Tags for a nodepool

### Connect to Prod AKS Cluster & verify
```

# List Nodepools
az aks nodepool list --cluster-name terraform-aks-prod-cluster --resource-group terraform-aks-prod -o table

# Setup kubeconfig
az aks get-credentials --resource-group <Resource-Group-Name>  --name <AKS-Cluster-Name>
az aks get-credentials --resource-group terraform-aks-prod  --name terraform-aks-prod-cluster --admin

# View Cluster Info
kubectl cluster-info

# List Kubernetes Worker Nodes
kubectl get nodes
```

## Step-11: Delete Resources
Delete the Resources either through the Pipeline Or Manually 

### Pipeline
- If you want to Delete Nginx App Deployment then Uncomment "delete task" in Deploy Kubernetes Deployment(pipeline) and re-run the pipeline.
- If you want to Delete AKS Cluster, Uncomment "destroy task" in Provision AKS Cluster(pipeline) and re-run the pipeline

### Manually
- Delete the Resource group which will delete all resources
  - terraform-aks-prod
  
- Delete AD Groups  

## Notes

- **Make sure to replace placeholders (e.g., Your_Subscription_ID, your_cluster_name, your_region, your_resource_group_name...etc) with your actual Configuration.**

- **This is a basic setup for demonstration purposes. In a production environment, you should follow best practices for security and performance.**

## References
- [Publish & Download Artifacts in Azure DevOps Pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/artifacts/pipeline-artifacts?view=azure-devops&tabs=yaml)
- [Azure DevOps Pipelines - Deployment Jobs](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/deployment-jobs?view=azure-devops)
- [Azure DevOps Pipelines - Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops)


