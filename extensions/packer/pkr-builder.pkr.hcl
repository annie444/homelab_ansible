locals {
  common_scripts = [
    "${path.root}/scripts/_common/vagrant.sh",
    "${path.root}/scripts/_common/sshd.sh",
    "${path.root}/scripts/_common/guest_tools_virtualbox.sh",
    "${path.root}/scripts/_common/guest_tools_vmware.sh",
    "${path.root}/scripts/_common/guest_tools_parallels.sh",
    "${path.root}/scripts/_common/guest_tools_qemu.sh",
  ]
  scripts = var.scripts == null ? (
    [
      "${path.root}/scripts/fedora/networking_fedora.sh",
      "${path.root}/scripts/fedora/install-supporting-packages_fedora.sh",
      "${path.root}/scripts/fedora/real-tmp_fedora.sh",
      "${path.root}/scripts/fedora/cleanup_dnf.sh",
    ]
  ) : var.scripts
  nix_environment_vars = [
    "HOME_DIR=/home/vagrant",
    "http_proxy=${var.http_proxy}",
    "https_proxy=${var.https_proxy}",
    "no_proxy=${var.no_proxy}"
  ]

  nix_execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
  elevated_user       = "vagrant"
  elevated_password   = "vagrant"
  source_names        = [for source in var.sources_enabled : trimprefix(source, "source.")]
}

# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = var.sources_enabled

  # Linux Shell scripts
  # Install updates and reboot
  provisioner "shell" {
    environment_vars  = local.nix_environment_vars
    execute_command   = local.nix_execute_command
    expect_disconnect = true
    pause_before      = "10s"
    scripts           = ["${path.root}/scripts/_common/update_packages.sh", ]
    valid_exit_codes  = [0, 143]
  }
  provisioner "shell" {
    inline = [
      "echo 'Waiting after reboot'"
    ]
    pause_after = "10s"
  }
  # Install build tools and reboot
  provisioner "shell" {
    environment_vars  = local.nix_environment_vars
    execute_command   = local.nix_execute_command
    expect_disconnect = true
    pause_before      = "10s"
    scripts           = ["${path.root}/scripts/_common/build_tools.sh", ]
  }
  provisioner "shell" {
    inline = [
      "echo 'Waiting after reboot'"
    ]
    pause_after = "10s"
  }
  # Run common scripts and guest tools installation
  provisioner "shell" {
    environment_vars  = local.nix_environment_vars
    execute_command   = local.nix_execute_command
    expect_disconnect = true
    pause_before      = "10s"
    scripts           = local.common_scripts
  }
  provisioner "shell" {
    inline = [
      "echo 'Waiting after reboot'"
    ]
    pause_after = "10s"
  }
  # Run OS specific scripts
  provisioner "shell" {
    environment_vars  = local.nix_environment_vars
    execute_command   = local.nix_execute_command
    expect_disconnect = true
    pause_before      = "10s"
    scripts           = local.scripts
  }
  # Run minimize script
  provisioner "shell" {
    environment_vars  = local.nix_environment_vars
    execute_command   = local.nix_execute_command
    expect_disconnect = true
    pause_after       = "10s"
    scripts           = ["${path.root}/scripts/_common/minimize.sh", ]
  }

  # Convert machines to vagrant boxes
  post-processor "vagrant" {
    compression_level = 9
    output            = "${path.root}/../builds/build_complete/${var.os_name}-${var.os_version}-${var.os_arch}.{{ .Provider }}.box"
  }
}
