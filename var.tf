variable "aws_region" {
  description = "This is aws region"
  default     = "us-east-2"
  type        = string
}
variable "profile" {
  description = "user account to use"
  default     = "default"
}

variable "aws_instance_type_server" {
  description = "This is aws ec2 type "
  default     = "t2.xlarge"
  type        = string
}
variable "aws_instance_type_forwader" {
  description = "This is aws ec2 type "
  default     = "t2.medium"
  type        = string
}

variable "aws_key" {
  description = "Key in region"
  default     = "my_ec2_key"
  type        = string
}