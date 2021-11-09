#!/bin/bash

set -x

#echo "Printing existing environment variables..."
#echo "------------------------------------------"
#printenv
#echo "------------------------------------------"

#echo "creating environment variables from coded constants..."
#echo "-------------------------------------------"
export AWS_CONTRAST_JAVA_AGENT_DOWNLOAD_URL="https://repository.sonatype.org/service/local/artifact/maven/redirect?r=central-proxy&g=com.contrastsecurity&a=contrast-agent&v=LATEST"
#echo "-------------------------------------------"

# echo "mapping environment variables to inputs..."

if [ -z "$CONTRAST_SECURITY_CREDENTIALS_FILE" ]; then
    printf '%s\n' "No Contrast Security credentials file passed via input." >&2
    exit 1
else
#    echo "Contrast Security credentials file found. "
    echo "----------------------------------------"
    echo "$CONTRAST_SECURITY_CREDENTIALS_FILE" >> contrast.json
#    echo "contrast_security_credentials_file value:"
#    cat contrast.json
#    cat contrast.json | jq '.'
    echo "Contrast Security credentials file found"
    echo "parsing configuration file and setting to environment variables..."
#    echo "quick test"
#    echo "-----------"
#    cat contrast.json | jq -r '.contrast_api_url'
    echo "mapping..."
    export CONTRAST_API_URL=$(cat contrast.json | jq -r '.contrast_api_url')
    export CONTRAST_API_USERNAME=$(cat contrast.json | jq -r '.contrast_api_username')
    export CONTRAST_API_API_KEY=$(cat contrast.json | jq -r '.contrast_api_api_key')
    export CONTRAST_API_SERVICE_KEY=$(cat contrast.json | jq -r '.contrast_api_service_key')
    export CONTRAST_AGENT_JAVA_STANDALONE_APP_NAME=$(cat contrast.json | jq -r '.contrast_agent_java_standalone_app_name')
    export CONTRAST_APPLICATION_VERSION=$(cat contrast.json | jq -r '.contrast_application_version')
    echo "parsing and mapping complete."
#    echo "removing contrast.json..."
    rm -f contrast.json
    echo "-----------------------------"
fi

# echo "results:"
# echo "contrast-api-url: $CONTRAST_API_URL"
# echo "contrast-api-username: $CONTRAST_API_USERNAME"
# echo "contrast-api-api-key: $CONTRAST_API_API_KEY"
# echo "contrast-api-service-key: $CONTRAST_API_SERICE_KEY"
# echo "contrast-agent-java-standalone-app-name: $CONTRAST_AGENT_JAVA_STANDALONE_APP_NAME"
# echo "contrast-application-version: $CONTRAST_APPLICATION_VERSION"
# echo "---------------------------------"

if [ -z "$AWS_CREDENTIALS_FILE" ]; then
    printf '%s\n' "No AWS credentials file passed via input." >&2
    exit 1
else
    echo "$AWS_CREDENTIALS_FILE" >> aws.json
#    echo "aws_credentials_file value:"
#    cat aws.json
#    cat aws.json | jq '.'
    echo "AWS configuration file found"
    echo "parsing configuration file and setting to environment variables..."
#    echo "quick test"
#    echo "-----------"
#    -- UPDATE cat aws.json | jq -r '.aws_tenant_id'
    echo "mapping and configuring aws cli..."
    export AWS_CONTAINER_REGISTRY=$(cat aws.json | jq -r '.aws_container_registry')
    export AWS_ACCESS_KEY_ID=$(cat aws.json | jq -r '.aws_access_key_id')
    export AWS_SECRET_ACCESS_KEY=$(cat aws.json | jq -r '.aws_secret_access_key')
    export AWS_DEFAULT_REGION=$(cat aws.json | jq -r '.aws_region')
#    export AWS_CONTAINER_REGISTRY_USERNAME=$(cat aws.json | jq -r '.aws_container_registry_username')
    echo "parsing, mapping, and configuration complete."
#    echo "removing aws.json..."
    rm -f aws.json
    echo "-----------------------------"
fi

# echo "results:"
# echo "aws-container-registry: $AWS_CONTAINER_REGISTRY"
# echo "aws-access-key-id: $AWS_ACCESS_KEY_ID"
# echo "aws-secret-access-key: $AWS_SECRET_ACCESS_KEY"
# echo "aws-region: $AWS_DEFAULT_REGION"
# echo "---------------------------------"

#if [ -z "$APPLICATION_DOCKERFILE" ]; then
#    printf '%s\n' "No Dockerfile passed via input." >&2
#    exit 1
#fi

if [ -z "$APPLICATION_OUTPUT_IMAGE_NAME_TAG" ]; then
    printf '%s\n' "No docker image name/tag passed via input. Exiting..." >&2
    exit 1
#else
#   echo "docker image name/tag validation passed."
fi

if [ -z "$APPLICATION_MANIFESTS" ]; then
    printf '%s\n' "No kubernetes application manifests passed via input. Exiting..." >&2
    exit 1
