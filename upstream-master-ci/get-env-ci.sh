set -o allexport
# Clone the moby repository
git clone https://github.com/moby/moby.git

PATH_COS="/mnt"
PATH_PASSWORD="/root/.s3fs_cos_secret"

COS_BUCKET_PRIVATE="ppc64le-docker"
URL_COS_PRIVATE="https://s3.us-south.cloud-object-storage.appdomain.cloud"


# Mount the COS bucket if not mounted
if ! test -d ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}
then
    # Set up the s3 secret if not already configured
    if ! test -f ${PATH_PASSWORD}
    then
        echo ":${S3_SECRET_AUTH}" > ${PATH_PASSWORD}
        chmod 600 ${PATH_PASSWORD}
    fi
    mkdir -p ${PATH_COS}/s3_${COS_BUCKET_PRIVATE}
    s3fs ${COS_BUCKET_PRIVATE} ${PATH_COS}/s3_${COS_BUCKET_PRIVATE} -o url=${URL_COS_PRIVATE} -o passwd_file=${PATH_PASSWORD} -o ibm_iam_auth
fi