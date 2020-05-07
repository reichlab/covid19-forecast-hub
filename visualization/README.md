# Interactive Visualization
* [Step 0: One Time Set Up](#step-0-one-time-Setup-on-Mac)
* [Step 1: Building Locally](#step-1-building-locally)
* [Step 2: Viewing Locally](#step-2-viewing-locally)

<a href = "https://reichlab.io/covid19-forecast-hub/">
 <img src="https://github.com/reichlab/covid19-forecast-hub/blob/master/visualization/vis-master/chart.png" width="500" alt="chart">
</a>

## About
The interactive visualization was based on [d3-foresight](https://github.com/reichlab/d3-foresight) a [D3.js](https://d3js.org/) package built by the Reich Lab. Some custom package configurations were made and the adapted d3-foresight package is called [covid-d3-foresight](https://github.com/reichlab/covid19-forecast-hub/tree/master/visualization/vis-master/covid-d3-foresight).

## Dependencies
These are automatically installed when you run the [one time setup](#one-time-setup-on-mac)
* [Python 3.x](https://www.python.org/downloads/)
* [pip3](https://pip.pypa.io/en/stable/)
* [node](https://nodejs.org/en/download/)

#### Python Package dependencies
* [setuptools](https://pypi.org/project/setuptools/)
* [pandas](https://pypi.org/project/pandas/)
* [pymmwr](https://github.com/reichlab/pymmwr)
* [click](https://pypi.org/project/click/)
* [requests](https://pypi.org/project/requests/)
* [urllib3](https://pypi.org/project/urllib3/)
* [selenium](https://pypi.org/project/selenium/)

## Step 0: One time Setup on Mac
1. Install [Homebrew](https://treehouse.github.io/installation-guides/mac/homebrew)
```ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"```
1. Install python3 ```brew install python3```
1. Install node ```brew install node```
1. Install yarn ```brew install yarn```
1. Run one-time setup 
```
cd ./visualization
bash ./one-time-setup.sh
```


## Step 1: Building locally
```
cd ./visualization
bash ./0-init-vis.sh

# if on mac
bash ./2-mac-build-vis.sh

# if on linux
bash ./1-patch-vis.sh
bash ./2-build-vis.sh
```

## Step 2: Viewing locally 
If you have Python 2.x:
```
cd ./visualization/vis-master/dist
python -m SimpleHTTPServer
```

If you have Python 3.x:
```
cd ./visualization/vis-master/dist
python3 -m http.server
```
