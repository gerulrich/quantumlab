# set up environment variables talosctl and kubectl

# Versions
export TALOS_VERSION="1.12.6"
export KUBERNETES_VERSION="1.35.4"
export FLUX_VERSION="2.8.5"
export CILIUM_VERSION="1.19.3"
export SCHEMATIC_ID=a2e824fa8b6d72b70f9076cebd483a76cd56a07a0a81372611a8ed6fe3b6b95e

# Cluster configuration
export CONTROL_PLANE_IP=10.10.10.194
export CONTROL_PLANE_MAC="52:54:00:1a:c7:e5"
export WORKER_IP=10.10.10.173
export WORKER_MAC="52:54:00:f3:be:40"
export KUBECONFIG=$PWD/kubeconfig
export TALOSCONFIG=$PWD/config/quantum-talos/talosconfig
export SOPS_AGE_KEY_FILE=$PWD/age.key
export PATH=$PATH:$PWD/bin
