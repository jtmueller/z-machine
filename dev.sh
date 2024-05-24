#!/bin/bash

docker build -t z-machine-dev .
docker run --rm -it -v $(pwd):/usr/src/app z-machine-dev