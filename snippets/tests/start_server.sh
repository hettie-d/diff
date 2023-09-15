#!/bin/bash

docker run --name test-postgres -e POSTGRES_PASSWORD=mysecretpassword -d postgres