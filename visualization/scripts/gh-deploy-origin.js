var ghpages = require('gh-pages');

ghpages.publish(
    'visualization/vis-master/dist',
    {
        remote: 'origin'
    }
)