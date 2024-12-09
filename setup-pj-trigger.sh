#!/bin/bash


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

echo "Triggering the next prow job by adding a git commit to the \
${FILE_TO_PUSH} file on the ${TRACKING_BRANCH} branch of the \
${TRACKING_REPO} repository."

./trigger-prow-job-from-git.sh -r ${TRACKING_REPO} \
-b ${TRACKING_BRANCH} -s ${PWD}/env/date.list -d ${FILE_TO_PUSH}

if [ $? -ne 0 ]
then
    echo "Failed to add the git commit to trigger the next job"
    exit 3
fi