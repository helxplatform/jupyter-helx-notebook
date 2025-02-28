## Introduction

This project creates a few different container images that are meant to be run within our HeLx platform. It uses the scipy-notebook image as the base image in the ordr-d project and the minimal-poetry-notebook as the base image in the rest of the projects. The minimal-poetry-notebook base image is based on the minimal-notebook base image and just adds Poetry and a few linux packages onto it (most important of which is upgrading git). Eventually ordr-d should probably be moved over to using minimal-poetry-notebook because it's very likely that that notebook + whatever packages you need has much fewer vulnerabilities according to a trivy scan than scipy-notebook. 

## Configuring

Some configuration variables can be set in the "config.env" file. Also some to use when running the container locally.  "run.env" can be used to set variables within the container when running.

You may also notice a `root/` directory in each project. In each Dockerfile, we copy the contents of that `root/` directory to the `/` directory in the image. So if there are scripts in a subdirectory, they'll get copied over. In the case of ordr-d, those scripts are still in the project, but in the case of the rest of the projects, we've pulled the startup scripts into the minimal-poetry-notebook image, since all container images with jupyter will need those.

## Building

To build the image you can use the basic docker command or use the included Makefile.
```
  make build
```
  To build the image without using the docker cache you can use the 'build-nc' argument.

## Running Locally

```
  make run
```
  Then connect to localhost:8888 in your web browser.

## Publishing Image to Registry
  To push the image to the configured registry (in config.env) use the 'publish' argument.
```
  make publish
```
  To build the image without the docker cache and publish you can use the 'release' argument.

## Container Environment Variables
  USER | NB_USER : Used to change the username of the process running within the container.
  
  NB_PREFIX : Used to set the URL path prefix to access the Jupyter datascience-notebook. 
