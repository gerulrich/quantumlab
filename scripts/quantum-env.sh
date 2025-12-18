# set up environment variables talosctl and kubectl

# Versions
export TALOS_VERSION="1.11.6"
export KUBERNETES_VERSION="1.34.2"
export FLUX_VERSION="0.38.3"
export CILIUM_VERSION="1.14.1"

# Cluster configuration
export CONTROL_PLANE_IP=10.10.10.194
export CONTROL_PLANE_MAC="52:54:00:1a:c7:e5"
export WORKER_IP=10.10.10.173
export WORKER_MAC="52:54:00:f3:be:40"
export KUBECONFIG=$PWD/kubeconfig
export TALOSCONFIG=$PWD/config/quantum-talos/talosconfig
export SOPS_AGE_KEY_FILE=$PWD/age.key
export PATH=$PATH:$PWD/bin