#!/bin/sh

nohup sh -c /hadoop-bootstrap.sh &

# Pause until Hadoop bootstrap completes.
counter=0
sleep_time=5
break_out=19
file_to_check="/tmp/hadoop-hdfs-nodemanager.pid"
while : ; do
    if [ -f "$file_to_check" -o $counter -gt $break_out ]
    then
        if [ -f "$file_to_check" ]
        then
            echo "### Hadoop bootstrap complete"
        else
            echo "### ERROR: Hadoop boostrap timeout"
        fi
        break
    else
        echo "$0 pausing until $file_to_check exists."
        sleep $sleep_time
        counter=$((counter+$sleep_time))
    fi
done

# Start Spark HistoryServer.
#
# Create shared "spark.eventLog.dir"/"spark.history.fs.logDirectory" directories in HDFS.
HADOOP_HOME=/opt/hadoop
loop_counter=0
max_loops=60
sleep_period=2
until [ $loop_counter -ge $max_loops ]
do
    $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp 2>/dev/null && break
    loop_counter=$((loop_counter+1))
    sleep $sleep_period
done

# Copy over the Spark JARs to HDFS.
$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark
$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark/yarn
$HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark/yarn/archive
$HADOOP_HOME/bin/hdfs dfs -copyFromLocal /opt/spark/jars/* /tmp/spark/yarn/archive/

if [ $loop_counter -lt $max_loops ]
then
    $HADOOP_HOME/bin/hdfs dfs -mkdir /tmp/spark-events
    /opt/spark/sbin/start-history-server.sh
else
    echo "ERROR: Spark HistoryServer did not start"
fi

# Start the Spark pseudo-distributed cluster
/opt/spark/sbin/start-all.sh

# Block until we signal exit.
trap 'exit 0' TERM
while true; do sleep 0.5; done
