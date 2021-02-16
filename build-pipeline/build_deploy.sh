#!/bin/bash

# Set global variables here
REGION="us-central"
PROJECT_ID="mp-delivery-new"


# Step-0
# create google project if not present
echo "[INFO] Step-0: Creating google project with projectId:${PROJECT_ID}"

gcloud projects describe $PROJECT_ID
if [ $? != 0 ]; then
    echo "[INFO] Project with ID:${PROJECT_ID} does not exist. Creating one"
    echo "CMD gcloud projects create ${PROJECT_ID}"
    gcloud projects create ${PROJECT_ID}

    # Set gcloud config project to the new project
    if [ $? -eq 0 ]; then
        echo "[INFO] Setting gcloud config to newly created project"
        gcloud config set project ${PROJECT_ID}
    fi

else
    echo "[INFO] Project with ID:${PROJECT_ID} exists.."
    gcloud config set project ${PROJECT_ID}
fi
# Step-1
# create google app if not present
if [ $? != 0 ]; then
    echo "[ERROR] Exiting project due to failure in previous step"
    exit 1
fi

gcloud app describe --project ${PROJECT_ID}
if [ $? != 0 ]; then
    echo "[INFO] app with PROJECT_ID:${PROJECT_ID} doesnt exist. Creating one... "
    gcloud app create --region ${REGION}   
fi

if [ $? != 0 ]; then
    echo "[ERROR] Error creating app. Exiting"
    exit 1
else
    echo "[INFO] Successfully created google app with PROJECT_ID:${PROJECT_ID}"    
fi

# Step-2
# Check permissions for the Cloudbuild service account to the project

# Disabling this line below as jq is not available on gcloud builder
# projectNumber=$(gcloud projects list --format=json | jq '.[]|select(.projectId == $PROJECT_ID).projectNumber')

projectNumber=$(gcloud projects describe ${PROJECT_ID} | grep "projectNumber" | cut -d " " -f2)

# Strip single quotes
projectNumber=$(eval echo $projectNumber)

if [ -z "$projectNumber" ]; then
    echo "[ERROR] Could not find PROJECT_NUMBER for PROJECT_ID:${PROJECT_ID}"
    exit 1
fi

echo "Got PROJECT_NUMBER:${projectNumber} for PROJECT_ID:${PROJECT_ID}"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
	--member="serviceAccount:${projectNumber}@cloudbuild.gserviceaccount.com" \
	--role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
	--member="serviceAccount:${projectNumber}@cloudbuild.gserviceaccount.com" \
	--role="roles/appengine.appAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
	--member="serviceAccount:${projectNumber}@cloudbuild.gserviceaccount.com" \
	--role="roles/cloudbuild.builds.builder"


# Step-3
echo Y | gcloud app deploy

# Step-4