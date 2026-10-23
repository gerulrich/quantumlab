terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

## ubuntu cloud image ##
resource "proxmox_download_file" "ubuntu_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve"
  url          = "https://cloud-images.ubuntu.com/resolute/current/resolute-server-cloudimg-amd64.img"
  overwrite    = true
  file_name = "resolute-server-cloudimg-amd64.qcow2"
}

## Ubuntu VM ##
resource "proxmox_virtual_environment_vm" "this" {
  vm_id       = var.vm_id
  name        = var.name
  description = var.description
  tags        = var.tags 
  node_name   = "pve"
  bios        = "seabios"
  machine     = "q35"
  started     = false
  on_boot     = true
  agent {
    enabled = true
  }
  cpu {
    cores = var.cores
    type  = "host"
  }
  memory {
    dedicated = var.memory
  }
  disk {
    datastore_id = "local-zfs"
    import_from  = proxmox_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = var.disk_size
  }
  network_device {
    bridge = "vmbr0"
    mac_address = var.mac_address
  }
  initialization {
    datastore_id = "local-zfs"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = var.user_data_file_id
  }
  lifecycle {
    ignore_changes = [
      started,
      usb,
      hostpci
    ]
  }
}