# Interactive Visualization

### Building the visualization locally
```
bash ./0-init-vis.sh

# if on mac
bash ./2-mac-build-vis.sh

# if on linux
bash ./1-patch-vis.sh
bash ./2-build-vis.sh
```

### Serving the visualization locally 
If you have Python 2.x:
```
cd vis-master/dist
python -m SimpleHTTPServer
```

If you have Python 3.x:
```
cd vis-master/dist
python3 -m http.server
```
