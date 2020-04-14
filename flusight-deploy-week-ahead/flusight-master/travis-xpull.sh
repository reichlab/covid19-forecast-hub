#!/usr/bin/env bash

# Script for handling xpull triggers
set -e

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Setup credentials
git config user.name "CI auto deploy"
git config user.email "lepisma@fastmail.com"
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_private.enc -out deploy_private -d
chmod 600 deploy_private
eval `ssh-agent -s`
ssh-add deploy_private

echo "This is a trigger from another repository."
npm install -g "reichlab/xpull"
xpull --repo "reichlab/2017-2018-cdc-flu-contest" --message "[TRAVIS] Xpulled files from travis"
git push $SSH_REPO HEAD:master
ssh-agent -k
