# CD/CI workflows with GitHub actions

COVID-19 Forecast Hub uses GitHub actions as its primary CD/CI tool.[^1] This page documents the actions and scripts involved with our CD/CI process.

[^1]: As the repository is getting larger in size, the GitHub Actions runner is unable to provide enough disk space for our CD/CI scripts. We are in progress of moving some actions to a Githooks based triggering system on a cloud VM.

Some actions may contain identical initial steps. This is because each time a GitHub action is run, it is run on a clean VM with no software/packages/libraries installed.

## 1. Deploy to GitHub Pages

### Summary

1. Check disk space and delete temporary files
2. Checkout latest commit on `master` (uses [this external action](https://github.com/actions/checkout))
3. Install Node.js (uses [this external action](https://github.com/actions/setup-node))
4. Install Python (uses [this external action](https://github.com/actions/setup-python))
5. Install [Node.js requirements](https://github.com/reichlab/covid19-forecast-hub/blob/master/package.json)
6. Install [Python requirements](https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/requirements.txt)
7. Deploy the contents in [`visualization/vis-master/dist`](https://github.com/reichlab/covid19-forecast-hub/tree/master/visualization/vis-master/dist) onto the [`gh-pages` branch](https://github.com/reichlab/covid19-forecast-hub/tree/gh-pages)

### Details

This action is quite simple. The Hub uses GitHub Pages to host our external-facing website; GitHub Pages hosts files on the `gh-pages` branch.[^2] The file `visualization/vis-master/dist/CNAME` determines under which domain should the host be configured.

[^2]: Detailed documentation of GitHub Pages is available [here](https://docs.github.com/en/free-pro-team@latest/github/working-with-github-pages).


