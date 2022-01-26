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
      %{~ for environment_variable in keys(var.environment_variables) ~}
      -e ${environment_variable}="${var.environment_variables[environment_variable]}" \
      %{~ endfor ~}
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
    %{~ if directory.user_uid != null ~}
              "id": ${directory.user_uid}
    %{~ endif ~}
    %{~ if directory.user_uid == null && directory.user_name != null ~}
              "name": "${directory.user_name}"
    %{~ endif ~}
            },
            "group": {
    %{~ if directory.group_uid != null ~}
              "id": ${directory.group_uid}
    %{~ endif ~}
    %{~ if directory.group_uid == null && directory.group_name != null ~}
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
    %{~ if file.user_uid != null ~}
              "id": ${file.user_uid}
    %{~ endif ~}
    %{~ if file.user_uid == null && file.user_name != null ~}
              "name": "${file.user_name}"
    %{~ endif ~}
            },
            "group": {
    %{~ if file.group_uid != null ~}
              "id": ${file.group_uid}
    %{~ endif ~}
    %{~ if file.group_uid == null && file.group_name != null ~}
              "name": "${file.group_name}"
    %{~ endif ~}
            },
            "path": "${file.path}",
            "overwrite": true,
            "contents": {
              "source": "data:text/plain;base64,${base64encode(file.contents)}"
            },
            "mode": ${file.decimal_mode}
          }%{~ if idx + 1 != length(var.files) ~},%{~ endif ~}
    %{~ endfor ~}
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