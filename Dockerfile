# образ Ubuntu LTS
FROM ubuntu:20.04

# переменные окружения
ENV HADOOP_VERSION=3.3.6
ENV HADOOP_URL=https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz
ENV HADOOP_HOME=/opt/hadoop
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# переменные для запуска Hadoop от root
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# зависимости
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget openjdk-11-jdk ssh git nano python3 python3-pip dos2unix && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install mrjob pandas matplotlib requests

#  Hadoop
RUN wget ${HADOOP_URL} && \
    tar -xzvf hadoop-${HADOOP_VERSION}.tar.gz && \
    mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} && \
    rm hadoop-${HADOOP_VERSION}.tar.gz

# hadoop-env.sh
RUN echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_HOME=/opt/hadoop' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_COMMON_HOME=${HADOOP_HOME}' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_HDFS_HOME=${HADOOP_HOME}' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_MAPRED_HOME=${HADOOP_HOME}' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh && \
    echo 'export HADOOP_YARN_HOME=${HADOOP_HOME}' >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

COPY hadoop_config/* ${HADOOP_HOME}/etc/hadoop/

RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys

WORKDIR /app
COPY vendor_contribution.py plot_results.py get_commit_data.py run_analysis.sh repos.txt /app/

RUN dos2unix /app/run_analysis.sh
RUN chmod +x /app/run_analysis.sh
CMD ["/bin/bash"]