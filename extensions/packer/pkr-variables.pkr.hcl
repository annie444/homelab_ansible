# General variables
variable "os_name" {
  type        = string
  description = "OS Brand Name"
}
variable "os_version" {
  type        = string
  description = "OS version number"
}
variable "os_arch" {
  type = string
  validation {
    condition     = var.os_arch == "x86_64" || var.os_arch == "aarch64"
    error_message = "The OS architecture type should be either x86_64 or aarch64."
  }
  description = "OS architecture type, x86_64 or aarch64"
}
variable "is_windows" {
  type        = bool
  default     = false
  description = "Determines to set setting for Windows or Linux"
}
variable "http_proxy" {
  type        = string
  default     = env("http_proxy")
  description = "Http proxy url to connect to the internet"
}
variable "https_proxy" {
  type        = string
  default     = env("https_proxy")
  description = "Https proxy url to connect to the internet"
}
variable "no_proxy" {
  type        = string
  default     = env("no_proxy")
  description = "No Proxy"
}
variable "sources_enabled" {
  type = list(string)
  default = [
    "source.qemu.vm",
    "source.vmware-iso.vm",
  ]
  description = "Build Sources to use for building vagrant boxes"
}

# Source block provider specific variables
# qemu
variable "qemu_accelerator" {
  type    = string
  default = null
}
variable "qemu_binary" {
  type    = string
  default = null
}
variable "qemu_boot_command" {
  type        = list(string)
  default     = null
  description = "Commands to pass to gui session to initiate automated install"
}
variable "qemu_boot_wait" {
  type    = string
  default = null
}
variable "qemu_cpu_model" {
  type    = string
  default = "host"
}
variable "qemu_disk_cache" {
  type    = string
  default = "unsafe"
}
variable "qemu_disk_compression" {
  type    = bool
  default = true
}
variable "qemu_disk_detect_zeroes" {
  type    = string
  default = "unmap"
}
variable "qemu_disk_discard" {
  type    = string
  default = "unmap"
}
variable "qemu_disk_interface" {
  type    = string
  default = "virtio"
}
variable "qemu_display" {
  type        = string
  default     = null
  description = "What QEMU -display option to use. Defaults to gtk, use none to not pass the -display option allowing QEMU to choose the default"
}
variable "qemu_disk_image" {
  type        = bool
  default     = false
  description = "Whether iso_url is a bootable qcow2 disk image"
}
variable "qemu_efi_boot" {
  type        = bool
  default     = null
  description = "Enable EFI boot"
}
variable "qemu_efi_firmware_code" {
  type        = string
  default     = null
  description = "EFI firmware code path"
}
variable "qemu_efi_firmware_vars" {
  type        = string
  default     = null
  description = "EFI firmware vars file path"
}
variable "qemu_efi_drop_efivars" {
  type        = bool
  default     = null
  description = "Drop EFI vars"
}
variable "qemu_format" {
  type    = string
  default = "qcow2"
  validation {
    condition     = var.qemu_format == "qcow2" || var.qemu_format == "raw"
    error_message = "Disk format, takes qcow2 or raw."
  }
  description = "Disk format, takes qcow2 or raw"
}
variable "qemu_machine_type" {
  type    = string
  default = null
}
variable "qemu_net_device" {
  type    = string
  default = "virtio-net-pci"
}
variable "qemuargs" {
  type    = list(list(string))
  default = null
}
variable "qemu_use_default_display" {
  type    = bool
  default = null
}
variable "qemu_use_pflash" {
  type    = bool
  default = true
}

# vmware-iso
variable "vmware_boot_command" {
  type        = list(string)
  default     = null
  description = "Commands to pass to gui session to initiate automated install"
}
variable "vmware_boot_wait" {
  type    = string
  default = null
}
variable "vmware_cdrom_adapter_type" {
  type        = string
  default     = "sata"
  description = "CDROM adapter type.  Needs to be SATA (or non-SCSI) for ARM64 builds."
}
variable "vmware_cores" {
  type        = number
  default     = 2
  description = "The number of virtual CPU cores per socket for the virtual machine"
}
variable "vmware_disk_adapter_type" {
  type        = string
  default     = "sata"
  description = "Disk adapter type.  Needs to be SATA (PVSCSI, or non-SCSI) for ARM64 builds."
}
variable "vmware_firmware" {
  type        = string
  default     = null
  description = "The firmware type for the virtual machine. Allowed values are bios, efi, and efi-secure (for secure boot). Defaults to the recommended firmware type for the guest operating system"
}
variable "vmware_guest_os_type" {
  type        = string
  default     = null
  description = "OS type for virtualization optimization"
}
variable "vmware_tools_upload_flavor" {
  type    = string
  default = null
}
variable "vmware_tools_upload_path" {
  type    = string
  default = null
}
variable "vmware_version" {
  type    = number
  default = 21
}
variable "vmware_vmx_data" {
  type    = map(string)
  default = null
}
variable "vmware_vmx_remove_ethernet_interfaces" {
  type    = bool
  default = true
}
variable "vmware_usb" {
  type        = bool
  default     = false
  description = "Enable the USB 2.0 controllers for the virtual machine"
}
variable "vmware_network_adapter_type" {
  type    = string
  default = null
}
variable "vmware_network" {
  type    = string
  default = "nat"
}
variable "vmware_vnc_disable_password" {
  type    = bool
  default = true
}

# Source block common variables
variable "boot_command" {
  type        = list(string)
  default     = null
  description = "Commands to pass to gui session to initiate automated install"
}
variable "default_boot_wait" {
  type    = string
  default = null
}
variable "cd_content" {
  type        = map(string)
  default     = null
  description = "Content to be served by the cdrom"
}
variable "cd_files" {
  type    = list(string)
  default = null
}
variable "cd_label" {
  type    = string
  default = "cidata"
}
variable "cpus" {
  type    = number
  default = 2
}
variable "communicator" {
  type    = string
  default = null
}
variable "disk_size" {
  type    = number
  default = null
}
variable "floppy_files" {
  type    = list(string)
  default = null
}
variable "headless" {
  type        = bool
  default     = true
  description = "Start GUI window to interact with VM"
}
variable "http_directory" {
  type    = string
  default = null
}
variable "iso_checksum" {
  type        = string
  default     = null
  description = "ISO download checksum"
}
variable "iso_target_path" {
  type        = string
  default     = "build_dir_iso"
  description = "Path to store the ISO file. Null will use packer cache default or build_dir_iso will put it in the local build/iso directory."
}
variable "iso_url" {
  type        = string
  default     = null
  description = "ISO download url"
}
variable "memory" {
  type    = number
  default = null
}
variable "output_directory" {
  type    = string
  default = null
}
variable "shutdown_command" {
  type    = string
  default = null
}
variable "shutdown_timeout" {
  type    = string
  default = "15m"
}
variable "ssh_password" {
  type    = string
  default = "vagrant"
}
variable "ssh_port" {
  type    = number
  default = 22
}
variable "ssh_timeout" {
  type    = string
  default = "15m"
}
variable "ssh_username" {
  type    = string
  default = "vagrant"
}
variable "vm_name" {
  type    = string
  default = null
}

# builder common block
variable "scripts" {
  type    = list(string)
  default = null
}
