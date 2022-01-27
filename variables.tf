variable "container_name" {
  description = "The name of the container."
  type = string
  default = "universal-container"
}

variable "container_user" {
  description = "The user name the container will use. Mutually exclusive with container_uid."
  type = string
  default = null
}

variable "container_uid" {
  description = "The user id the container will use. Mutually exclusive with container_user."
  type = number
  default = null
}

variable "container_group" {
  description = "The group name or GID the container will use. Mutually exclusive with container_gid."
  type = string
  default = null
}

variable "container_gid" {
  description = "The group GID the container will use. Mutually exclusive with container_group."
  type = number
  default = null
}

variable "image_uri" {
  description = "Container image tag in the form image:tag."
  type = string
}

variable "labels" {
  description = "Labels to apply to the container."
  type = list(string)
  default = []
}

variable "ports" {
  description = "Ports to expose from the container."
  type =list(object({
    host_port = number
    container_port = number
  }))
  default = []
}

variable "environment_variables" {
  description = "Additional environment variables to set inside the container."
  type = map(string)
  default = {}
  sensitive = true
}

variable "volume_binds" {
  description = "Volumes to bind in the container."
  type = list(object({
    host_dir = string
    container_dir = string
    options = optional(string)
  }))
  default = []
}

variable "args" {
  description = "Arguments to pass to the container when executing podman run."
  type = string
  default = null
  sensitive = true
}

variable "files" {
  description = "Additional files to create on the CoreOS host."
  type = list(object({
    path = string
    contents = string
    decimal_mode = string
    uid = optional(number)
    user_name = optional(string)
    gid = optional(number)
    group_name = optional(string)
  }))
  default = []
  sensitive = true
}

variable "directories" {
  description = "Additional directories to create on the CoreOS host."
  type = list(object({
    path = string
    decimal_mode = string
    uid = optional(number)
    user_name = optional(string)
    gid = optional(number)
    group_name = optional(string)
  }))
  default = []
}

variable "systemd_afters" {
  description = "Systemd targets or services to include in After= directives for the container systemd unit."
  type = list(string)
  default = []
}

