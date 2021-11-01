#!/bin/sh -l

set -x

AWS_CREDENTIALS_FILE=${1}
CONTRAST_SECURITY_CREDENTIALS_FILE=${2}
APPLICATION_MANIFESTS=${3}
APPLICATION_DOCKERFILE=${4}
APPLICATION_OUTPUT_IMAGE_NAME_TAG=${5}
CLUSTER_NAME=${6}
APPLICATION_ARTIFACT=${7}

# echo "printing environment variables..."
#echo "--------------------------------------------------"
# printenv
#echo "--------------------------------------------------"

echo "splitting application-artifact into application-artifact-2 for filenames..."
APPLICATION_ARTIFACT_2="$(basename ${APPLICATION_ARTIFACT})"
echo "Artifact filename is $APPLICATION_ARTIFACT_2"
echo "---------------------------------------------------"

# echo "file system..."
# ls -a
echo "creating file locations..."
mkdir /usr/bin/docker-action/application-dockerfile/
mkdir /usr/bin/docker-action/application-manifests/
echo "copying user-defined dockerfile into container filesystem..."
cp /github/workspace/${APPLICATION_DOCKERFILE} /usr/bin/docker-action/application-dockerfile/Dockerfile
echo "copying user-defined application files into container filesystem..."
cp /github/workspace/${APPLICATION_ARTIFACT} /usr/bin/docker-action/application-dockerfile/${APPLICATION_ARTIFACT_2}
echo "copying user-defined kubernetes manifests into container filesystem..."
cp /github/workspace/${APPLICATION_MANIFESTS} /usr/bin/docker-action/application-manifests/deployment.yaml
#echo "entering docker-action directory..."
cd /usr/bin/docker-action
#echo "what is inside - docker-action..."
#ls -l
echo "what is inside - application-dockerfile..."
cd /usr/bin/docker-action/application-dockerfile/
#ls -l
echo "------------------------------------------"
cat /usr/bin/docker-action/application-dockerfile/Dockerfile
echo "------------------------------------------"
echo "what is inside - application-manifests..."
cd /usr/bin/docker-action/application-manifests/
#ls -l
echo "------------------------------------------"
cat /usr/bin/docker-action/application-manifests/deployment.yaml
echo "------------------------------------------"

#echo "go into build directory..."
cd /usr/bin/docker-action

#echo "creating docker image with the following inputs..."
#echo "--------------------------------------------------"
#echo "aws-credentials-file: $AWS_CREDENTIALS_FILE"
#echo "contrast-security-credentials-file: $CONTRAST_SECURITY_CREDENTIALS_FILE"
#echo "azure-application-name: $APPLICATION_MANIFESTS"
#echo "--------------------------------------------------"

echo "running docker build with passed arguments..."
#echo "--------------------------------------------------"

# here we can make the construction of the image as customizable as we need
# and if we need parameterizable values it is a matter of sending them as inputs
docker build -t docker-action --build-arg contrast_security_credentials_file="$CONTRAST_SECURITY_CREDENTIALS_FILE" --build-arg aws_credentials_file="$AWS_CREDENTIALS_FILE" --build-arg application_manifests="/usr/bin/docker-action/application-manifests/deployment.yaml" --build-arg application_dockerfile="/usr/bin/docker-action/application-dockerfile/Dockerfile" --build-arg application_output_image_name_tag="$APPLICATION_OUTPUT_IMAGE_NAME_TAG" --build-arg cluster_name="$CLUSTER_NAME" --build-arg application_artifact="$APPLICATION_ARTIFACT" --build-arg application_artifact_2="$APPLICATION_ARTIFACT_2" . && docker run -v /var/run/docker.sock:/var/run/docker.sock docker-action
