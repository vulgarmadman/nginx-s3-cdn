variable "aws_access_key" {
    type = "string"
}
variable "aws_secret_key" {
    type = "string"
}
variable "aws_default_region" {
    type = "string"
}
variable "ssh_key_name" {
    type = "string"
}
variable "iam_instance_profile" {
    type = "string"
}
variable "vpc_zones" {
    type = "list"
}
variable "security_groups" {
    type = "list"
}
variable "vpc_id" {
    type = "string"
}
variable "volume" {
    type = "map"
}
variable "blue" {
    type = "map"
}
variable "green" {
    type = "map"
}
variable "logstore" {
    type = "map"
}
variable "loadbalancer" {
    type = "map"
}
