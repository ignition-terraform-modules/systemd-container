locals {
  container_user_or_uid = "%{ if var.container_user != null }${var.container_user}%{ else }%{ if var.container_uid != null }${var.container_uid}%{ else }%{ endif }%{ endif }"
  container_group_or_gid = "%{ if var.container_group != null }${var.container_group}%{ else }%{ if var.container_gid != null }${var.container_gid}%{ else }%{ endif }%{ endif }"
}

# Universal systemd service file
data template_file "universal_service" {
  template = <<-EOS
    [Unit]
    Description=${var.container_name}
    After=network-online.target
    Wants=network-online.target
    %{~ for target in var.systemd_afters ~}
    After=${target}
    %{~ endfor ~}

    [Service]
    TimeoutStartSec=0
    ExecStartPre=/bin/podman stop ${var.container_name} --ignore
    ExecStartPre=/bin/podman rm ${var.container_name} --ignore
    ExecStart=/bin/podman run \
      %{~ for label in var.labels ~}
      --label ${label} \
      %{~ endfor ~}
      --env-file /etc/${var.container_name}/${var.container_name}.env \
      %{~ for volume_bind in var.volume_binds ~}
      -v ${volume_bind.host_dir}:${volume_bind.container_dir}%{ if volume_bind.options != null }:${volume_bind.options}%{ endif } \
      %{~ endfor ~}
      %{~ for port in var.ports ~}
      -p ${port.host_port}:${port.container_port} \
      %{~ endfor ~}
      %{~ if local.container_user_or_uid != "" ~}
      --user ${local.container_user_or_uid}%{~ if local.container_group_or_gid != "" ~}:${local.container_group_or_gid}%{~ endif ~} \
      %{~ endif ~}
      --rm \
      --name ${var.container_name} \
      ${var.image_uri} %{ if var.args != null }${var.args}%{ endif }
    ExecStop=-/usr/bin/podman stop ${var.container_name} --ignore
    ExecStopPost=-/usr/bin/podman rm ${var.container_name} --ignore

    [Install]
    WantedBy=multi-user.target
    EOS
}

data template_file "container_env" {
    template = <<-EOE
      %{ for environment_variable in keys(var.environment_variables) }
      ${environment_variable}="${var.environment_variables[environment_variable]}"
      %{ endfor }
    EOE
}

# Ignition contents
data template_file "ignition" {
  template = <<-EOI
    {
      "ignition": {
        "version": "3.3.0"
      },
      "storage": {
        "directories": [
    %{~ for idx, directory in var.directories ~}
          {
            "user": {
    %{~ if directory.uid != null ~}
              "id": ${directory.uid}
    %{~ endif ~}
    %{~ if directory.uid == null && directory.user_name != null ~}
              "name": "${directory.user_name}"
    %{~ endif ~}
            },
            "group": {
    %{~ if directory.gid != null ~}
              "id": ${directory.gid}
    %{~ endif ~}
    %{~ if directory.gid == null && directory.group_name != null ~}
              "name": "${directory.group_name}"
    %{~ endif ~}
            },
            "path": "${directory.path}",
            "overwrite": false,
            "mode": ${directory.decimal_mode}
          }%{~ if idx + 1 != length(var.files) ~},%{~ endif ~}
    %{~ endfor ~}
        ],
        "files": [
    %{~ for idx, file in var.files ~}
          {
            "user": {
    %{~ if file.uid != null ~}
              "id": ${file.uid}
    %{~ endif ~}
    %{~ if file.uid == null && file.user_name != null ~}
              "name": "${file.user_name}"
    %{~ endif ~}
            },
            "group": {
    %{~ if file.gid != null ~}
              "id": ${file.gid}
    %{~ endif ~}
    %{~ if file.gid == null && file.group_name != null ~}
              "name": "${file.group_name}"
    %{~ endif ~}
            },
            "path": "${file.path}",
            "overwrite": true,
            "contents": {
              "source": "data:text/plain;base64,${base64encode(file.contents)}"
            },
            "mode": ${file.decimal_mode}
          },
    %{~ endfor ~}
          {
            "user": {
    %{~ if var.container_uid != null ~}
              "id": ${var.container_uid}
    %{~ endif ~}
    %{~ if var.container_uid == null && var.container_user != null ~}
              "name": "${var.container_user}"
    %{~ endif ~}
            },
            "group": {
    %{~ if var.container_gid != null ~}
              "id": ${var.container_gid}
    %{~ endif ~}
    %{~ if var.container_gid  == null && var.container_group != null ~}
              "name": "${var.container_group}"
    %{~ endif ~}
            },
            "path": "/etc/${var.container_name}/${var.container_name}.env",
            "overwrite": true,
            "contents": {
              "source": "data:text/plain;base64,${base64encode(data.template_file.container_env.rendered)}"
            },
            "mode": 288
          }
        ]
      },
      "systemd": {
        "units": [
          {
            "name": "${var.container_name}.service",
            "enabled": true,
            "contents": ${jsonencode(data.template_file.universal_service.rendered)}
          }
        ]
      }
    }
    EOI
}

# Checks that ignition is valid JSON. Helps spot simple serialization bugs.
locals {
  validate_ignition = jsondecode(data.template_file.ignition.rendered)
}