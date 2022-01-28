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
    %{~ for target in var.container_systemd_afters ~}
    After=${target}
    %{~ endfor ~}

    [Service]
    TimeoutStartSec=0
    ExecStartPre=/bin/podman stop ${var.container_name} --ignore
    ExecStartPre=/bin/podman rm ${var.container_name} --ignore
    ExecStart=/bin/podman run \
      %{~ for label in var.container_labels ~}
      --label ${label} \
      %{~ endfor ~}
      --env-file /etc/${var.container_name}/${var.container_name}.env \
      %{~ for volume_bind in var.container_volume_binds ~}
      -v ${volume_bind.host_dir}:${volume_bind.container_dir}%{ if volume_bind.options != null }:${volume_bind.options}%{ endif } \
      %{~ endfor ~}
      %{~ for port in var.container_ports ~}
      -p ${port.host_port}:${port.container_port} \
      %{~ endfor ~}
      %{~ if local.container_user_or_uid != "" ~}
      --user ${local.container_user_or_uid}%{~ if local.container_group_or_gid != "" ~}:${local.container_group_or_gid}%{~ endif ~} \
      %{~ endif ~}
      --rm \
      --name ${var.container_name} \
      ${var.container_image_uri} %{ if var.container_args != null }${var.container_args}%{ endif }
    ExecStop=-/usr/bin/podman stop ${var.container_name} --ignore
    ExecStopPost=-/usr/bin/podman rm ${var.container_name} --ignore

    [Install]
    WantedBy=multi-user.target
    EOS
}

data template_file "data_disk_mount" {
  template = <<-EOM
    [Unit]
    Before=local-fs.target
    Requires=systemd-fsck@dev-disk-by\\x2dpartlabel-${var.data_disk.label}.service
    After=systemd-fsck@dev-disk-by\\x2dpartlabel-${var.data_disk.label}.service

    [Mount]
    Where=${var.data_disk.mount_path}
    What=/dev/disk/by-partlabel/${var.data_disk.label}
    Type=xfs

    [Install]
    RequiredBy=local-fs.target
    EOM
}

data template_file "container_env" {
    template = <<-EOE
      %{ for environment_variable in keys(var.container_environment_variables) }
      ${environment_variable}="${var.container_environment_variables[environment_variable]}"
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
    %{~ for idx, directory in var.coreos_directories ~}
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
          }%{~ if idx + 1 != length(var.coreos_files) ~},%{~ endif ~}
    %{~ endfor ~}
        ],
        "files": [
    %{~ for idx, file in var.coreos_files ~}
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