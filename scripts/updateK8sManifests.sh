#!/bin/bash

set -x

# Set the repository URL
REPO_URL="https://PAT-TOKEN@dev.azure.com/Org-Name/voting-app/_git/voting-app"

# Clean up any previous temp repo
rm -rf /tmp/temp_repo

# Clone the git repository into the /tmp directory
git clone "$REPO_URL" /tmp/temp_repo

# Navigate into the cloned repository directory
cd /tmp/temp_repo

# Make changes to the Kubernetes manifest file(s)
sed -i "s|image:.*|image: akshataazurecicd.azurecr.io/$2:$3|g" k8s-specifications/$1-deployment.yaml

# Add the modified files
git add .

# Commit the changes
git commit -m "Update Kubernetes manifest"

# Push the changes back to the repository
git push

# Cleanup: remove the temporary directory
rm -rf /tmp/temp_repo
