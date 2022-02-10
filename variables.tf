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

variable "container_image_uri" {
  description = "Container image tag in the form image:tag."
  type = string
}

variable "container_labels" {
  description = "Labels to apply to the container."
  type = list(string)
  default = []
}

variable "container_ports" {
  description = "Ports to expose from the container."
  type =list(object({
    host_port = number
    container_port = number
  }))
  default = []
}

variable "container_environment_variables" {
  description = "Additional environment variables to set inside the container."
  type = map(string)
  default = {}
  sensitive = true
}

variable "container_volume_binds" {
  description = "Volumes to bind in the container."
  type = list(object({
    host_dir = string
    container_dir = string
    options = optional(string)
  }))
  default = []
}

variable "container_args" {
  description = "Arguments to pass to the container when executing podman run."
  type = string
  default = null
  sensitive = true
}

variable "container_systemd_afters" {
  description = "Systemd targets or services to include in After= directives for the container systemd unit."
  type = list(string)
  default = []
}

# Avoid non-alphanumeric characters for disk.label and disk.mount_path
# or the systemd unit naming convention and proper escaping gets complicated
# https://unix.stackexchange.com/a/345518/412527
variable "coreos_disks" {
  type = list(object({
    device = string
    label = string
    mount_path = string
  }))
  default = []
}

variable "coreos_files" {
  description = "Additional files to create on the CoreOS host."
  type = list(object({
    path = string
    decimal_mode = optional(string)
    uid = optional(number)
    user_name = optional(string)
    gid = optional(number)
    group_name = optional(string)
    contents = string
  }))
  default = []
  sensitive = true
}

variable "coreos_directories" {
  description = "Additional directories to create on the CoreOS host."
  type = list(object({
    path = string
    decimal_mode = optional(string)
    uid = optional(number)
    user_name = optional(string)
    gid = optional(number)
    group_name = optional(string)
  }))
  default = []
}
