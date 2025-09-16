variable "prism_central_endpoint" {
  description = "Prism Central endpoint (IP or FQDN)"
  type        = string
}

variable "prism_central_username" {
  description = "Prism Central username"
  type        = string
  default     = "admin"
}

variable "prism_central_password" {
  description = "Prism Central Password. Also used to set password for user VMs"
  type        = string
  sensitive   = true
}

variable "number_of_users" {
  description = "Number of users"
  type        = number
  default     = 10
}

variable "user_number" {
  description = "User number to start from. Use if contiguous numbering is required across multiple clusters."
  type        = number
  default     = 1
}

variable "image_name" {
  description = "Source image to clone student VMs from. Needs uploading to cluster first. Must be Rocky Linux."
  type        = string
  default     = "Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
}

variable "subnet_name" {
  description = "Name of the subnet to attach user VMs to"
  type        = string
}

variable "user_vm_name_prefix" {
  description = "Prefix for naming user VMs"
  type        = string
  default     = "BootcampVM-User"
}
