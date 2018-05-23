# nginx-s3-cdn

This repository contains code to launch a simple S3 CDN/Proxy on AWS with the ability to perform
"Blue/Green" deployments

## Requirements

* Packer (https://www.packer.io/downloads.html)
* Terraform
* AWS CLI access (API Keys set)
* Bash

## Usage

Building the image is done with Packer.  Deploying the image is done with terraform

### Packer

Packer config code lives in the **packer** directory with the main manifest being **cdn-manifest.json**
with variables configured in the external file **variables.json**

To build the packer image, first ensure you have AWS API keys set in either your environment or via AWS SDK.

To configure via environment variables, do the following

```
export AWS_ACCESS_KEY_ID=your-aws-access-key-id
export AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
export AWS_DEFAULT_REGION=eu-west-1

```

To build a script in the root of the directory can be run

```
O_O..<$> ./build-packer.sh
amazon-ebs output will be in this color.

==> amazon-ebs: Prevalidating AMI Name: cdn-amazon-linux 1526992576
    amazon-ebs: Found Image ID: ami-ca0135b3
==> amazon-ebs: Creating temporary keypair: packer_5b040ec0-e90b-ef63-f758-48845297a6dd
==> amazon-ebs: Creating temporary security group for this instance: packer_5b040ec4-0d3e-65b5-34c7-fde38ac64bd4
==> amazon-ebs: Authorizing access to port 22 from 0.0.0.0/0 in the temporary security group...
==> amazon-ebs: Launching a source AWS instance...
==> amazon-ebs: Adding tags to source instance
    amazon-ebs: Adding tag: "Name": "Packer Builder"
    amazon-ebs: Instance ID: i-0ff6689d6b52602cd
==> amazon-ebs: Waiting for instance (i-0ff6689d6b52602cd) to become ready...
==> amazon-ebs: Waiting for SSH to become available...
==> amazon-ebs: Connected to SSH!
==> amazon-ebs: Uploading files => /home/ec2-user
==> amazon-ebs: Provisioning with shell script: provision.sh
    amazon-ebs: Loaded plugins: priorities, update-motd, upgrade-helper
    amazon-ebs: Resolving Dependencies
    amazon-ebs: --> Running transaction check
...

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
eu-west-1: ami-75fbc40c

The build has completed.  Please find your AMI details above
```


## Terraform

The terraform config in this repo will deploy:

* 1 ELB
* A green and blue launch config
* A green and blue auto scaling group

### Configuration

All config is done in `terraform/variables.tfvars` with mapping file `terraform/variables.tf`

```
variable "aws_access_key"       type = "string"
variable "aws_secret_key"       type = "string"
variable "aws_default_region"   type = "string"
variable "ssh_key_name"         type = "string"
variable "iam_instance_profile" type = "string"
variable "vpc_id"               type = "string"
variable "vpc_zones"            type = "list"
variable "security_groups"      type = "list"
variable "volume"               type = "map"
variable "blue"                 type = "map"
variable "green"                type = "map"
variable "logstore"             type = "map"
```

### Deploying

A script has been included to make this easier

```
^_^..<$> ./deploy-terraform.sh

Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "aws" (1.19.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.aws: version = "~> 1.19"

Terraform has been successfully initialized!

...

Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_launch_configuration.blue-launch-config: Creating...

...

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
Terraform has completed with success


```

### Terraform State

The terraform state for this deployment can be found in the bucket **terraform-state-storage-bucket/cdn/terraform.state**

This is configured in **terraform/main.tf**

Ensure you have AWS credentials set before running anything, otherwise state will not download/update!

### Rolling upgrade

Edit the file `terraform/variables.tfvars` and update the next states AMI i.e. if you
are currently running instances in the green state, update the AMI in the blue state

Also, update the count in the blue deployment to 2min/2desired/8max

Now apply these changes

When new instances are fully in service scale down the green to 0/0/0 and re-apply terraform changes

#### Destroying

There is no script for this - its dangerous so if you want to destroy it all, you will have to manually run

```
cd terraform
terraform init
terraform destroy -var-file=variables.tfvars
aws_launch_configuration.blue-launch-config: Refreshing state... (ID: blue-launch-config)
aws_launch_configuration.green-launch-config: Refreshing state... (ID: green-launch-config)
aws_elb.cdn-elb: Refreshing state... (ID: cdn-elb)
aws_autoscaling_group.cdn-blue-asg: Refreshing state... (ID: cdn-blue-asg)
aws_autoscaling_group.cdn-green-asg: Refreshing state... (ID: cdn-green-asg)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  - aws_autoscaling_group.cdn-blue-asg

  - aws_autoscaling_group.cdn-green-asg

  - aws_elb.cdn-elb

  - aws_launch_configuration.blue-launch-config

  - aws_launch_configuration.green-launch-config


Plan: 0 to add, 0 to change, 5 to destroy.

Do you really want to destroy?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

...

Destroy complete! Resources: 5 destroyed.
```
