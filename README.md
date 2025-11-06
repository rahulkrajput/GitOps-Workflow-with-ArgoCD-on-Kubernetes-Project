# Provision Azure AKS and Install ArgoCD using Terraform & Azure DevOps

## Step-01: Brief Intro
- Create Azure DevOps Pipeline to create AKS cluster and Install ArgoCD using Terraform
- Terraform Manifests Validate
- Provision Prod AKS Cluster
- Install ArgoCD Server


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
- Name: GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project
- Descritpion: A GitOps Workflow project using ArgoCD on Kubernetes focuses on automating and managing deployments by using Git.
- Repository Type: Public or Private (As Per Requirement)
- Click on **Create Repository**

### Create files, Initialize Local Repo, Push to Remote Git Repo
```
# Create folder in local desktop

mkdir GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project
cd GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project

# Create new folders inside "GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project" in local desktop
kubernetes-cluster-manifests (Create Yaml Files for Deployment on AKS Cluster)
terraform-manifests (Create Terraform Files for Provision AKS Cluster)
Pipelines (It is used for Save Pipeline, while Creating of AKS Cluster, Install ArgoCD and Docker Build Push Image via Azure Devops Pipeline)



# Initialize Git Repo
cd GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project
git init

# Add Files & Commit to Local Repo
git add .
git commit -am "GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project"

# Add Remote Origin and Push to Remote Repo
git remote add origin https://github.com/rahulkrajput/GitOps-Workflow-with-ArgoCD-on-Kubernetes-Project.git
git push --set-upstream origin master 

```     


## Step-05: Create New Azure DevOps Project for IAC
- Go to -> Azure DevOps -> Select Organization -> GitOps-Workflow-with-ArgoCD-on-Kubernetes ->  Create New Project
- Project Name: Provision-GitOps-Workflow-with-ArgoCD-on-Terraform-AKS-Cluster
- Project Descritpion: Provision-GitOps-Workflow-with-ArgoCD-on-Terraform-AKS-Cluster
- Visibility: Private
- Click on **Create**

## Step-06: Create Azure RM Service Connection for Terraform Commands
- This is a pre-requisite step required during Azure Pipelines
- Go to -> Azure DevOps -> Select Organization -> Select project **Provision-GitOps-Workflow-with-ArgoCD-on-Terraform-AKS-Cluster**
- Go to **Project Settings**
- Go to Pipelines -> Service Connections -> Create Service Connection
- Choose a Service Connection type: Azure Resource Manager
- Identity type: App registration (automatic)
- Credential: Workload identity federation (automatic)
- Scope Level: Subscription
- Subscription: Select_Your_Subscription
- Resource Group: No need to select any resource group
- Service Connection Name: GitOps-ArgoCD-Terraform-AKS-Cluster-svc-conn
- Description: Service Connection for provisioning GitOps workflow with ArgoCD On Terraform AKS Cluster
- Security: Grant access permissions to all pipelines (check it - leave to default)
- Click on **SAVE**


## Step-07: Provide Permission to create Azure AD Groups
- Provide permission for Service connection created in previous step to create Azure AD Groups
- Go to -> Azure DevOps -> Select Organization -> Select project **Provision-GitOps-Workflow-with-ArgoCD-on-Terraform-AKS-Cluster**
- Go to **Project Settings** -> Pipelines -> Service Connections 
- Open **GitOps-ArgoCD-Terraform-AKS-Cluster-svc-conn**
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
- Go to Azure DevOps -> - Go to -> Azure DevOps -> Select Organization -> GitOps-Workflow-with-ArgoCD-on-Kubernetes ->  Create New Project
 -> Provision-GitOps-Workflow-with-ArgoCD-on-Terraform-AKS-Cluster -> Pipelines -> Library
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
- Pipeline Name: 01-Provision-and-Destroy-Terraform-AKS-Cluster-&-Install-ArgoCD-Pipeline.yml
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

