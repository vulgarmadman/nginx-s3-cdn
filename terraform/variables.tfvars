aws_access_key=""
aws_secret_key=""
aws_default_region="eu-west-1"
ssh_key_name=""
iam_instance_profile=""
vpc_zones = []
security_groups = []
vpc_id = ""
volume = {
    type   = "gp2"
    delete = "true"
    size   = "10"
}
blue = {
    ami_id        = ""
    instance_type = "t2.small"
    max           = "2"
    min           = "1"
}
green = {
    ami_id        = ""
    instance_type = "t2.small"
    max           = "0"
    min           = "0"
}
logstore = {
    bucket = "terraform-state-storage-bucket"
    prefix = "elb"
    time   = "5"
}
loadbalancer = {
    instance_protocol = "HTTP"
    instance_port     = "80"
    lb_protocol       = "HTTP"
    lb_port           = "80"
    health_check      = "HTTP:80/nginx_status"
}
