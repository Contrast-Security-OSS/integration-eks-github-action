FROM ubuntu

ARG contrast_security_credentials_file
ARG aws_credentials_file
ARG application_manifests
ARG application_dockerfile
ARG application_output_image_name_tag
ARG cluster_name
ARG application_artifact
ARG application_artifact_2

ENV APPLICATION_MANIFESTS ${application_manifests}   
ENV CONTRAST_SECURITY_CREDENTIALS_FILE ${contrast_security_credentials_file}
ENV AWS_CREDENTIALS_FILE ${aws_credentials_file}
ENV APPLICATION_DOCKERFILE ${application_dockerfile}
ENV APPLICATION_OUTPUT_IMAGE_NAME_TAG ${application_output_image_name_tag}
ENV CLUSTER_NAME ${cluster_name}
ENV APPLICATION_ARTIFACT ${application_artifact}
ENV APPLICATION_ARTIFACT_2 ${application_artifact_2}

RUN apt-get update
RUN apt-get install ca-certificates curl gnupg lsb-release unzip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
RUN aws --version
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN apt-get install docker-ce docker-ce-cli containerd.io
RUN docker version

COPY entrypoint-az.sh /opt/entrypoint.sh
COPY /application-dockerfile/Dockerfile /opt/Dockerfile
COPY /application-manifests/deployment.yaml /opt/deployment.yaml
COPY contrast_security.yaml /opt/contrast_security.yaml
COPY /application-dockerfile/${APPLICATION_ARTIFACT_2} /opt/${APPLICATION_ARTIFACT_2}

RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
