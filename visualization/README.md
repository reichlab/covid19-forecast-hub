# Interactive Visualization

### Building the visualization locally
```
npm install
bash ./0-init-flusight.sh

# if on mac
bash ./2-mac-build-flusight.sh

# if on linux
bash ./1-patch-flusight.sh
bash ./2-build-flusight.sh
```

### Serving the visualization locally 
If you have Python 2.x:
```
cd flusight-master/dist
python -m SimpleHTTPServer
```

If you have Python 3.x:
```
cd flusight-master/dist
python3 -m http.server
```
