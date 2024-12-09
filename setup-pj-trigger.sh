#!/bin/bash

echo "Triggering the next prow job using git commit"

TRACKING_REPO=${REPO_OWNER}/${REPO_NAME}
while getopts ":r:" option; do
    case "${option}" in
        r)
            TRACKING_REPO=${OPTARG}
            ;;
    esac
done
shift $((OPTIND-1))

TRACKING_BRANCH=prow-job-tracking
FILE_TO_PUSH=job/${JOB_NAME}

./trigger-prow-job-from-git.sh -r ${TRACKING_REPO} \
-b ${TRACKING_BRANCH} -s ${PWD}/env/date.list -d ${FILE_TO_PUSH}

if [ $? -ne 0 ]
then
    echo "Failed to add the git commit to trigger the next job"
    exit 3
fi