# set up environment variables talosctl and kubectl
export KUBECONFIG=$PWD/talos/kubeconfig
export TALOSCONFIG=$PWD/talos/talosconfig
export CONTROL_PLANE_IP=192.168.0.125
export WORKER_IP=192.168.0.230
export SOPS_AGE_KEY_FILE=$PWD/age.key