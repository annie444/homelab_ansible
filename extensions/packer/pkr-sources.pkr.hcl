data "external-raw" "host_os" {
  program = ["uname", "-s"]
}

locals {
  # helper locals
  build_dir = abspath("${path.root}/../builds/")
  host_os   = chomp(data.external-raw.host_os.result)
  # Source block provider specific
  # qemu
  qemu_accelerator = var.qemu_accelerator == null ? (
    local.host_os == "Darwin" ? "hvf" : null
  ) : var.qemu_accelerator
  qemu_binary = var.qemu_binary == null ? "qemu-system-${var.os_arch}" : var.qemu_binary
  qemu_display = var.qemu_display == null ? (
    local.host_os == "Darwin" ? (
      var.os_arch == "aarch64" ? "cocoa" : "virtio-gpu-pci"
      ) : (
      var.os_arch == "aarch64" ? "virtio-ramfb" : "virtio-vga"
    )
  ) : var.qemu_display
  qemu_efi_boot = var.qemu_efi_boot == null ? (
    var.os_arch == "aarch64" ? true : false
  ) : var.qemu_efi_boot
  qemu_efi_firmware_code = var.qemu_efi_firmware_code == null ? (
    local.host_os == "Darwin" ? "/opt/homebrew/share/qemu/edk2-${var.os_arch}-code.fd" : "/usr/local/share/qemu/edk2-x86_64-code.fd"
  ) : var.qemu_efi_firmware_code
  qemu_efi_firmware_vars = var.qemu_efi_firmware_vars == null ? (
    local.host_os == "Darwin" ? (
      var.os_arch == "aarch64" ? "/opt/homebrew/share/qemu/edk2-arm-vars.fd" : "/usr/local/share/qemu/edk2-i386-vars.fd"
    ) : null
  ) : var.qemu_efi_firmware_vars
  qemu_machine_type = var.qemu_machine_type == null ? (
    var.os_arch == "aarch64" ? "virt" : "q35"
  ) : var.qemu_machine_type
  qemuargs = var.qemuargs == null ? (
    var.os_arch == "aarch64" ? [
      ["-device", "virtio-gpu-pci"],
      ["-device", "qemu-xhci"],
      ["-device", "virtio-tablet"],
      ["-device", "driver=virtio-keyboard-pci"],
      ["-device", "driver=virtio-mouse-pci"],
      ["-device", "driver=usb-kbd"],
      ["-device", "driver=usb-mouse"],
      ["-device", "virtio-serial"],
      ["-chardev", "socket,name=org.qemu.guest_agent.0,id=org.qemu.guest_agent,server=on,wait=off"],
      ["-device", "virtserialport,chardev=org.qemu.guest_agent,name=org.qemu.guest_agent.0"],
      ["-boot", "strict=off"],
      ] : [
      ["-device", "virtio-serial"],
      ["-chardev", "socket,name=org.qemu.guest_agent.0,id=org.qemu.guest_agent,server=on,wait=off"],
      ["-device", "virtserialport,chardev=org.qemu.guest_agent,name=org.qemu.guest_agent.0"],
    ]
  ) : var.qemuargs

  # vmware-iso
  vmware_network_adapter_type = var.vmware_network_adapter_type == null ? (
    "e1000e"
  ) : var.vmware_network_adapter_type
  vmware_tools_upload_flavor = var.vmware_tools_upload_flavor
  vmware_tools_upload_path = var.vmware_tools_upload_path == null ? (
    "/tmp/vmware-tools.iso"
  ) : var.vmware_tools_upload_path
  vmware_vmx_data = var.vmware_vmx_data == null ? (
    {
      "svga.autodetect"  = "TRUE"
      "usb_xhci.present" = "TRUE"
    }
  ) : var.vmware_vmx_data

  # Source block common
  cd_files = var.cd_files
  communicator = var.communicator == null ? (
    "ssh"
  ) : var.communicator
  default_boot_command = var.boot_command
  default_boot_wait = var.default_boot_wait == null ? (
    "15s"
  ) : var.default_boot_wait
  disk_size = var.disk_size == null ? (
    65536
  ) : var.disk_size
  floppy_files    = var.floppy_files
  http_directory  = var.http_directory == null ? "${path.root}/http" : var.http_directory
  iso_target_path = var.iso_target_path == "build_dir_iso" && var.iso_url != null ? "${path.root}/../builds/iso/${var.os_name}-${var.os_version}-${var.os_arch}-${substr(sha256(var.iso_url), 0, 8)}.iso" : var.iso_target_path
  memory = var.memory == null ? (
    var.os_arch == "aarch64" ? 4096 : 3072
  ) : var.memory
  output_directory = var.output_directory == null ? "${path.root}/../builds/build_files/packer-${var.os_name}-${var.os_version}-${var.os_arch}" : var.output_directory
  shutdown_command = var.shutdown_command == null ? (
    "echo 'vagrant' | sudo -S /sbin/halt -h -p"
  ) : var.shutdown_command
  vm_name = var.vm_name == null ? (
    var.os_arch == "x86_64" ? "${var.os_name}-${var.os_version}-amd64" : "${var.os_name}-${var.os_version}-${var.os_arch}"
  ) : var.vm_name
}

