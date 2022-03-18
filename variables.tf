variable "name" {
  description = "The name of the container."
  type = string
}

variable "container_user" {
  description = "The user name the container will use. Mutually exclusive with container_uid."
  type = string
  default = null
}

variable "container_uid" {
  description = "The user id the container will use. Mutually exclusive with user."
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

variable "image" {
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

variable "volumes" {
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

variable "pod" {
  description = "The pod to run the container in"
  type = string
  default = null
}

variable "user" {
  description = "The user systemd will run the container under."
  type = string
  default = "core"
}

variable "systemd_afters" {
  description = "Targets or services to include in the After= directives for the container systemd unit."
  type = list(string)
  default = []
}

variable "systemd_start_limit_burst" {
  description = "Units which are started more than burst times within an interval time span are not permitted to start any more."
  type = number
  default = 5
}

variable "systemd_start_limit_interval" {
  description = "Units which are started more than burst times within an interval time span are not permitted to start any more."
  type = number
  default = 60
}

variable "systemd_restart_sec" {
  description = "Configures the time to sleep before restarting a service."
  type = number
  default = 30
}

variable "systemd_timeout_start_sec" {
  description = "Configures the time to wait for start-up."
  type = number
  default = 20
}

variable "systemd_oneshots" {
  description = "Systemd oneshot services to create."
  type = list(object({
    exec_start_script_path = string
  }))
  default = []
}

# Avoid non-alphanumeric characters for disk.label and disk.mount_path
# or the systemd unit naming convention and proper escaping gets complicated
# https://unix.stackexchange.com/a/345518/412527
variable "disks" {
  type = list(object({
    device = string
    label = string
    mount_path = string
  }))
  default = []
}

variable "files" {
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

variable "directories" {
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
