setup_git() {
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis CI"
}

setup_git()
git checkout gh-pages
git fetch origin master
git checkout origin/master  -- ./visualization/vis-master/dist
cd ./visualization/vis-master
cp -r ./dist/* ../../