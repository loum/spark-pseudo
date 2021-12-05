# Apache Spark (YARN on Pseudo Distributed Hadoop) with Docker
- [Overview](#Overview)
- [Quick Links](#Quick-Links)
- [Quick Start](#Quick-Start)
- [Prerequisites](#Prerequisites)
- [Getting Started](#Getting-Started)
- [Getting Help](#Getting-Help) 
- [Docker Image Management](#Docker-Image-Management)
  - [Image Build](#Image-Build)
  - [Image Searches](#Image-Searches)
  - [Image Tagging](#Image-Tagging) 
- [Interact with Apache Spark](#Interact-with-Apache-Spark)
  - [Start a shell on the Container](#Start-a-shell-on-the-Container)
  - [Submitting Applications to Spark](#Submitting-Applications-to-Spark)
    - [Sample SparkPi Application](#Sample-SparkPi-Application)
  - [`pyspark`](#`pyspark`)
  - [`spark`](#`spark`)
- [Web Interfaces](#Web-Interfaces)

## Overview
Quick and easy way to get Spark (YARN on Pseudo Distributed Hadoop) with Docker.

This repository will build you a Docker image that allows you to run Apache Spark as a compute engine.  [Spark itself uses YARN as the resource manager](https://spark.apache.org/docs/3.2.0/running-on-yarn.html) which we leverage from the underlying Hadoop install.  See documentation on the [Pseudo Hadoop base Docker image](https://github.com/loum/hadoop-pseudo) for details on how Hadoop/YARN has been configured.

## Quick Links
- [Apache Hadoop](https://hadoop.apache.org/)
- [Apache Spark](https://spark.apache.org/)

## Quick Start
Impatient and just want Spark quickly?
```
docker run --rm -d --name spark-pseudo loum/spark-pseudo:latest
```
## Prerequisties
- [Docker](https://docs.docker.com/install/)
- [GNU make](https://www.gnu.org/software/make/manual/make.html)

## Getting Started
Get the code and change into the top level `git` project directory:
```
git clone https://github.com/loum/spark-pseudo.git && cd spark-pseudo
```
> **_NOTE:_** Run all commands from the top-level directory of the `git` repository.

For first-time setup, get the [Makester project](https://github.com/loum/makester.git):
```
git submodule update --init
```
Keep [Makester project](https://github.com/loum/makester.git) up-to-date with:
```
make submodule-update
```
Setup the environment:
```
make init
```
## Getting Help
There should be a `make` target to get most things done.  Check the help for more information:
```
make help
```
## Docker Image Management
### Image Build
The image build compiles Spark from scratch to ensure we get the correct version without the YARN libraries.  More info can be found at the [Spark build page](http://spark.apache.org/docs/2.4.8/building-spark.html).

To build the Docker image against Apache Spark version `SPARK_VERSION` (defaults to `3.2.0`):
```
make build-image
```
You can target a specific Apache Spark release by setting `SPARK_VERSION`.  For example:
```
SPARK_VERSION=3.0.3 make build image
```
> **_NOTE:_** the image builds against Python 3 so you may be limited around which versions of `pyspark` you can use.  For example, `pyspark` against `SPARK_VERSION` `2.4.8` breaks Livy.

### Image Searches
Search for existing Docker image tags with command:
```
make search-image
```
### Image Tagging
By default, `makester` will tag the new Docker image with the current branch hash.  This provides a degree of uniqueness but is not very intuitive.  That's where the `tag-version` `Makefile` target can help.  To apply tag as per project tagging convention `<hadoop-version>-<spark-version>-<image-release-number>`:
```
make tag-version
```
To tag the image as `latest`:
```
make tag-latest
```
## Interact with Apache Spark
To start the container and wait for all Hadoop services to initiate:
```
make controlled-run
```
To stop the container:
```
make stop
```
### Start a shell on the Container
```
make login
```
### Submitting Applications to Spark
The [Spark computing system](<https://spark.apache.org/docs/latest/index.html>)_ is available and can be invoked as per normal.  More information on submitting applications to Spark can be found [here](https://spark.apache.org/docs/2.4.8/submitting-applications.html).

#### Sample SparkPi Application
The [sample SparkPi application](https://spark.apache.org/docs/2.4.8/running-on-yarn.html#launching-spark-on-yarn) can be launched with:
```
make pi
```
Apart from some verbose logging displayed on the console it may appear that not much has happened here.  However, since the [Spark application has been deployed in cluster mode](https://spark.apache.org/docs/2.4.8/cluster-overview.html) you will need to dump the associated application ID's log to see meaningful output.  To get a list of Spark application logs (under YARN):
```
make yarn-apps
```
Then plug in an `Application-Id` into:
```
make yarn-app-log YARN_APPLICATION_ID=<Application-Id>
```
To see something similar to the following::
```
====================================================================
LogType:stdout
LogLastModifiedTime:Sat Apr 11 21:49:03 +0000 2020
LogLength:33
LogContents:
Pi is roughly 3.1398156990784956

End of LogType:stdout
***********************************************************************
```
### `pyspark`
```
make pyspark
```
```
Python 3.8.10 (default, Jun  2 2021, 10:49:15) 
[GCC 9.4.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 3.2.0
      /_/

Using Python version 3.8.10 (default, Jun  2 2021 10:49:15)
Spark context Web UI available at http://spark-pseudo:4040
Spark context available as 'sc' (master = yarn, app id = application_1625998641423_0001).
SparkSession available as 'spark'.
>>>
```
> **_Note:_** see Apache Spark limitations in the [image build process](#Image-Build).

### `spark`
```
make spark
```
```
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
Spark context Web UI available at http://spark-pseudo:4040
Spark context available as 'sc' (master = yarn, app id = application_1625998641423_0002).
Spark session available as 'spark'.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 3.2.0
      /_/
         
Using Scala version 2.12.15 (OpenJDK 64-Bit Server VM, Java 11.0.11)
Type in expressions to have them evaluated.
Type :help for more information.

scala> 
```
## Web Interfaces
The following web interfaces are available to view configurations and logs and to track YARN/Spark job submissions:
- YARN NameNode web UI: http://localhost:8042
- YARN ResourceManager web UI: http://localhost:8088
- Spark History Server web UI: http://localhost:18080

---
[top](Apache-Spark-(YARN-on-Pseudo-Distributed-Hadoop)-with-Docker)
