# Ignition Terraform Modules: Systemd Container

## What is this module for?

This is a [Terraform module](https://www.terraform.io/language/modules) to generate [CoreOS ignition](https://coreos.github.io/ignition/) JSON configuration to deploys containerized applications to [Fedora CoreOS](https://getfedora.org/en/coreos?stream=stable) hosts. 


## How do I use this module?

This module is intended to be merged in with other ignition configurations. For example:

```hcl
module "common_ignition" {
  source = "https://github.com/ignition-terraform-modules/coreos-common"

  # Fedora CoreOS hostname
  hostname = "fedora-coreos"
  
  # Additional users to create
  additional_users = ["httpd"]
}

module "httpd_ignition" {
  source = "https://github.com/ignition-terraform-modules/systemd-container"

  # Name of the container
  name = "httpd"
  
  # User used to run the container
  user = "httpd"
  
  # The container image
  image = "registry.access.redhat.com/ubi8/httpd-24:latest"

  # Ports to expose on the host 
  ports = [
    {
      host_port: 8080
      container_port: 8080
    }
  ]
}

locals {
  # The generated ignition contents
  ignition = {
    "ignition": {
      "version": "3.3.0",
      "config": {
        "merge": [
          {
            "source": "data:text/json;base64,${base64encode(module.common_ignition.ignition)}"
          },
          {
            "source": "data:text/json;base64,${base64encode(module.httpd_ignition.ignition)}"
          }
        ]
      }
    }
  }

  # Check that the ignition contents are valid JSON
  validate_ignition = jsondecode(data.template_file.ignition.rendered)
}
```

You can then feed ```local.ignition``` into a Terraform provider that is deploying a Fedora CoreOS server. Using the vSphere provider for example:

```hcl
resource "vsphere_virtual_machine" "fedora_coreos_vm" {
  name = var.hostname
  resource_pool_id = var.vsphere_resource_pool_id
  datastore_id = data.vsphere_datastore.datastore.id
  folder = var.vsphere_folder
  
  # ...
  
  clone {
    template_uuid = var.ova_content_library_item_id
  }
  extra_config = {
    "guestinfo.ignition.config.data"          = base64encode(local.ignition)
    "guestinfo.ignition.config.data.encoding" = "base64"
  }
}
```

## What do the Systemd units look like?

The generated systemd unit for the above configuration would look like the following: 

```ini
[Unit]
Description=httpd Podman container
After=network-online.target
Wants=network-online.target
StartLimitInterval=60
StartLimitBurst=5

[Service]
User=httpd
Restart=always
RestartSec=30
TimeoutStartSec=20
ExecStart=/bin/podman run \
  --env-file /etc/httpd/httpd.env \
  -p 8080:8080 \
  --rm \
  --replace \
  --name httpd \
  registry.access.redhat.com/ubi8/httpd-24:latest
ExecStop=-/usr/bin/podman stop test --ignore

[Install]
WantedBy=multi-user.target
```