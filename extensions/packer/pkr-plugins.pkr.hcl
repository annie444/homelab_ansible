packer {
  required_version = ">= 1.7.0"
  required_plugins {
    external = {
      version = ">= 0.0.3"
      source  = "github.com/joomcode/external"
    }
    qemu = {
      version = ">= 1.1.4"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = ">= 1.1.6"
      source  = "github.com/hashicorp/vagrant"
    }
    vmware = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/vmware"
    }
  }
}
