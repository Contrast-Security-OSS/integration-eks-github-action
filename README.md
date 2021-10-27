# eks-contrast-security-github-action

This github action builds and deploys a java application to the Amazon Elastic Kubernetes Service (EKS) with a Contrast Security Java Agent.

Other supported languages coming soon...

## Prerequisites

- An AWS User with enough permissions (IAM Roles) to: 
    - Deploy an application to Amazon Elasatic Kubernetes Service (EKS)
    - Deploy a volume
    - Create a secret 
- A valid Contrast Security account
- Prepopulated Contrast Security and Amazon AWS JSON objects - details within 'Inputs' section

## Inputs
- `aws-credentials-file`
  - Description: 'The configuration file contents for Amazon AWS-specific logins, regions, etc...'
  - REQUIRED: true
  - Default: No Default Value
  - Example:
    ```sh
    {
      "aws_access_key_id": "xxxxx",
      "aws_secret_access_key": "xxxxx",
      "aws_default_region": "xxxxx",
      "aws_container_registry": "xxxxx"
    }
    ```
- `contrast-security-credentials-file`
  - Description: 'The configuration file contents for the Contrast Security Java Agent - used to communication with Contrast Security Team Server'
  - REQUIRED: true
  - Default: No Default Value
  - Example:
    ```sh
    {
    "contrast_api_url": "xxxxx",
    "contrast_api_username": "xxxxx",
    "contrast_api_api_key": "xxxxx",
    "contrast_api_service_key": "xxxxx",
    "contrast_agent_java_standalone_app_name": "xxxxx",
    "contrast_application_version": "xxxxx"
    }
    ```
- `application-manifest`
  - Description: 'Application manifest file location required for kubernetes deployment'
  - REQUIRED: true
  - Default: No Default Value
- `application-dockerfile`
  - Description: 'dockerfile location required for docker build'
  - REQUIRED: true
  - Default: No Default Value
- `application-output-image-name-tag:
  - Description: 'output image name/tag that will be deployed to kubernetes cluster'
  - REQUIRED: true
  - Default: No Default Value
- `cluster-name`
  - Description: 'aks cluster name'
  - REQUIRED: true
  - Default: No Default Value
- `application-artifact`
  - Description: 'artifacts location associated with the docker build'
  - REQUIRED: false
  - Default: No Default Value

## Documentation

Can be found at these links:

> Note: `This section` is to be updated...

## Example Use

```sh
- name: Contrast Security EKS Build Deploy
        uses: Contrast-Security-OSS/eks-github-action@main
        id: contrast-build-deploy
        with:
          contrast-security-credentials-file: ${{ secrets.CONTRAST_CREDS_FILE }}
          aws-credentials-file: ${{ secrets.AWS_CREDS_FILE }}
          application-manifest: ${{ env.APPLICATION_MANIFEST }}
          application-dockerfile: ${{ env.APPLICATION_DOCKERFILE }}
          application-output-image-name-tag: ${{ env.IMAGE_NAME_TAG }}
          cluster-name: ${{ env.CLUSTER_NAME }}
          application-artifact: ${{ env.APPLICATION_ARTIFACT }}
```

## Development

> Note: `This section` is to be updated...
