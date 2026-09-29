# Downloads the Talos nocloud ISO into the Proxmox local datastore.
resource "proxmox_download_file" "talos_disk_image" {
  content_type = "iso"
  datastore_id = "local"
  file_name    = "talos-nocloud-amd64-v1.14.1.iso"
  node_name    = "pve"
  url          = "https://factory.talos.dev/image/dc7b152cb3ea99b821fcb7340ce7168313ce393d663740b791c36f6e95fc8586/v1.14.1/nocloud-amd64.iso"
}

# Uploads the Talos worker machine config as a cloud-init snippet file.
resource "proxmox_virtual_environment_file" "talos_worker_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data      = file("${path.module}/../quantum-talos/worker.yaml")
    file_name = "talos-worker-cloud-init.yaml"
  }
}

# Provisions the Talos worker VM and attaches boot media, disk, and network.
resource "proxmox_virtual_environment_vm" "talos_boson_vm" {
  vm_id       = 1004
  name        = "boson-talos-v2"
  description = "Talos kubernetes node provisioned with Opentofu"
  tags        = ["opentofu", "talos", "worker"]
  node_name   = "pve"
  machine     = "q35"
  # Empty scsi0 falls through to the ISO on first boot
  boot_order  = ["scsi0", "ide0"]
  started     = false
  on_boot     = false

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
    dedicated = 4096
    floating  = 4096
  }

  cdrom {
    file_id   = proxmox_download_file.talos_disk_image.id
    interface = "ide0"  # Boot from Talos ISO
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    ssd = true
    backup = false
    replicate = false
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi1"
    size         = 60
    file_format  = "raw"
    ssd = true
    backup = false
    replicate = false
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:C3:24:1B"
  }

  operating_system {
    type = "l26"
  }
}