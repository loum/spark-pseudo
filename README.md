# Apache Spark (YARN on Pseudo Distributed Hadoop) Container Image

- [Overview](#overview)
- [Quick Links](#quick-links)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Getting Help](#getting-help)
- [Container Image Management](#container-image-management)
- [Interact with Apache Spark](#interact-with-apache-spark)
  - [Configuration](#configuration)
  - [Container runtime control](#container-runtime-control)
  - [Submitting Applications to Spark](#submitting-applications-to-spark)
    - [Sample SparkPi Application](#sample-sparkpi-application)
- [Useful Commands](#useful-commands)
- [Web Interfaces](#Web-Interfaces)

## Overview
Quick and easy way to get Spark (YARN on Pseudo Distributed Hadoop) with Docker.

This repository will build you a Docker image that allows you to run Apache Spark as a compute engine.  [Spark itself uses YARN as the resource manager](https://spark.apache.org/docs/3.2.0/running-on-yarn.html) which we leverage from the underlying Hadoop install.  See documentation on the [Pseudo Hadoop base Docker image](https://github.com/loum/hadoop-pseudo) for details on how Hadoop/YARN has been configured.

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Quick Links
- [Apache Hadoop](https://hadoop.apache.org/)
- [Apache Spark](https://spark.apache.org/)

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Quick Start
Impatient, and just want Spark quickly?
```
docker run --rm -d --name spark-pseudo loum/spark-pseudo:latest
```

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Prerequisites
- [Docker](https://docs.docker.com/install/)
- [GNU make](https://www.gnu.org/software/make/manual/make.html)
- Python 3 Interpreter. [We recommend installing pyenv](https://github.com/pyenv/pyenv).

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

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

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Getting Help
There should be a `make` target to get most things done.  Check the help for more information:
```
make help
```

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Container Image Management

> **_NOTE:_**  See [Makester's `docker` subsystem](https://loum.github.io/makester/makefiles/docker/) for more detailed container image operations.

Build the container image locally:
```
make image-build
```

Search for built container image:
```
make image-search
```

Delete the container image:
```
make image-rm
```

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Interact with Apache Spark
### Configuration
Every Hadoop configuration settings can be overridden during container startup by targeting the setting name and prepending the configuration file context as per the following:

-   [Hadoop core-default.xml](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/core-default.xml)  | Override with  `CORE_SITE__<setting>`
-   [Hadoop hdfs-default.xml](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/hdfs-default.xml)  | Override token  `HDFS_SITE__<setting>`
-   [Hadoop mapred-default.xml](https://hadoop.apache.org/docs/stable/hadoop-mapreduce-client/hadoop-mapreduce-client-core/mapred-default.xml)  | Override with  `MAPRED_SITE__<setting>`
-   [Hadoop yarn-default.xml](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-common/yarn-default.xml)  | Override with  `YARN_SITE__<setting>`

Similarly, for Spark environment settings:

-  [spark-env.sh](https://github.com/apache/spark/blob/master/conf/spark-env.sh.template) | Override with `SPARK_ENV__<setting>`. For example, to control the Spark executor settings you can add the following `SPARK_ENV__*` environment variables to Docker `run`:
```
docker run --rm -d --name jupyter-spark-pseudo\
 --hostname jupyter-spark-pseudo\
 --env JUPYTER_PORT=8889\
 --volume $(PWD)/jupyter-spark-pseudo/notebooks:/home/hdfs/notebooks\
 --env YARN_SITE__YARN_NODEMANAGER_RESOURCE_DETECT_HARDWARE_CAPABILITIES=true\
 --env SPARK_ENV__SPARK_EXECUTOR_CORES=2\
 --env SPARK_ENV__SPARK_EXECUTOR_INSTANCES=7\
 --env SPARK_ENV__SPARK_EXECUTOR_MEMORY=1280m\
 --publish 8032:8032\
 --publish 8088:8088\
 --publish 8042:8042\
 --publish 18080:18080\
 --publish 8889:8889\
 loum/jupyter-spark-pseudo:latest
```

### Container runtime control
`controlled-run` is a convenience target to start the container with basic configuration, and wait for all Hadoop services to initiate:
```
make controlled-run
```

To stop the container:
```
make container-stop
```

### Submitting applications to Spark
The [Spark computing system](<https://spark.apache.org/docs/latest/index.html>)_ is available and can be invoked as per normal.  More information on submitting applications to Spark can be found [here](https://spark.apache.org/docs/2.4.8/submitting-applications.html).

#### Sample SparkPi application
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
To see something similar to the following:
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

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Useful Commands
To start the `pyspark` REPL:
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
> **_NOTE:_** see Apache Spark limitations in the [image build process](#Image-Build).

To start the `spark-shell` REPL:
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

[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)

## Web Interfaces
The following web interfaces are available to view configurations and logs and to track YARN/Spark job submissions:
- YARN NameNode web UI: http://localhost:8042
- YARN ResourceManager web UI: http://localhost:8088
- Spark History Server web UI: http://localhost:18080

---
[top](#apache-spark-yarn-on-pseudo-distributed-hadoop-container-image)
