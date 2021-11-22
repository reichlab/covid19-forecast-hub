var ghpages = require('gh-pages');
var gh_token = process.env.GH_TOKEN
ghpages.publish(
    'visualization/vis-master/dist',
    {
        repo: 'https://' + gh_token + '@github.com/reichlab/covid19-forecast-hub.git'
    }
)