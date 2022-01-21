# Ignition Terraform Modules: Universal

## What is this module for?

This is a [Terraform module](https://www.terraform.io/language/modules) to generate a [CoreOS ignition](https://coreos.github.io/ignition/) configuration that deploys an arbitrary applications to a [Fedora CoreOS](https://getfedora.org/en/coreos?stream=stable) host. 

This module is intended to be merged in with other ignition configurations. For example:

```hcl
module "ignition_coreos_universal" {
  source = "https://github.com/ignition-terraform-modules/universal"

  container_name = "my-app"
  container_user_or_uid = "1010"
  image_uri = "docker.io/library/image:352"
  ports = [
    {
      host_port: 8080
      container_port: 80
    }
  ]
  volume_binds = [
    {
      host_dir = "/var/mnt/data"
      container_dir = "/var/lib/data"
      options = "U,Z"
    }
  ]
}

locals {
  ignition = {
    "ignition": {
      "version": "3.3.0",
      "config": {
        "merge": [
          {
            "source": "data:text/json;base64,${base64encode(module.ignition_coreos_common.ignition)}"
          },
          {
            "source": "data:text/json;base64,${base64encode(module.ignition_coreos_universal.ignition)}"
          }
        ]
      }
    }
  }
}
```

You can then feed ```local.ignition``` into a Terraform provider that is deploying a Fedora CoreOS server. For example:

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