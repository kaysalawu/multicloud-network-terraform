
variable "tf_service_account" {
  description = "service account to impersonate"
  default     = null
}

variable "prefix" {
  description = "prefix used for all resources"
  default     = ""
}

variable "project_id" {
  description = "hub project id"
}

