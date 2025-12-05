# set up environment variables talosctl and kubectl
export KUBECONFIG=$PWD/config/quantum-talos/kubeconfig
export TALOSCONFIG=$PWD/config/quantum-talos/talosconfig
export CONTROL_PLANE_IP=10.10.10.194
export WORKER_IP=10.10.10.173
export SOPS_AGE_KEY_FILE=$PWD/age.key