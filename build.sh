#!/bin/bash

set -ex

if [ ! "`whoami`" = "root" ]
then
    echo "\nPlease run script as root."
    exit 1
fi

find /nix/store -name '*docker-image-backend-ryo.tar.gz' #-delete

nix --extra-experimental-features nix-command --extra-experimental-features flakes build .#dockerImage

files=(/nix/store/*docker-image-backend-ryo.tar.gz)

image_path=${files[0]}

tag=$(basename $image_path | sed 's/-docker-image-backend-ryo.tar.gz//')

echo $image_path

echo $tag

docker load -i $image_path

docker image tag backend-ryo:$tag anhdhteko/cardano-local-blockchain:$tag
docker image tag backend-ryo:$tag anhdhteko/cardano-local-blockchain:latest

# docker push anhdhteko/cardano-local-blockchain:latest
