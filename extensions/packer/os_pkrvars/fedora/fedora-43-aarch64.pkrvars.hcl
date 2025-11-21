os_name              = "fedora"
os_version           = "43"
os_arch              = "aarch64"
iso_url              = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/aarch64/iso/Fedora-Server-netinst-aarch64-43-1.6.iso"
iso_checksum         = "file:https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/aarch64/iso/Fedora-Server-43-1.6-aarch64-CHECKSUM"
vmware_guest_os_type = "arm-fedora-64"
boot_command         = ["<up>e<wait><down><down><end> inst.ks=https://raw.githubusercontent.com/chef/bento/refs/heads/main/packer_templates/http/rhel/ks.cfg inst.repo=https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/aarch64/os/ <F10><wait>"]