#else
#   echo "docker image name/tag validation passed."
fi

# echo "printing environment variables for testing..."
# printenv
# echo "-------------------------------------------"

#echo "++Displaying '/opt/' directory contents..."
#echo "---------------------------------------------"
cd /opt
#ls -l
#echo "---------------------------------------------"
echo "++Displaying incoming Dockerfile contents..."
echo "---------------------------------------------"
cat Dockerfile
echo "---------------------------------------------"

# log into aws cli via credentials
echo "logging into aws cli..."
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
aws configure set region ${AWS_DEFAULT_REGION}
aws configure set output json
echo "successfully logged into aws cli"
echo "-------------------------------------------"

# docker build using passed application dockerfile and image name/tag
echo "++application docker build started..."
echo "-------------------------------------------"
docker build -t application-docker-image .
echo "++application docker build successfully completed."
echo "-------------------------------------------"

# download Contrast Security java agent
echo "++downloading contrast security java agent..."
#echo "-------------------------------------------"
curl -L "${AWS_CONTRAST_JAVA_AGENT_DOWNLOAD_URL}" -o contrast.jar
CONTRAST_URL=$(curl "${AWS_CONTRAST_JAVA_AGENT_DOWNLOAD_URL}" -s -L -I -o /dev/null -w '%{url_effective}')
echo $CONTRAST_URL
#CONTRAST_AGENT_VERSION=$(find . -name '*contrast-agent*' | grep -o '[0-9]*') 
echo "Contrast Security agent version is: $CONTRAST_AGENT_VERSION"
echo "++successfully downloaded contrast security java agent."
echo "-------------------------------------------"

# set up contrast-agent label
echo "checking agent type..."
if [[ "$CONTRAST_AGENT_NAME" == *".jar"*  ]]; then 
    echo "agent-type = JAVA"
    CONTRAST_AGENT_TYPE="JAVA"
fi

# inject contrast agent into new application image
echo "running container image..."
RUNNING_CONTAINER_ID=$(docker run -d --restart=always application-docker-image)
echo "waiting 5 seconds..."
sleep 5
echo "-------------------------------------------"
docker ps
echo "-------------------------------------------"
echo "creating directory inside running container..."
docker exec -i $RUNNING_CONTAINER_ID mkdir /opt/contrast
echo "injecting contrast security agent jar..."
docker cp contrast.jar $RUNNING_CONTAINER_ID:/opt/contrast/
echo "verifying file copy..."
docker exec -w /opt/contrast $RUNNING_CONTAINER_ID ls -l
echo "-------------------------------------------"

# create image from running container
echo "creating container image from running container..."
docker commit $RUNNING_CONTAINER_ID ${AWS_CONTAINER_REGISTRY}/${APPLICATION_OUTPUT_IMAGE_NAME_TAG}
echo "successfully created container image."
echo "verifying local docker image..."
echo "-------------------------------------------"
docker images
echo "-------------------------------------------"

# docker login to container registry url
echo "retrieving docker login and logging into docker registry using login password..."
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_CONTAINER_REGISTRY} 
echo "successfully logged into container registry."
echo "-------------------------------------------"

# docker push to registry url
echo "pushing image to container registry..."
docker push ${AWS_CONTAINER_REGISTRY}/${APPLICATION_OUTPUT_IMAGE_NAME_TAG}
echo "successfully pushed container image to registry."
echo "-------------------------------------------"

# install kubectl
#echo "++installing kubectl..."
#curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
#chmod +x ./kubectl
#mv ./kubectl /usr/local/bin/kubectl
#kubectl version
#echo "++successfully installed kubectl"
#echo "-------------------------------------------"

# configure kubectl to connect to EKS cluster
echo "++configuring kubectl..."
aws eks list-clusters
aws eks --region ${AWS_DEFAULT_REGION} update-kubeconfig --name ${CLUSTER_NAME}
echo "++successfully configured kubectl."
echo "-------------------------------------------"

# check cluster nodes
echo "++checking cluster nodes..."
kubectl get nodes
echo "checking existing deployments..."
echo "-------------------------------------------"
kubectl get deployments
echo "-------------------------------------------"

# deploy application into the Amazon Elastic Kubernetes Service platform
echo "++deploying application manifests..."
startDeploy='deployment.apps/'
endSD=' '
startService='service/'
echo "++Returning results from kubernetes deployment..."
echo "--------------------------------------------"
KUBECTL_RESULTS=$(kubectl apply -f '/opt/deployment.yaml')
#echo "---------------"
#echo $KUBECTL_RESULTS
#echo "---------------"
DEPLOYMENT_NAME=$(awk '$0=$2' FS="$startDeploy" RS="$endSD" <<< "$KUBECTL_RESULTS")
SERVICE_NAME=$(awk '$0=$2' FS="$startService" RS="$endSD"  <<< "$KUBECTL_RESULTS")
kubectl describe deployments $DEPLOYMENT_NAME
#CONTAINER_NAME=$(kubectl get deploy "$DEPLOYMENT_NAME" -o yaml)
CONTAINER_NAME=$(kubectl get deployments "$DEPLOYMENT_NAME" -o=jsonpath='{$.spec.template.spec.containers[:1].name}')
#echo $CONTAINER_NAME
echo "-------------------------------------------"

