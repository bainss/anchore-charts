#!/bin/bash

# Usage: build.sh <target dir> <bucket w/prefix>
# Example: build.sh stable/ s3://charts.anchore.io

# This script will sync and rebuild the index.yaml for the repo of the specified directory
# This script requires:
# 1. the aws cli installed and configured with credentails sufficient to get, list, and push objects to the s3 bucket
# 2. helm installed and configured locally

dest_dir=$1
s3_bucket_path=$2
do_push=$3


echo Building charts in $dest_dir and merging with data from $s3_bucket_path
pushd $dest_dir

echo Syncing s3 data down
aws s3 sync s3://${s3_bucket_path} .

echo Generating packages
for chart_dir in $(find -maxdepth 1 -not -name '.*' -type d)
do
	echo Packaging ${chart_dir}
	helm package ${chart_dir}
done

helm repo index --merge index.yaml .


if [ "${do_push}" == "true" ]
then
	echo Syncing back up
	aws s3 sync ./*.tgz s3://${s3_bucket_path}
	aws s3 sync ./index.yaml s3://${s3_bucket_path}
else
	echo Skipping push
fi

