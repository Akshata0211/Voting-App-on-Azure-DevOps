
# Voting App Deployment on Azure DevOps

This project demonstrates the deployment of a multi-container voting application (vote, worker, result) using Azure DevOps pipelines, Azure Container Registry (ACR), Azure Kubernetes Service (AKS), and ArgoCD for GitOps continuous delivery.

## Architecture Overview

- Frontend: Voting UI (Python/Flask)
- Backend: Redis for temporary storage
- Worker: .NET Core service to process votes
- Database: Postgres for persistent storage
- Results: Node.js service to display results

## Deployment Steps

### 1. Repository Setup

1. Clone the original repo: `dockersamples/example-voting-app`
2. In Azure DevOps:
   - Create a new project
   - Import repository (Git)
   - Set main branch as default

### 2. Azure Infrastructure Setup

1. Create Resource Group
2. Create Azure Container Registry (ACR)
3. Create an Azure Kubernetes Service (AKS) cluster with:
   - Dev/Test configuration
   - Public IP enabled

### 3. Self-Hosted Agent Setup

1. Create Linux VM on Azure Portal
2. In Azure DevOps:
    `Project Settings > Agent Pools > Add pool (self-hosted)`
3. On VM:
   ```bash
   ssh -i keyname.pem azureuser@vm-public-ip
   sudo apt install docker.io
   sudo usermod -aG docker azureuser
   ```
4. Run agent installation commands with:
   Server URL: `https://dev.azure.com/organization-name`
   PAT token (from User Settings > Personal Access Tokens)

### 4. Pipeline Setup

For each microservice (vote, worker, result):
  - Create pipeline with Azure Repos Git
  - Select Docker template
  - Configure to build and push to ACR

### 5. Kubernetes Deployment

1. Configure Azure Kubernetes Cluster:
   ```bash
   az aks get-credentials --name azuredevops --overwrite-existing --resource-group azurecicd
   ```
2. Verify Cluster Nodes (Use EXTERNAL-Node-IP):
   ```bash
   kubectl get nodes -o wide
   ```
3. ACR Configuration
  - Create ACR (if not existing):
    ```bash
    az acr create --resource-group azurecicd --name ACR-REPOname --sku Basic
    ```
    
   - Enable Admin Credentials:
     
    `Azure Portal → Your ACR → Settings → Access keys → Enable Admin user`
     Note the username (ACR-REPOname) and password
  
4. Create ImagePullSecret:
   ```bash
   kubectl create secret docker-registry acr-credentials \
  --namespace default \
  --docker-server=ACR-REPOname.azurecr.io \
  --docker-username=ACR-REPOname \
  --docker-password=<your-acr-password>
   ```

5. Update Kubernetes Manifests
   Edit k8s-specifications/deployment.yaml:
   ```bash
   image: ACR-REPOname.azurecr.io/vote:latest
   imagePullSecrets:
   - name: acr-credentials
   ```

### 6. ArgoCD Setup

1. Install ArgoCD:
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```
2. Get admin password:
   ```bash
   kubectl get secrets -n argocd 
   kubectl edit secret argocd-initial-admin-secret -n argocd
   echo <password> | base64 --decode
   ```
3. Change service type to NodePort:
   ```bash
   kubectl edit svc argocd-server -n argocd
   ```
4. Update VM NSG to allow inbound traffic to NodePort

### 7. Configure ArgoCD

1. Access ArgoCD UI at http://<node-ip>:<node-port>
2. Connect Git repo (Azure Repos URL)
3. Create new app pointing to k8s-specifications folder
4. Update reconciliation timeout to 10s:
   ```bash
   kubectl edit cm argocd-cm -n argocd
   ```

### 8. Access Application

1. Get services:
   ```bash
   kubectl get svc
   ```
2. Access:
  - Voting UI: `http://<external-node-ip>:<vote-node-port>`
  - Results UI: `http://<external-node-ip>:<result-node-port>`
  - ArgoCD UI: `http://<external-node-ip>:<argocd-node-port>`

### Cleanup

To delete all resources:
- Delete the resource group in Azure Portal
- Delete the Azure DevOps project
