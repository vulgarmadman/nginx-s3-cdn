terraform {
    backend "s3" {
        bucket = "terraform-state-storage-bucket"
        key    = "cdn/terraform.state"
        region = "eu-west-1"
    }
}
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.aws_default_region}"
}

# Elastic Load Balancer
resource "aws_elb" "cdn-elb" {
    name                  = "cdn-elb"
    subnets               = [ "${var.vpc_zones}" ]
    security_groups       = [ "${var.security_groups}" ]
    listener {
        instance_port     = "${var.loadbalancer["instance_port"]}"
        instance_protocol = "${var.loadbalancer["instance_protocol"]}"
        lb_port           = "${var.loadbalancer["lb_port"]}"
        lb_protocol       = "${var.loadbalancer["lb_protocol"]}"
    }
    health_check {
      healthy_threshold   = "2"
      unhealthy_threshold = "2"
      timeout             = "3"
      target              = "${var.loadbalancer["health_check"]}"
      interval            = "5"
    }
    access_logs {
        bucket        = "${var.logstore["bucket"]}"
        bucket_prefix = "${var.logstore["prefix"]}"
        interval      = "${var.logstore["time"]}"
    }
    idle_timeout = "60"
}

# Launch Configurations
# Green
resource "aws_launch_configuration" "green-launch-config" {
    name                 = "green-launch-config"
    image_id             = "${var.green["ami_id"]}"
    instance_type        = "${var.green["instance_type"]}"
    key_name             = "${var.ssh_key_name}"
    iam_instance_profile = "${var.iam_instance_profile}"
    security_groups      = [ "${var.security_groups}" ]
    root_block_device    = {
        delete_on_termination = "${var.volume["delete"]}"
        volume_type           = "${var.volume["type"]}"
        volume_size           = "${var.volume["size"]}"
    }

    lifecycle {
        create_before_destroy = false
    }
}
# Blue
resource "aws_launch_configuration" "blue-launch-config" {
    name                 = "blue-launch-config"
    image_id             = "${var.blue["ami_id"]}"
    instance_type        = "${var.blue["instance_type"]}"
    key_name             = "${var.ssh_key_name}"
    iam_instance_profile = "${var.iam_instance_profile}"
    security_groups      = [ "${var.security_groups}" ]
    root_block_device    = {
        delete_on_termination = "${var.volume["delete"]}"
        volume_type           = "${var.volume["type"]}"
        volume_size           = "${var.volume["size"]}"
    }

    lifecycle {
        create_before_destroy = false
    }
}
# Autoscaling Groups
# Green
resource "aws_autoscaling_group" "cdn-green-asg" {
    name                 = "cdn-green-asg"
    launch_configuration = "${aws_launch_configuration.green-launch-config.name}"
    min_size             = "${var.green["min"]}"
    desired_capacity     = "${var.green["min"]}"
    max_size             = "${var.green["max"]}"
    vpc_zone_identifier  = [ "${var.vpc_zones}" ]
    load_balancers       = [
        "${aws_elb.cdn-elb.name}"
    ]
    tag {
        key                 = "name"
        value               = "cdn-node"
        propagate_at_launch = true
    }
    tag {
        key                 = "deployment-state"
        value               = "green"
        propagate_at_launch = true
    }
}
resource "aws_autoscaling_policy" "high-cpu-green" {
    name                   = "high-cpu-green"
    autoscaling_group_name = "${aws_autoscaling_group.cdn-green-asg.name}"
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = "1"
    cooldown               = "300"
    policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "high-cpu-green" {
    alarm_name                 = "high-cpu-green"
    alarm_description          = "high-cpu-green"
    comparison_operator        = "GreaterThanOrEqualToThreshold"
    evaluation_periods         = "2"
    metric_name                = "CPUUtilization"
    namespace                  = "AWS/EC2"
    period                     = "60"
    statistic                  = "Average"
    threshold                  = "60"
    dimensions                 = {
        "AutoScalingGroupName" = "${aws_autoscaling_group.cdn-green-asg.name}"
    }
    actions_enabled            = true
    alarm_actions              = [
        "${aws_autoscaling_policy.high-cpu-green.arn}"
    ]
}
resource "aws_autoscaling_policy" "low-cpu-green" {
    name                   = "low-cpu-green"
    autoscaling_group_name = "${aws_autoscaling_group.cdn-green-asg.name}"
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = "-1"
    cooldown               = "300"
    policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "low-cpu-green" {
    alarm_name                 = "low-cpu-green"
    alarm_description          = "low-cpu-green"
    comparison_operator        = "LessThanOrEqualToThreshold"
    evaluation_periods         = "2"
    metric_name                = "CPUUtilization"
    namespace                  = "AWS/EC2"
    period                     = "60"
    statistic                  = "Average"
    threshold                  = "10"
    dimensions                 = {
        "AutoScalingGroupName" = "${aws_autoscaling_group.cdn-green-asg.name}"
    }
    actions_enabled            = true
    alarm_actions              = [
        "${aws_autoscaling_policy.low-cpu-green.arn}"
    ]
}
# Blue
resource "aws_autoscaling_group" "cdn-blue-asg" {
    name                 = "cdn-blue-asg"
    launch_configuration = "${aws_launch_configuration.green-launch-config.name}"
    min_size             = "${var.blue["min"]}"
    desired_capacity     = "${var.blue["min"]}"
    max_size             = "${var.blue["max"]}"
    vpc_zone_identifier  = [ "${var.vpc_zones}" ]
    load_balancers       = [
        "${aws_elb.cdn-elb.name}"
    ]
    tag {
        key                 = "Name"
        value               = "cdn-node"
        propagate_at_launch = true
    }
    tag {
        key                 = "deployment-state"
        value               = "blue"
        propagate_at_launch = true
    }
}
resource "aws_autoscaling_policy" "high-cpu-blue" {
    name                   = "high-cpu-blue"
    autoscaling_group_name = "${aws_autoscaling_group.cdn-blue-asg.name}"
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = "1"
    cooldown               = "300"
    policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "high-cpu-blue" {
    alarm_name                 = "high-cpu-blue"
    alarm_description          = "high-cpu-blue"
    comparison_operator        = "GreaterThanOrEqualToThreshold"
    evaluation_periods         = "2"
    metric_name                = "CPUUtilization"
    namespace                  = "AWS/EC2"
    period                     = "120"
    statistic                  = "Average"
    threshold                  = "60"
    dimensions                 = {
        "AutoScalingGroupName" = "${aws_autoscaling_group.cdn-blue-asg.name}"
    }
    actions_enabled            = true
    alarm_actions              = [
        "${aws_autoscaling_policy.high-cpu-blue.arn}"
    ]
}
resource "aws_autoscaling_policy" "low-cpu-blue" {
    name                   = "low-cpu-blue"
    autoscaling_group_name = "${aws_autoscaling_group.cdn-blue-asg.name}"
    adjustment_type        = "ChangeInCapacity"
    scaling_adjustment     = "-1"
    cooldown               = "300"
    policy_type            = "SimpleScaling"
}
resource "aws_cloudwatch_metric_alarm" "low-cpu-blue" {
    alarm_name                 = "low-cpu-blue"
    alarm_description          = "low-cpu-blue"
    comparison_operator        = "LessThanOrEqualToThreshold"
    evaluation_periods         = "2"
    metric_name                = "CPUUtilization"
    namespace                  = "AWS/EC2"
    period                     = "120"
    statistic                  = "Average"
    threshold                  = "10"
    dimensions                 = {
        "AutoScalingGroupName" = "${aws_autoscaling_group.cdn-blue-asg.name}"
    }
    actions_enabled            = true
    alarm_actions              = [
        "${aws_autoscaling_policy.low-cpu-blue.arn}"
    ]
}

output "loadbalancer-dns" {
    value = "${aws_elb.cdn-elb.dns_name}"
}
