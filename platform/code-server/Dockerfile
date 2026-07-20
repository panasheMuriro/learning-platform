# Custom code-server image for the Juju + Terraform course lab workspace.
#
# Extends the official code-server image with Terraform pre-installed, so
# learners can run `terraform init/plan/apply/destroy` in the integrated
# terminal immediately — no extra setup required.
FROM codercom/code-server:latest

ARG TERRAFORM_VERSION=1.9.8

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl unzip ca-certificates \
    && ARCH="$(dpkg --print-architecture)" \
    && curl -fLO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" \
    && unzip "terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm "terraform_${TERRAFORM_VERSION}_linux_${ARCH}.zip" \
    && apt-get purge -y unzip \
    && rm -rf /var/lib/apt/lists/*

USER coder
