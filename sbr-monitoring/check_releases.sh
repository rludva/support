#!/bin/bash

# Read latest release from GitHub REST API..
function get_latest_release() {

  # Input parameters..
  GITHUB_USERNAME="$1"
  GITHUB_REPOSITORY="$2"

  # Call GitHub REST API..
  response=$(curl -s "https://api.github.com/repos/${GITHUB_USERNAME}/${GITHUB_REPOSITORY}/releases/latest")

  # Parse JSON response..
  release=$(echo "$response" | grep -Po '"tag_name": "\K([^"]*)')

  echo "$release"
}

a=$(get_latest_release "prometheus" "prometheus")
echo "a: $a"
exit 0

function check_releases() {

  # Input parameters..
  APPLICATION="$1"
  LATEST="$2"

  echo "Checking $APPLICATION for new releases, latest is $LATEST."
  
  RELEASES_FILE_NAME="./playbooks/variables/${APPLICATION}-releases.yaml"
  if not grep "$LATEST" $RELEASES_FILE_NAME; then
    echo "New release of $APPLICATION detected: $LATEST"
    echo "Updating $RELEASES_FILE_NAME"
    echo "releases:" > $RELEASES_FILE_NAME
    echo "  - $LATEST" >> $RELEASES_FILE_NAME
  else
    echo "No new release of $APPLICATION detected: $LATEST"
  fi
}

# Get the latest releases of applications..
function check() {

  prometheus_release=$(get_latest_release "prometheus" "prometheus")
  echo "prometheus_release: $prometheus_release"
  exit 0
  check_releases "prometheus" "$prometheus_release"

  alertmanager_release=$(get_latest_release "prometheus" "alertmanager")
  check_releases "alertmanager" "$alertmanager_release"

  node_exporter_release=$(get_latest_release "prometheus" "node_exporter")
  check_releases "node_exporter" "$node_exporter_release"
}

check

