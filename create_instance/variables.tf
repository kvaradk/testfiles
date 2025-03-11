variable "compartment_id" {
  type        = string
  description = "OCID of compartment for Compute Instance"
}

variable "subnet_id" {
  type        = string
  description = "OCID of the subnet for Compute Instance"
}

variable "display_name" {
  type        = string
  description = "Display Name Of Compute Instance"
  default = "Test Instance"
}

variable "availability_domain" {
  type = string
  description = "Region based Availability Domain to place the Compute Instance"
}

variable "image_id" {
  type        = string
  description = "Image Id"
}