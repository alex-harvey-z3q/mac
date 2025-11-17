#!/usr/bin/env bash

usage() {
  echo "Usage: bash $0 BUCKET_NAME"
  exit 1
}

[[ -z "$1" ]] && usage

bucket="$1"

s3_base=s3://"$bucket"

cd "$HOME"

(set -x
 aws s3 cp "$s3_base"/Documents.tgz Documents.tgz
 aws s3 cp "$s3_base"/dot_aws.tgz   dot_aws.tgz
 aws s3 cp "$s3_base"/dot_ssh.tgz   dot_ssh.tgz
 aws s3 cp "$s3_base"/dot_zsh.tgz   dot_zsh.tgz
 aws s3 cp "$s3_base"/git.tgz       git.tgz)

echo "To untar the files:"
echo "tar -xzf Documents.tgz"
echo "tar -xzf dot_aws.tgz"
echo "tar -xzf dot_ssh.tgz"
echo "tar -xzf dot_zsh.tgz"
echo "tar -xzf git.tgz"