# update deployment with secret/environment variables and updated image
echo "updating deployment $DEPLOYMENT_NAME with environment variable JAVA_TOOL_OPTIONS..."
kubectl set env deployment/$DEPLOYMENT_NAME JAVA_TOOL_OPTIONS="-javaagent:/opt/contrast/contrast.jar" 
echo "updating deployment $DEPLOYMENT_NAME with environment variable CONTRAST__API__URL..."
kubectl set env deployment/$DEPLOYMENT_NAME CONTRAST__API__URL=${CONTRAST_API_URL} 
echo "updating deployment $DEPLOYMENT_NAME with environment variable CONTRAST__API__USER_NAME..."
kubectl set env deployment/$DEPLOYMENT_NAME CONTRAST__API__USER_NAME=${CONTRAST_API_USERNAME} 
echo "updating deployment $DEPLOYMENT_NAME with environment variable CONTRAST__API__API_KEY..."
kubectl set env deployment/$DEPLOYMENT_NAME CONTRAST__API__API_KEY=${CONTRAST_API_API_KEY} 
echo "updating deployment $DEPLOYMENT_NAME with environment variable JAVA_TOOL_OPTIONS..."
kubectl set env deployment/$DEPLOYMENT_NAME CONTRAST__API__SERVICE_KEY=${CONTRAST_API_SERVICE_KEY} 
echo "updating deployment $DEPLOYMENT_NAME with environment variable CONTRAST__AGENT__JAVA__STANDALONE_APP_NAME..."
kubectl set env deployment/$DEPLOYMENT_NAME CONTRAST__AGENT__JAVA__STANDALONE_APP_NAME=${CONTRAST_AGENT_JAVA_STANDALONE_APP_NAME} 
echo "updating deployment $DEPLOYMENT_NAME with environment variable CONTRAST__AGENT__LOGGER__STDERR..."
kubectl set env deployment/$DEPLOYMENT_NAME CONTRAST__AGENT__LOGGER__STDERR=true
echo "updating deployment $DEPLOYMENT_NAME with image..."
kubectl set image deployment/$DEPLOYMENT_NAME $CONTAINER_NAME=${AWS_CONTAINER_REGISTRY}/${APPLICATION_OUTPUT_IMAGE_NAME_TAG} -o yaml
echo "updating deployment with Contrast Security label..."
echo "Returning deployment(s)..."
echo "--------------------------------------------"
kubectl label --overwrite deployment $DEPLOYMENT_NAME contrast-secured=true contrast-agent-type=$CONTRAST_AGENT_TYPE contrast-assess=true contrast-protect=false contrast-oss=false contrast-application-url=coming-soon contrast-application-name=$CONTRAST_AGENT_JAVA_STANDALONE_APP_NAME contrast-application-version=$CONTRAST_AGENT_VERSION contrast-env=environment contrast-server=coming-soon -o yaml
echo "--------------------------------------------"
echo "++checking update-deployment status..."
echo "--------------------------------------------"
kubectl rollout status deployment $DEPLOYMENT_NAME
echo "--------------------------------------------"
echo "++confirming deployment details..."
echo "--------------------------------------------"
kubectl get deployments
echo "--------------------------------------------"
echo "++updated deployment $DEPLOYMENT_NAME container $CONTAINER_NAME image to ${AWS_CONTAINER_REGISTRY}/${APPLICATION_OUTPUT_IMAGE_NAME_TAG}"
echo "-------------------------------------------"

# get application endpoint for kubernetes deployment
echo "++retrieving endpoint information..."
AWS_APPLICATION_URL=$(kubectl describe svc $SERVICE_NAME)
echo "------------------------------------"
echo ${AWS_APPLICATION_URL}
external_ip=""
while [ -z $external_ip ]; do
  echo "Waiting for end point..."
  external_ip=$(kubectl get svc $SERVICE_NAME -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
  [ -z "$external_ip" ] && sleep 10
done
external_port=$(kubectl describe svc $SERVICE_NAME | grep 'Port:' | grep -v 'NodePort:' | grep -v 'TargetPort:' | grep -o '[0-9]*')
echo 'End point ready:'
echo "SECURED endpoint - HTTPS: https://$external_ip:$external_port"
echo "UNSECURED endpoint - HTTP: http://$external_ip:$external_port"
#echo "Contrast Security Application URL: https://${CONTRAST_API_URL}static/ng/index.html#/"
echo "-------------------------------------------"
echo "**************************************************************************"
echo "****Contrast Security has been successfully onboarded. Contrast Rocks!****"
echo "**************************************************************************"
