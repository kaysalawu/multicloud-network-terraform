#!/bin/bash

export PROJECT_ID=ne-devksalawu-4tl7
export ZONE=europe-west1-b

kubectl delete pod workload-identity -n default --ignore-not-found
kubectl delete serviceaccount workload-id-demo-k8s-sa -n default --ignore-not-found
gcloud iam service-accounts delete workload-id-demo-gcp-sa@$PROJECT_ID.iam.gserviceaccount.com --quiet
gcloud container clusters delete demo-gke-cluster --zone $ZONE --project $PROJECT_ID --quiet