source "qemu" "vm" {
  # QEMU specific options
  accelerator         = local.qemu_accelerator
  cpu_model           = var.qemu_cpu_model
  display             = local.qemu_display
  disk_cache          = var.qemu_disk_cache
  disk_compression    = var.qemu_disk_compression
  disk_detect_zeroes  = var.qemu_disk_detect_zeroes
  disk_discard        = var.qemu_disk_discard
  disk_image          = var.qemu_disk_image
  disk_interface      = var.qemu_disk_interface
  efi_boot            = local.qemu_efi_boot
  efi_firmware_code   = local.qemu_efi_firmware_code
  efi_firmware_vars   = local.qemu_efi_firmware_vars
  efi_drop_efivars    = var.qemu_efi_drop_efivars
  format              = var.qemu_format
  machine_type        = local.qemu_machine_type
  net_device          = var.qemu_net_device
  qemu_binary         = local.qemu_binary
  qemuargs            = local.qemuargs
  use_default_display = var.qemu_use_default_display
  use_pflash          = var.qemu_use_pflash
  # Source block common options
  boot_command     = var.qemu_boot_command == null ? local.default_boot_command : var.qemu_boot_command
  boot_wait        = var.qemu_boot_wait == null ? local.default_boot_wait : var.qemu_boot_wait
  cd_content       = var.cd_content
  cd_files         = local.cd_files
  cd_label         = var.cd_label
  cpus             = var.cpus
  communicator     = local.communicator
  disk_size        = local.disk_size
  floppy_files     = local.floppy_files
  headless         = var.headless
  http_directory   = local.http_directory
  iso_checksum     = var.iso_checksum
  iso_target_path  = local.iso_target_path
  iso_url          = var.iso_url
  memory           = local.memory
  output_directory = "${local.output_directory}-qemu"
  shutdown_command = local.shutdown_command
  shutdown_timeout = var.shutdown_timeout
  ssh_password     = var.ssh_password
  ssh_port         = var.ssh_port
  ssh_timeout      = var.ssh_timeout
  ssh_username     = var.ssh_username
  vm_name          = local.vm_name
}
source "vmware-iso" "vm" {
  # VMware specific options
  cores                          = var.vmware_cores
  cdrom_adapter_type             = var.vmware_cdrom_adapter_type
  disk_adapter_type              = var.vmware_disk_adapter_type
  firmware                       = var.vmware_firmware
  guest_os_type                  = var.vmware_guest_os_type
  network                        = var.vmware_network
  network_adapter_type           = local.vmware_network_adapter_type
  tools_upload_flavor            = local.vmware_tools_upload_flavor
  tools_upload_path              = local.vmware_tools_upload_path
  usb                            = var.vmware_usb
  version                        = var.vmware_version
  vmx_data                       = local.vmware_vmx_data
  vmx_remove_ethernet_interfaces = var.vmware_vmx_remove_ethernet_interfaces
  vnc_disable_password           = var.vmware_vnc_disable_password
  # Source block common options
  boot_command     = var.vmware_boot_command == null ? local.default_boot_command : var.vmware_boot_command
  boot_wait        = var.vmware_boot_wait == null ? local.default_boot_wait : var.vmware_boot_wait
  cd_content       = var.cd_content
  cd_files         = local.cd_files # Broken and not creating disks
  cd_label         = var.cd_label
  cpus             = var.cpus
  communicator     = local.communicator
  disk_size        = local.disk_size
  floppy_files     = local.floppy_files
  headless         = var.headless
  http_directory   = local.http_directory
  iso_checksum     = var.iso_checksum
  iso_target_path  = abspath(local.iso_target_path)
  iso_url          = var.iso_url
  memory           = local.memory
  output_directory = "${local.output_directory}-vmware"
  shutdown_command = local.shutdown_command
  shutdown_timeout = var.shutdown_timeout
  ssh_password     = var.ssh_password
  ssh_port         = var.ssh_port
  ssh_timeout      = var.ssh_timeout
  ssh_username     = var.ssh_username
  vm_name          = local.vm_name
}
