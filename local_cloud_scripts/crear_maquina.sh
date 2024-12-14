#!/bin/bash

gcloud compute instances create spark-local --zone=europe-southwest1-a \
--machine-type=e2-standard-4 --metadata-from-file startup-script=plantilla_cloud_local.sh