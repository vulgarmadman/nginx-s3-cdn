#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM="terraform"
VAR_FILE="$DIR/terraform/variables.tfvars"

command -v $PACKER > /dev/null

if [ $? -eq 1 ]; then
    echo "Hashicorp Terraform is required https://www.terraform.io/downloads.html and must be set in your path"
    echo "will exit now..."
    exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "WARNING: You do not have an AWS_SECRET_ACCESS_KEY set in your environment."
    echo "         This can be ignored if your using an IAM profile or using the AWS CLI"

fi
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "WARNING: You do not have an AWS_ACCESS_KEY_ID set in your environment."
    echo "         This can be ignored if your using an IAM profile or using the AWS CLI"

fi

cd $DIR/terraform
$TERRAFORM init
if [ $? -eq 1 ]; then
    echo "Failed to initialise terraform. Check for errors and retry"
    exit 1
fi
$TERRAFORM plan -var-file $VAR_FILE
if [ $? -eq 1 ]; then
    echo "Failed to plan - check for issues and retry"
    exit 1
fi
$TERRAFORM apply -var-file $VAR_FILE
if [ $? -eq 0 ]; then
    echo
    echo "Terraform has completed with success"
    echo
    exit 0
else
    echo
    echo "Terraform apply of the plan did not work!"
    echo
    exit 1
fi
