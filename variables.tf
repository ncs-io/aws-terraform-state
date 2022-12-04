variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "use_kms" {
  type    = bool
  default = true
}

variable "log_events" {
  type    = bool
  default = false
}