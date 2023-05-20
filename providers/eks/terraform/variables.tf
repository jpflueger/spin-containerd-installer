variable "name" {
    description = "The name of the EKS cluster"
    type        = string
}

variable "region" {
    description = "The AWS region to deploy to"
    type        = string
}

variable "tags" {
    description = "A map of tags to add to all resources"
    type        = map(string)
    default = {}
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type        = string
}