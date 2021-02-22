#!/bin/bash

# Set global variables here
REGION="us-central1"
PROJECT_ID="mp-delivery-now"
POSTGRES_DB_INSTANCE="qa-postgresql-db"
POSTGRES_DB_NAME="postgres"

# Assuming we have Project and app already created

# Assumin all permissions are already set
gcloud config set project ${PROJECT_ID}

# Make sure "Cloud SQL Admin API" Permission is enabled

# Check Database
sqlInstanceConnectionName="$PROJECT_ID:us-west2:$POSTGRES_DB_INSTANCE"
echo "sqlInstanceConnectionName:$sqlInstanceConnectionName"
gcloud sql instances describe $POSTGRES_DB_INSTANCE

if [ $? != 0 ]; then
    echo "[INFO] INSTANCE ID:$POSTGRES_DB_INSTANCE doesnt exist. Creating one."
    gcloud sql instances create $POSTGRES_DB_INSTANCE --database-version=POSTGRES_12 --assign-ip --cpu=1 --memory=4GiB --root-password=perseverance! --region=$REGION
    echo "[INFO] INSTANCE ID:$POSTGRES_DB_INSTANCE creation complete"
else
    echo "INSTANCE ID:$POSTGRES_DB_INSTANCE already exists."
fi

# Create a database in the sql instances, if the database is not default postgres
gcloud sql databases describe $POSTGRES_DB_NAME --instance=$POSTGRES_DB_INSTANCE

if [ $? != 0 ]; then
    echo "[INFO] Database:$POSTGRES_DB_NAME doesnt exist. Creating one."
    gcloud sql databases create $POSTGRES_DB_NAME --instance=$POSTGRES_DB_INSTANCE
else
    echo "[INFO] Database:$POSTGRES_DB_NAME already exists."
fi

# Enable "Google Cloud Memorystore for Redis API" if not enabled
redisApi=$(gcloud services list | grep redis)

if [ -z "$redisApi" ]; then
    echo "[INFO] Redis API is not enabled for project. Enabling it now."
    gcloud services enable redis.googleapis.com
else
    echo "[INFO] Redis API is enabled for project."
fi

# Create a redis cache instance if not present already
gcloud redis instances describe $PROJECT_ID --region $REGION

if [ $? != 0 ]; then
    echo "[INFO] Redis instance doesnt exist. Creating one."
    gcloud redis instances create $PROJECT_ID --region $REGION
else
    echo "[INFO] Redis instances already exists"
fi

# Create Pubsub topics and subscriptions as needed
topicNameArray=("feed_item-updated" "sport_structure-updated" "invitation-updated" "user-updated" "team_migration-updated" "challenge-updated")

for topicName in ${topicNameArray[*]}; do
    gcloud pubsub topics describe $topicName --project $PROJECT_ID

    if [ $? != 0 ]; then
        echo "[INFO] Topic:$topicName doesnt exist in PROJECT_ID:$PROJECT_ID. Creating one"
        gcloud pubsub topics create $topicName --project $PROJECT_ID
    else
        echo "[INFO] Topic:$topicName already exists."
    fi
done

# Deploy any Cloud Functions if exist

# Deploy the project
# NOTE: Commenting this line for now. Uncomment later 
# mvn clean package appengine:deploy -Dspring.profiles.active=qa -DskipTests=true

