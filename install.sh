#!/bin/bash

[ ! -z "$1" ] || { echo "tool not specified"; exit 1; }
[ ! -z "$GITHUB_TOKEN" ] || { echo "GITHUB_TOKEN not specified"; exit 1; }

TOOL=$1
BUILD_TARGET=${OSTYPE//[0-9.]/}_$(arch)

RELEASE_LATEST=$(curl -s -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/era-dk/$TOOL-tool/releases/latest | jq -r ".assets // empty")
[ ! -z "$RELEASE_LATEST" ] || { echo "release not found"; exit 1; }

RELEASE_TARGET=$(echo $RELEASE_LATEST | jq -r ".[] | select(.name | contains(\"${BUILD_TARGET}.tar.gz\"))")
[ ! -z "$RELEASE_TARGET" ] || { echo "release target not found"; exit 1; }

RELEASE_ARCHIVE=$(echo $RELEASE_TARGET | jq -r '.name // empty')
[ ! -z "$RELEASE_ARCHIVE" ] || { echo "release archive name not found"; exit 1; }

RELEASE_URL=$(echo $RELEASE_TARGET | jq -r '.url // empty')
[ ! -z "$RELEASE_URL" ] || { echo "release archive url not found"; exit 1; }

TMP_DIR=$(mktemp -d)
curl -L \
  -H "Accept: application/octet-stream" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  $RELEASE_URL > $TMP_DIR/$RELEASE_ARCHIVE

BIN_DIR=/usr/local/bin
tar -zxvf $TMP_DIR/$RELEASE_ARCHIVE -C $TMP_DIR/
sudo mv -f $TMP_DIR/era-$TOOL $BIN_DIR/era-$TOOL
sudo chmod +x $BIN_DIR/era-$TOOL

rm -rf $TMP_DIR
echo "era-$TOOL installed"