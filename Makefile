.DEFAULT_GOAL := help

MAKESTER__REPO_NAME := loum
MAKESTER__CONTAINER_NAME := spark-pseudo

HADOOP_VERSION := 3.2.2
SPARK_VERSION := 3.1.2
SPARK_RELEASE := spark-$(SPARK_VERSION)-bin-without-hadoop

# Tagging convention used: <hadoop-version>-<spark-version>-<image-release-number>
MAKESTER__VERSION := $(HADOOP_VERSION)-$(SPARK_VERSION)
MAKESTER__RELEASE_NUMBER := 3

include makester/makefiles/base.mk
include makester/makefiles/docker.mk
include makester/makefiles/python-venv.mk

UBUNTU_BASE_IMAGE := focal-20210723
HADOOP_PSEUDO_BASE_IMAGE := $(HADOOP_VERSION)-1
OPENJDK_8_HEADLESS := 8u292-b10-0ubuntu1~20.04
PYTHON3_VERSION := 3.8.10-0ubuntu1~20.04

export PATH := $(MAKESTER__PROJECT_DIR)/3env/bin:$(PATH)

MAKESTER__BUILD_COMMAND = $(DOCKER) build --rm\
 --no-cache\
 --build-arg SPARK_VERSION=$(SPARK_VERSION)\
 --build-arg SPARK_RELEASE=$(SPARK_RELEASE)\
 --build-arg UBUNTU_BASE_IMAGE=$(UBUNTU_BASE_IMAGE)\
 --build-arg HADOOP_PSEUDO_BASE_IMAGE=$(HADOOP_PSEUDO_BASE_IMAGE)\
 --build-arg OPENJDK_8_HEADLESS=$(OPENJDK_8_HEADLESS)\
 --build-arg PYTHON3_VERSION=$(PYTHON3_VERSION)\
 -t $(MAKESTER__IMAGE_TAG_ALIAS) .

MAKESTER__RUN_COMMAND := $(DOCKER) run --rm -d\
 --publish 8032:8032\
 --publish 7077:7077\
 --publish 8080:8080\
 --publish 8088:8088\
 --publish 8042:8042\
 --publish 18080:18080\
 --hostname $(MAKESTER__CONTAINER_NAME)\
 --name $(MAKESTER__CONTAINER_NAME)\
 $(MAKESTER__SERVICE_NAME):$(HASH)

init: clear-env makester-requirements

backoff:
	@$(PYTHON) makester/scripts/backoff -d "YARN ResourceManager" -p 8032 localhost
	@$(PYTHON) makester/scripts/backoff -d "YARN ResourceManager webapp UI" -p 8088 localhost
	@$(PYTHON) makester/scripts/backoff -d "YARN NodeManager webapp UI" -p 8042 localhost
	@$(PYTHON) makester/scripts/backoff -d "Spark HistoryServer web UI port" -p 18080 localhost
	@$(PYTHON) makester/scripts/backoff -d "Spark master" -p 7077 localhost
	@$(PYTHON) makester/scripts/backoff -d "Spark web UI port" -p 8080 localhost

controlled-run: run backoff

hadoop-version:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME) /opt/hadoop/bin/hadoop version || true

spark-version: controlled-run
	@$(DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop /opt/spark/bin/spark-submit --version" || true

pi:
	@$(DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop /opt/spark/bin/spark-submit --class org.apache.spark.examples.SparkPi\
 --files /opt/spark/conf/metrics.properties.template\
 --master yarn\
 --deploy-mode cluster\
 --driver-memory 1g\
 --executor-memory 1g\
 --executor-cores 1\
 /opt/spark/examples/jars/spark-examples_2.*-$(SPARK_VERSION).jar"

pi-standalone:
	spark-submit\
 --master spark://localhost:7077\
 https://raw.githubusercontent.com/apache/spark/master/examples/src/main/python/pi.py

yarn-apps:
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn application -list -appStates ALL"

check-yarn-app-id:
	$(call check_defined, YARN_APPLICATION_ID)
yarn-app-log: check-yarn-app-id
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn logs -log_files stdout -applicationId $(YARN_APPLICATION_ID)"

pyspark: backoff
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/spark/bin/pyspark"

spark: backoff
	@$(DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/spark/bin/spark-shell"

help: makester-help docker-help python-venv-help
	@echo "(Makefile)\n\
  hadoop-version       Hadoop version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  spark-version        Spark version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  yarn-apps            List all YARN application IDs\n\
  yarn-app-log         Dump log for YARN application ID defined by \"YARN_APPLICATION_ID\"\n\
  pyspark              Start the pyspark REPL\n\
  spark                Start the spark REPL\n\
  pi                   Run the sample Spark Pi application on YARN cluster\n\
  pi-standalone        Run the sample Spark Pi application on Spark standalone cluster\n"
