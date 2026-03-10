#!/bin/bash
set -euo pipefail

sudo podman exec cluster-registry bin/registry garbage-collect -m /etc/docker/registry/config.yml