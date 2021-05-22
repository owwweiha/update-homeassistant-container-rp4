#!/bin/bash
### COLOR
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

# full path (including registry like docker.io or gcr.io) to image that should be used
image="docker.io/homeassistant/raspberrypi4-homeassistant:stable"
# name of container for podman commands
container_name="homeassistant"
# path to config folder for homeassistant
config_folder=$1

usage() {
  echo -e "${RED}ERROR: Variable $1 not set. Usage: bash update-homeassistant <config_folder>${NC}"
}

not_a_folder() {
  echo -e "${RED}ERROR: Variable $1 is not a folder${NC}"
}

check_var() {
  if [[ -z ${config_folder} ]]; then
    usage config_folder
    exit 1
  fi

  if [[ ! -d $config_folder ]]; then
    not_a_folder config_folder
    exit 1
  fi
}

check_image() {
  echo -e "Checking whether image ${CYAN}${image}${NC} exists or not"
  podman image exists "${image}"

  if [[ "${?}" == 0 ]]; then
    echo -e "Image ${CYAN}${image}${NC} already exists\n"
    return 1
  else
    echo -e "Image ${CYAN}${image}${NC} does not exist yet\n"
    return 0
  fi
}

check_container() {
  echo -e "Checking whether image ${CYAN}${image}${NC} is already in use or not"
  podman container exists "${container_name}"

  if [[ "${?}" == 0 ]]; then
    echo -e "Image ${CYAN}${image}${NC} is already in use\n"
    return 1
  else
    echo -e "Image ${CYAN}${image}${NC} is not used by any container, going to update now\n"
    return 0
  fi
}

update_image() {
  podman pull "${image}"
}

update_container() {
  echo -e "${RED}Stopping old ${CYAN}${container_name}${NC} container${NC}"
  podman stop "${container_name}"

  echo -e "${RED}Removing old ${CYAN}${container_name}${NC} container${NC}"
  podman rm "${container_name}"

  echo -e "Starting new ${CYAN}${container_name}${NC} container"
  podman run \
  --init \
  --detach \
  --name "${container_name}" \
  --restart=unless-stopped \
  --volume /etc/localtime:/etc/localtime:ro \
  --volume "${config_folder}":/config \
  --network=host \
  "${image}"

  echo -e "${GREEN}Done${NC}"
}

compare_image_digest() {
  echo -e "Comparing image id of running ${CYAN}${container_name}${NC} container with image id of ${CYAN}${image}${NC}"
  # there is a container named ${container_name} running. get image id
  container_image_id=$(podman inspect ${container_name} --format "{{.Image}}")
  container_image_digest=$(podman inspect ${container_image_id} --format "{{.Digest}}")
  image_digest=$(podman inspect ${image} --format "{{.Digest}}")
  if [[ "${container_image_digest}" == "${image_digest}" ]]; then
    echo -e "Container ${CYAN}${container_name}${NC} is already on newest image version\n"
    return 1
  else
    echo -e "Container ${CYAN}${container_name}${NC} is not on newest image version, needs to be updated\n"
    return 0
  fi
}

main() {
  date
  check_var

  check_image
  image_exists=$?
  if [[ "${image_exists}" == 0 ]]; then
    update_image
  fi

  check_container
  container_exists=$?
  if [[ "${container_exists}" == 0 ]]; then
    update_container
  elif [[ "${container_exists}" == 1 ]]; then
    compare_image_digest
    newest_image_running=$?
    if [[ "${newest_image_running}" == 1 ]]; then
      echo -e "${GREEN}Nothing to do${NC}"
    else
      update_container
    fi
  fi
}

main
