# nginx-s3-cdn

This repository contains code to launch a simple S3 CDN/Proxy on AWS with the ability to perform
"Blue/Green" deployments

This CDN is then best hidden behind a reverse proxy service like the almighty https://www.cloudflare.com

SSL is also supported, but will require a few tweeks to the config which is detailed below

## Details

Once launched, by default the AWS ELB DNS will return the following:

```
^_^..<$> curl http://cdn-elb-0000000000.eu-west-1.elb.amazonaws.com/
ok

^_^..<$> curl http://cdn-elb-0000000000.eu-west-1.elb.amazonaws.com/nginx_status
Active connections: 37
server accepts handled requests
 69046 69046 1666393
Reading: 0 Writing: 1 Waiting: 36
```

Now, to make use of the CDN functionality, create an S3 bucket with the url of your domain
i.e. www.your-domain.com and create a CNAME to your ELB DNS hostname.

The nginx config file `packer/files/sites-enables/com.conf` will by default forward any .co.uk, .com, .org + .net
domains back to an S3 bucket of the same name.

If you are running in **eu-west** region of AWS (as I am) it will just work.  If you are in any other region alter the location in `packer/files/sites-enables/com.conf` to match your region

## Requirements

* Packer (https://www.packer.io/downloads.html)
* Terraform
* AWS CLI access (API Keys set)
* Bash

## Usage

Building the image is done with Packer.  Deploying the image is done with terraform

## Packer

Packer config code lives in the **packer** directory with the main manifest being **cdn-manifest.json**
with variables configured in the external file **variables.json**

To build the packer image, first ensure you have AWS API keys set in either your environment or via AWS SDK.

To configure via environment variables, do the following

```
export AWS_ACCESS_KEY_ID=your-aws-access-key-id
export AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
export AWS_DEFAULT_REGION=eu-west-1

```

### Configuration

The packer build can be configured via the standalone variables file `packer/variables.json`

```
aws_access_key       AWS access key id can be placed here, but see above for alternative approach
aws_secret_key       AWS secret key can be placed here, but see above for alternative approach
aws_region           AWS default regions
ami_name             The name to tag the AMI
ami_description      Description of the AMI
source_ami           The source AMI - Amazon Linux is highly recommended
instance_type        Instance size to spin up
ssh_username         SSH username - usually ec2-user
vpc_id               VPC id to launch the instance in
subnet_id            Subnet id to launch the instance in
enable_ssl           Enable SSL - see below for SSL details
```

### Build

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

## SSL

SSL on this build is disabled by default.  To enable SSL, edit the `packer/variables.json` file and set `enable_ssl="true"`

Add your private key and ssl certificate to the SSL directory and edit the `packer/files/sites-enables/ssl-com.conf`
file to match your certificate and domain.

The current `packer/files/sites-enables/ssl-com.conf` is configured to work out of the box on port 443 with cloudflare
with the addition of edge certificates which can be generated from your console.

Nginx SSL configuration details can also be found at http://nginx.org/en/docs/http/configuring_https_servers.html

## Terraform

The terraform config in this repo will deploy:

* 1 ELB
* A green and blue launch config
* A green and blue auto scaling group
* Policies to autoscale up/down on load



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

### Destroying

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
