#!/usr/bin/env bash

# Script installing and register gitlab-runner in docker
# To run script type 'sudo docker_runner_install.sh <gitlab-url> <project-registration-token>'

docker run -d \
 --name gitlab-runner \
 --restart always \
 -v /srv/gitlab-runner/config:/etc/gitlab-runner \
 -v /var/run/docker.sock:/var/run/docker.sock \
 gitlab/gitlab-runner:latest

docker run --rm -v /srv/gitlab-runner/config:/etc/gitlab-runner gitlab/gitlab-runner register \
 --non-interactive \
 --executor "docker" \
 --docker-image alpine:latest \
 --url "$1" \
 --registration-token "$2" \
 --description "docker-runner" \
 --tag-list "linux,xenial,ubuntu,docker" \
 --run-untagged="true" \
 --locked="false" \
 --access-level="not_protected"

