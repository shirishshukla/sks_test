Demo app of a simple flask application, deploying in a kubernetes cluster in minikube.

Using https://www.ncdc.noaa.gov/cdo-web/webservices/v2#stations 

### Prerequisite
##### minikube 
minikube version: v1.13.1
##### docker 
Docker version 1.13.1, build 64e9980/1.13.1
##### OS
CentOS Linux release 7.8.2003 (Core)

### Deployment files and scripts
* envr.vars           : Declaired varibles in  this file to have dynaminc applicaton and control api paths 

--- file snip..
```
# Application Name
export APP_NAME='flask_api-v1'
export IMAGE_NAME="${APP_NAME}:latest"

# API PTHS
export USPS_API_PATH=/api/v1/resources/states/usps
export STATION_API_PATH=/api/v1/resources/station

# Miniport Registry
export REGISTRY_PORT=5050

# Flask ENV VRS
export AUTH_TOKEN='xxx-your-api-token' # request it from https://www.ncdc.noaa.gov/cdo-web/token
export FLASK_PORT=5000

# K8S Files
export CONFIG_MAP=K8S/config-maps.yml
...
```
* Dockerfile          : Dockerfile to create base image 
* build_dockerfile.sh : Script to build docker image
* create_image.sh     : Script to create image (When testing docker run..)
* k8s_setup_run.sh    : Main script, to create docker registry and deploy application pod and service.
* cleanup.sh          : Delete Application POD and SERVICES

### Application Flask python scrits
* API/requirements.txt : pre-requisite python libraries, get installed during image build via Dockerfile
* API/api.py           : Main API script handles flask session and requst processing 
* API/test_flask.py    : pytest for testing flask connection 

### Kubernetes manifests Files 
* K8S/kube-api.yml
manifest file to deploy pod and service 

* K8S/config-maps.yml
manifest file to create config maps for varibles

### Create Application 
Run script k8s_setup_run.sh

```sh
$ sh k8s_setup_run.sh
```

###### Output Sample 
Last line print svc url, access it in browser .

```
Registry container 5d292cafbf31 already running ..
Registry http://192.168.1.28:5050/ accessible

Building new image flask_api-v1:latest ...
sha256:5b72556fd2b2b488d4e97793c37c3b82f39da3d9bd4fe1b2bd45e2675687d44e

Tag and Push Image 192.168.1.28:5050/flask_api-v1:latest
The push refers to a repository [192.168.1.28:5050/flask_api-v1]
Get https://192.168.1.28:5050/v1/_ping: http: server gave HTTP response to HTTPS client

 ... Creating application pod and service

API POD flask-api-f7cfd877-8txs9 already Running .. deleting it..
pod "flask-api-f7cfd877-8txs9" deleted
configmap/image-config unchanged
configmap/api-env-vars unchanged
deployment.apps/flask-api unchanged
service/flask-api created

API ACCESS URL: http://192.168.1.28:32222
```

###### API WEB PAGE 
As above example access api url in browser, content and usages self-explanatory. 

Sample content on home page.
```
State Stations data from www.ncdc.noaa.gov
A prototype API for getting list of stations from www.ncdc.noaa.gov

http://192.168.1.28:32222/ : Main help page.
http://192.168.1.28:32222/api/v1/resources/states/usps : Get list of all states USPS to FIPS mappings.
http://192.168.1.28:32222/api/v1/resources/station?state=AL : Eg. Get all of the stations in state "AL"
http://192.168.1.28:32222/api/v1/resources/station?state=AL&limit=10&offset=100 : Eg. Get all of the stations in state "AL" from offset and limit result .
```

###### PYTEST Function in API/api.py
test-1: Home page rechability
test-2: Validate Token & connectivity via fetching stations of a state 
pytest API/ 

## END
