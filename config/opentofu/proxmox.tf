
## SSH Key for VM ##
data "local_file" "ssh_public_key" {
  filename = var.proxmox_ssh_public_key_path
}

## User Data Cloud Config for Ubuntu Server VM ##
resource "proxmox_virtual_environment_file" "user_data_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ubuntu-vm
    timezone: America/Argentina/Buenos_Aires
    users:
      - default
      - name: ubuntu
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - qemu-guest-agent
      - nfs-kernel-server
      - curl
      - wget
      - gpg
    mounts:
      - [ "UUID=b2223470-ca24-444f-9ea5-498622c2a422", "/mnt/storage", "ext4", "defaults,nofail", "0", "2" ]
    write_files:
      - path: /etc/exports
        permissions: '0644'
        content: |
          /mnt/storage 10.10.10.0/24(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534)
      - path: /etc/systemd/system/openrgb.service
        permissions: '0644'
        content: |
          [Unit]
          Description=OpenRGB Server
          After=network.target

          [Service]
          ExecStart=/usr/bin/openrgb --server --server-host 0.0.0.0 --server-port 6742
          Restart=on-failure

          [Install]
          WantedBy=default.target
      
      - path: /etc/systemd/user/music-assistant.service
        owner: root:root
        permissions: '0644'
        content: |
          [Unit]
          Description=Music Assistant  in a container
          Wants=network-online.target
          After=network-online.target
          RequiresMountsFor=%t/containers

          [Service]
          ExecStart=/usr/bin/podman run --rm --name music-assistant \
            --cidfile=%t/%n.ctr-id \
            --cgroups=no-conmon \
            --sdnotify=conmon \
            --replace \
            --detach \
            --network=host \
            -e LOG_LEVEL=info \
            --label "io.containers.autoupdate=registry" \
            --volume=/mnt/storage/music-assistant/data:/data/ \
            --volume=/mnt/storage/media/music:/media:ro \
            ghcr.io/music-assistant/server:latest

          ExecStop=/usr/bin/podman stop --ignore -t 10 --cidfile=%t/%n.ctr-id
          ExecStopPost=/usr/bin/podman rm -f --ignore -t 10 --cidfile=%t/%n.ctr-id
          Type=notify
          NotifyAccess=all

          [Install]
          WantedBy=default.target
      
      - path: /sbin/finish-install
        permissions: '0755'
        content: |
          #!/bin/sh
   
          apt-get update
          apt-get install -y \
            openrgb \
            dkms \
            build-essential \
            intel-gpu-tools \
            linux-firmware \
            linux-firmware-intel-graphics \
            vainfo \
            intel-media-va-driver-non-free \
            intel-opencl-icd \
            openrgb \
            podman rootlesskit \
            net-tools \
            linux-headers-7.0.0-38 --no-install-recommends

          # install QEMU guest agent
          systemctl enable qemu-guest-agent
          systemctl start qemu-guest-agent
          
          #install NFS server
          mountpoint -q /mnt/storage || mount /mnt/storage
          systemctl enable --now nfs-kernel-server
          exportfs -ra
          
          # install openrgb
          systemctl enable --now openrgb

          # install music-assistant
          loginctl enable-linger ubuntu
          sudo -u ubuntu XDG_RUNTIME_DIR=/run/user/1000 systemctl --user daemon-reload
          sudo -u ubuntu XDG_RUNTIME_DIR=/run/user/1000 systemctl --user enable --now music-assistant

          # install plex media server repository
          curl -L https://downloads.plex.tv/plex-keys/PlexSign.v2.key | gpg --yes --dearmor -o /usr/share/keyrings/plexmediaserver.v2.gpg
          echo "deb [signed-by=/usr/share/keyrings/plexmediaserver.v2.gpg] https://repo.plex.tv/deb/ public main" > /etc/apt/sources.list.d/plex.list
          mkdir -p /etc/systemd/system/plexmediaserver.service.d/
          tee /etc/systemd/system/plexmediaserver.service.d/override.conf <<'_EOF_'
          [Service]
          Environment="PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/mnt/storage/plex/"
          _EOF_
          apt-get update
          apt-get install -y plexmediaserver
          usermod -a -G render plex
          usermod -a -G video plex
          usermod -a -G render ubuntu
          usermod -a -G video ubuntu
          sudo systemctl daemon-reload
          sudo systemctl restart plexmediaserver

          # install i915-sriov-dkms
          apt install -y dkms build-essential linux-headers-$(uname -r)
          wget https://github.com/strongtz/i915-sriov-dkms/releases/download/2026.09.16/i915-sriov-dkms_2026.09.16_amd64.deb
          dpkg -i i915-sriov-dkms_2026.09.16_amd64.deb
          dkms install i915-sriov-dkms/2026.09.16 -k $(uname -r) --force
          update-initramfs -u -k all
          echo "Installation finished"

    runcmd:
      - /sbin/finish-install
      - echo "done" > /tmp/cloud-config.done
    EOF

    file_name = "user-data-cloud-config-media.yaml"
  }
}

## Ubuntu Server VM ##
module "ubuntu_server" {
  vm_id  = 100
  source = "./modules/ubuntu-vm"
  name   = "ubuntu-vm"
  description = "Ubuntu server VM"
  tags   = ["opentofu", "ubuntu", "media"]
  cores  = 2
  memory = 2048
  disk_size = 20
  mac_address = "BC:24:11:B6:19:19"
  user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config.id
}

## User Data Cloud Config for Ubuntu IA Server VM ##
resource "proxmox_virtual_environment_file" "user_data_cloud_config_ia" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ubuntu-vm
    timezone: America/Argentina/Buenos_Aires
    users:
      - default
      - name: ubuntu
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ssh_public_key.content)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    package_update: true
    packages:
      - linux-firmware
      - linux-firmware-intel-graphics
      - qemu-guest-agent
      - net-tools
      - curl
      - wget
      - gpg
      - intel-gpu-tools
      - vainfo
      - intel-media-va-driver-non-free
      - intel-opencl-icd
    
    runcmd:
      - systemctl enable qemu-guest-agent
      - systemctl start qemu-guest-agent
      - loginctl enable-linger ubuntu
      - sudo -u ubuntu XDG_RUNTIME_DIR=/run/user/1000 systemctl --user daemon-reload
      - update-initramfs -u -k all
      - echo "done" > /tmp/cloud-config.done
    EOF
    file_name = "user-data-cloud-config-ia.yaml"
  }
}

## Ubuntu IA Server VM Module ##
module "ubuntu_ia" {
  vm_id  = 101
  source = "./modules/ubuntu-vm"
  name   = "ubuntu-ia"
  description = "Ubuntu IA server VM"
  tags   = ["opentofu", "ubuntu", "server", "ia"]
  cores  = 4
  memory = 4096
  disk_size = 60
  mac_address = "BC:24:11:09:45:94"
  user_data_file_id = proxmox_virtual_environment_file.user_data_cloud_config_ia.id
}