# Verify Deployment Status:

- ArgoCD Pods:
kubectl get pods -n argocd

- ArgoCD Service:
kubectl get svc -n argocd

- ArgoCD Ingress:
kubectl get ingress -n argocd 

- Ingress Controller Pods:
kubectl get pod -n ingress-nginx

- Ingress Controller Service:
kubectl get svc -n ingress-nginx

```
## Step-11: Create Ingress File 
```
Create Ingress File with any Name (In Our Case we create "nginx-ingress.yml" File)

#  vi nginx-ingress.yml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-http-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS" #(Sometime it work with HTTPS and Sometime it work with HTTP Protocol, Also change Port number as well according to your Protocol HTTPS Or HTTP)
    nginx.ingress.kubernetes.io/service-upstream: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  
  rules:
  - host: argocd.ubei.info # Add Your Domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443

# Apply Nginx-Ingress File

kubectl apply -f nginx-ingress.yml

```
## Step-12: Edit argocd ConfigMap 
```
Edit argocd ConfigMap and Update yaml with 

    “ data:
           server.insecure: "true"  ”

# kubectl edit configmap argocd-cmd-params-cm -n argocd -o yaml

apiVersion: v1
data:
  server.insecure: "true" 
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"ConfigMap","metadata":{"annotations":{},"labels":{"app.kubernetes.io/name":"argocd-cmd-params-cm","app.kubernetes.io/part-of":"argocd"},"name":"argocd-cmd-params-cm","namespace":"argocd"}}
  creationTimestamp: "2025-11-02T13:18:49Z"
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
  name: argocd-cmd-params-cm
  namespace: argocd
  resourceVersion: "117859"
  uid: bceeb42d-ded5-4b3a-acbb-03639e4f1b1d

```
## Step-13: Create DNS Zone 

-	Go to Azure Portal and Search -> **DNS Zones**
-	Subscription: Your_Subscription 
-	Resource Group: terraform-aks-prod-nrg
-	Name: ubei.info (Zone Name)
-	Resource Group Location: centralindia
-	Click on Review + Create

## Step-13A: Copy Azure Nameservers Name

 -	Go to Azure Portal and Search -> DNS Zones-> ubei.info-> Overview
```
ns3-05.azure-dns.org	
ns2-05.azure-dns.net	
ns1-05.azure-dns.com	
ns4-05.azure-dns.info	

```
## Step-14: Go to Your Domain Registrar Update Nameservers 

- Verify before updation

```
nslookup -type=SOA ubei.info
nslookup -type=NS ubei.info
```


Output:

<img width="663" height="319" alt="Image" src="https://github.com/user-attachments/assets/53e9e5f3-35c3-4c38-89e0-3817e270470d" />




-	Login into your Domain Provider Account (My Domain Registrar: ionos.com)
-	Click on Add or edit name servers
-	Update Azure Name servers here and click on Save
-	Wait for Next 48 hours (but usually it updates Name Servers within 3-4 hours.)
-	Verify after updation

```
nslookup -type=NS ubei.info 8.8.8.8
nslookup -type=SOA ubei.info 8.8.8.8
```

Output:

<img width="877" height="614" alt="Image" src="https://github.com/user-attachments/assets/8926082f-3f0c-46a2-ba61-1cb6034774cd" />



##  Step-15: Now, Create A record in DNS Zone (ubei.info)

-	Go to RecordSet
-	Click on Add
-	Type Name : argocd
-	Value : Type your External-IP Address (Which you got when you created Ingress Controller. If want to know about it, go to Terminal & type “ kubectl get svc -n ingress-nginx ”) 
-	Go to Browser type Your host name “argocd.ubei.info”

Output: 

<img width="975" height="638" alt="Image" src="https://github.com/user-attachments/assets/57a8b726-5f4a-465e-ba52-7dc1c3e70cd3" />


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


