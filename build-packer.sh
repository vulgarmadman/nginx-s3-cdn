#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACKER="packer"
TEMPLATE="$DIR/packer/cdn-manifest.json"
VAR_FILE="$DIR/packer/variables.json"

command -v $PACKER > /dev/null

if [ $? -eq 1 ]; then
    echo "Hashicorp Packer is required https://www.packer.io/downloads.html and must be set in your path"
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

cd $DIR/packer
$PACKER build -var-file $VAR_FILE $TEMPLATE

if [ $? -eq 0 ]; then
    echo "The build has completed.  Please find your AMI details above"
    echo
    exit 0
else
    echo "Something went wrong with the build, please check the above output for more details"
    echo
    exit 1
fi
