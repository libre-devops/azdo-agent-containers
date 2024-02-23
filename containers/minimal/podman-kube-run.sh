# Ensure the script stops if an error occurs
set -e

# Pull the necessary pause image
podman pull k8s.gcr.io/pause:3.5

podman kube play kube-azdo-creds.yaml && \
podman play kube podman-kube-deployment.yaml

