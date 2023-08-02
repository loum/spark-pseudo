#!/bin/sh
#
LATEST_SPARK_VERSION=$SPARK_VERSION
LATEST_HADOOP_VERSION=$HADOOP_VERSION

for HADOOP_VERSION in 3.3.6
do
    HADOOP_PSEUDO_BASE_IMAGE=loum/hadoop-pseudo:$HADOOP_VERSION

    for SPARK_VERSION in 3.4.0 3.4.1
    do
        SPARK_RELEASE=spark-$SPARK_VERSION-bin-without-hadoop
        CMD="docker buildx build --platform linux/arm64,linux/amd64
 --push --rm --no-cache
 --build-arg HADOOP_PSEUDO_BASE_IMAGE=$HADOOP_PSEUDO_BASE_IMAGE
 --build-arg SPARK_VERSION=$SPARK_VERSION
 --build-arg SPARK_RELEASE=$SPARK_RELEASE"

        if [ "$HADOOP_VERSION" = "$LATEST_HADOOP_VERSION" ] && [ "$SPARK_VERSION" = "$LATEST_SPARK_VERSION" ]
        then
            CMD="$CMD --tag loum/spark-pseudo:latest"
        fi

        CMD="$CMD --tag loum/spark-pseudo:$HADOOP_VERSION-$SPARK_VERSION ."

        $CMD
    done
done
