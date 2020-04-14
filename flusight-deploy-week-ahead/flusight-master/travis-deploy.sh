#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "master" ]; then
    echo "Skipping deploy; just doing a build."
    yarn run parse
    yarn run test
    yarn run build
    exit 0
fi

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Run deployment steps
git checkout gh-pages || git checkout --orphan gh-pages
rm -rf ./dist/* || exit 0

yarn run parse
yarn run test
yarn run build
cp -r ./dist/* ./
# Some cleanup
rm -rf ./dist/*
rm -rf ./data ./test ./src ./scripts ./schema ./paper ./build ./config
rm yarn.lock screen.png screenframe.png

git config user.name "CI auto deploy"
git config user.email "abhinav.tushar.vs@gmail.com"

git add .
git commit -m "Auto deploy to GitHub Pages: ${SHA}"

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_private.enc -out deploy_private -d
chmod 600 deploy_private
eval `ssh-agent -s`
ssh-add deploy_private

# Push to gh-pages
git push $SSH_REPO gh-pages --force
ssh-agent -k
