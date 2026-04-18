# Downloads the Talos nocloud ISO into the Proxmox local datastore.
resource "proxmox_download_file" "talos_disk_image" {
  content_type = "iso"
  datastore_id = "local"
  file_name    = "talos-nocloud-amd64-v1.12.6.iso"
  node_name    = "proxmox"
  url          = "https://factory.talos.dev/image/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586/v1.12.6/nocloud-amd64.iso"
}

# Uploads the Talos worker machine config as a cloud-init snippet file.
resource "proxmox_virtual_environment_file" "talos_worker_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "proxmox"

  source_raw {
    data      = file("${path.module}/../quantum-talos/worker.yaml")
    file_name = "talos-boson-cloud-init.yaml"
  }
}

# Provisions the Talos worker VM and attaches boot media, disk, and network.
resource "proxmox_virtual_environment_vm" "talos_boson_vm" {
  vm_id       = 1000
  name        = "talos-boson"
  description = "Talos kubernetes node provisioned with Opentofu"
  tags        = ["opentofu", "talos", "worker"]
  node_name   = "proxmox"

  agent {
    enabled = true
  }

  stop_on_destroy = true

  startup {
    order      = "1"
    up_delay   = "60"
    down_delay = "60"
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
    floating  = 2048
  }

  cdrom {
    file_id   = proxmox_download_file.talos_disk_image.id
    interface = "ide0"  # Boot from Talos ISO
  }

  disk {
    datastore_id = "local"
    interface    = "scsi0"
    size         = 20
    file_format  = "qcow2"
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:C3:24:1B"
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    datastore_id = "local"
    version      = "v2.0"
  }
}