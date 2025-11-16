#!/usr/bin/env bash

usage() {
  echo "Usage: bash $0 BUCKET_NAME"
  exit 1
}

[[ -z "$1" ]] && usage

bucket="$1"

cd "$HOME"

set -x

tar -czf documents.tgz Documents
tar -czf dot_aws.tgz .aws
tar -czf dot_ssh.tgz .ssh
tar -czf dot_zsh.tgz .zsh*
tar -czf git.tgz git

s3_base=s3://"$bucket"

aws s3 cp documents.tgz "$s3_base"/documents.tgz
aws s3 cp dot_aws.tgz  "$s3_base"/dot_aws.tgz
aws s3 cp dot_ssh.tgz  "$s3_base"/dot_ssh.tgz
aws s3 cp dot_zsh.tgz  "$s3_base"/dot_zsh.tgz
aws s3 cp git.tgz      "$s3_base"/git.tgz
