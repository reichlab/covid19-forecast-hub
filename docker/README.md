## Build container

Download this Dockerfile and build the container using the `docker build` command:

```
mkdir covid19-forecast-hub
cd covid19-forecast-hub
wget https://raw.githubusercontent.com/reichlab/covid19-forecast-hub/master/docker/Dockerfile
docker build -t covid19-forecast-hub .
```

## Start container

Use:

```
docker run -p 8000:8000 -it covid19-forecast-hub 
```

And open the site from your localhost at `127.0.0.1:8000`
