# packer {
#   required_plugins {
#     vsphere = {
#       version = ">= 0.0.1"
#       source = "github.com/hashicorp/vsphere"
#     }
#   }
# }

variable "cpu_num" {
  type    = number
  default = 2
}

variable "disk_size" {
  type    = number
  default = 51200
}

variable "mem_size" {
  type    = number
  default = 2048
}

variable "os_iso_checksum" {
  type    = string
  default = ""
}

variable "os_iso_url" {
  type    = string
  default = ""
}

variable "iso_path" {
  # type    = string
  description = "The path on the source vSphere datastore for ISO images."
  default = []
  }

variable "vsphere_folder" {
  type    = string
  default = ""
}
variable "vsphere_datastore" {
  type    = string
  default = ""
}

variable "vsphere_datacenter" {
  type    = string
  default = ""
}

variable "vsphere_guest_os_type" {
  type    = string
  default = ""
}

variable "vsphere_host" {
  type    = string
  default = ""
}

variable "vsphere_cluster" {
  type    = string
  default = ""
}


variable "vsphere_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "vsphere_network" {
  type    = string
  default = ""
}

variable "vsphere_server" {
  type    = string
  default = ""
}

variable "vsphere_vm_name" {
  type    = string
  default = ""
}

variable "vsphere_username" {
  type    = string
  default = ""
}

variable "ssh_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ssh_username" {
  type    = string
  default = ""
}

variable "cloudinit_userdata" {
  type = string
  default = ""
}

variable "cloudinit_metadata" {
  type = string
  default = ""
}

variable "shell_scripts" {
  type = list(string)
  description = "A list of scripts."
  default = []
}

variable "boot_command" {
  type = list(string)
  description = "Ubuntu boot command"
  default = []
}

locals {
  buildtime = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}

source "vsphere-iso" "ubuntu" {
  notes = "Built by HashiCorp Packer on ${local.buildtime}."
  folder = var.vsphere_folder

  vcenter_server        = var.vsphere_server
  # host                = var.vsphere_host
  cluster               = var.vsphere_cluster
  username              = var.vsphere_username
  password              = var.vsphere_password
  insecure_connection   = "true"
  datacenter            = var.vsphere_datacenter
  datastore             = var.vsphere_datastore

  CPUs                  = var.cpu_num
  RAM                   = var.mem_size
  RAM_reserve_all       = true
  disk_controller_type  = ["pvscsi"]
  guest_os_type         = var.vsphere_guest_os_type
  # iso_checksum          = var.os_iso_checksum
  # iso_url               = var.os_iso_url
  iso_paths = var.iso_path
  cd_content            = {
    "/meta-data" = file("${var.cloudinit_metadata}")
    "/user-data" = file("${var.cloudinit_userdata}")
  }
  cd_label              = "cidata"

  network_adapters {
    network             = var.vsphere_network
    network_card        = "vmxnet3"
  }

  storage {
    disk_size             = var.disk_size
    disk_thin_provisioned = true
  }

  vm_name               = var.vsphere_vm_name
  convert_to_template   = "true"
  communicator          = "ssh"
  ssh_username          = var.ssh_username
  ssh_password          = var.ssh_password
  ssh_timeout           = "30m"
  ssh_handshake_attempts = "100000"

  boot_order            = "disk,cdrom,floppy"
  boot_wait             = "3s"
  boot_command          = var.boot_command
  shutdown_command      = "echo '${var.ssh_password}' | sudo -S -E shutdown -P now"
  shutdown_timeout      = "15m"

  configuration_parameters = {
    "disk.EnableUUID" = "true"
  }
}

build {
  sources = ["source.vsphere-iso.ubuntu"]

  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    environment_vars = [
      "BUILD_USERNAME=${var.ssh_username}",
    ]
    scripts = var.shell_scripts
    expect_disconnect = true
  }

}
