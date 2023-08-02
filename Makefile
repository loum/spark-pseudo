.SILENT:
.DEFAULT_GOAL := help

MAKESTER__INCLUDES := py docker versioning
MAKESTER__REPO_NAME := loum

include makester/makefiles/makester.mk

#
# Makester overrides.
#
# Container image build.
export HADOOP_VERSION := 3.3.6
export SPARK_VERSION ?= 3.4.1

# Tagging convention used: <HADOOP_VERSION>-<SPARK_VERSION>-<MAKESTER__RELEASE_NUMBER>
MAKESTER__VERSION := $(HADOOP_VERSION)-$(SPARK_VERSION)
MAKESTER__RELEASE_NUMBER := 1

MAKESTER__IMAGE_TARGET_TAG := $(MAKESTER__RELEASE_VERSION)

SPARK_RELEASE := spark-$(SPARK_VERSION)-bin-without-hadoop
HADOOP_PSEUDO_BASE_IMAGE := loum/hadoop-pseudo:$(HADOOP_VERSION)
MAKESTER__BUILD_COMMAND = --rm --no-cache\
 --build-arg SPARK_VERSION=$(SPARK_VERSION)\
 --build-arg SPARK_RELEASE=$(SPARK_RELEASE)\
 --build-arg HADOOP_PSEUDO_BASE_IMAGE=$(HADOOP_PSEUDO_BASE_IMAGE)\
 -t $(MAKESTER__IMAGE_TAG_ALIAS) .

MAKESTER__CONTAINER_NAME := spark-pseudo
MAKESTER__RUN_COMMAND := $(MAKESTER__DOCKER) run --rm -d\
 --hostname $(MAKESTER__CONTAINER_NAME)\
 --name $(MAKESTER__CONTAINER_NAME)\
 --publish 8032:8032\
 --publish 7077:7077\
 --publish 8080:8080\
 --publish 8088:8088\
 --publish 8042:8042\
 --publish 18080:18080\
 --env YARN_SITE__YARN_LOG_AGGREGATION_ENABLE=true\
 $(MAKESTER__IMAGE_TAG_ALIAS)

#
# Local Makefile targets.
#
# Initialise the development environment.
init: py-venv-clear py-venv-init py-install-makester

_backoff:
	@venv/bin/makester backoff $(MAKESTER__LOCAL_IP) 8032 --detail "YARN ResourceManager"
	@venv/bin/makester backoff $(MAKESTER__LOCAL_IP) 8088 --detail "YARN ResourceManager webapp UI"
	@venv/bin/makester backoff $(MAKESTER__LOCAL_IP) 8042 --detail "YARN NodeManager webapp UI"
	@venv/bin/makester backoff $(MAKESTER__LOCAL_IP) 18080 --detail "Spark HistoryServer web UI port"
	@venv/bin/makester backoff $(MAKESTER__LOCAL_IP) 7077 --detail "Spark master"
	@venv/bin/makester backoff $(MAKESTER__LOCAL_IP) 8080 --detail "Spark web UI port"

image-bulk-build:
	$(info ### Container image bulk build ...)
	scripts/bulkbuild.sh

image-pull-into-docker:
	$(info ### Pulling local registry image $(MAKESTER__IMAGE_TAG_ALIAS) into docker)
	$(MAKESTER__DOCKER) pull $(MAKESTER__IMAGE_TAG_ALIAS)

image-tag-in-docker: image-pull-into-docker
	$(info ### Tagging local registry image $(MAKESTER__IMAGE_TAG_ALIAS) => $(MAKESTER__STATIC_SERVICE_NAME):$(MAKESTER__RELEASE_VERSION))
	$(MAKESTER__DOCKER) tag $(MAKESTER__IMAGE_TAG_ALIAS) $(MAKESTER__STATIC_SERVICE_NAME):$(MAKESTER__RELEASE_VERSION)

image-transfer: image-tag-in-docker
	$(info ### Deleting pulled image $(MAKESTER__IMAGE_TAG_ALIAS))
	$(MAKESTER__DOCKER) rmi $(MAKESTER__IMAGE_TAG_ALIAS)

multi-arch-build:
	$(info ### Starting multi-arch builds ...)
	$(MAKE) image-buildx-builder
	$(MAKESTER__DOCKER) buildx ls
	$(MAKE) MAKESTER__DOCKER_DRIVER_OUTPUT=push MAKESTER__DOCKER_PLATFORM=linux/arm64,linux/amd64 image-buildx

amd-arch-build: PLATFORM := linux/amd64
arm-arch-build: PLATFORM := linux/arm64
amd-arch-build arm-arch-build: _arch-build

_arch-build:
	$(MAKE) image-buildx-builder
	$(MAKESTER__DOCKER) buildx ls
	$(MAKE) MAKESTER__DOCKER_DRIVER_OUTPUT=push MAKESTER__DOCKER_PLATFORM=$(PLATFORM) image-buildx

controlled-run: container-run _backoff

hadoop-version:
	@$(MAKESTER__DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME) /opt/hadoop/bin/hadoop version || true

spark-version:
	@$(MAKESTER__DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
 "HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop /opt/spark/bin/spark-submit --version" || true

pi:
	@$(MAKESTER__DOCKER) exec $(MAKESTER__CONTAINER_NAME) bash -c\
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
	@$(MAKESTER__DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn application -list -appStates ALL"

check-yarn-app-id:
	$(call check_defined, YARN_APPLICATION_ID)
yarn-app-log: check-yarn-app-id
	@$(MAKESTER__DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/hadoop/bin/yarn logs -log_files stdout -applicationId $(YARN_APPLICATION_ID)"

pyspark:
	@$(MAKESTER__DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/spark/bin/pyspark"

spark:
	@$(MAKESTER__DOCKER) exec -ti $(MAKESTER__CONTAINER_NAME)\
 bash -c "/opt/spark/bin/spark-shell"

help: makester-help
	@echo "(Makefile)\n\
  controlled-run       Start and wait until all container services stabilise\n\
  hadoop-version       Hadoop version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  image-bulk-build     Build all multi-platform container images\n\
  init                 Build the local development environment\n\
  pi                   Run the sample Spark Pi application on YARN cluster\n\
  pi-standalone        Run the sample Spark Pi application on Spark standalone cluster\n\
  pyspark              Start the pyspark REPL\n\
  spark                Start the spark REPL\n\
  spark-version        Spark version in running container $(MAKESTER__CONTAINER_NAME)\"\n\
  yarn-app-log         Dump log for YARN application ID defined by \"YARN_APPLICATION_ID\"\n\
  yarn-apps            List all YARN application IDs\n"
