FROM ubuntu:latest

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF

RUN echo "deb http://repos.mesosphere.io/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mesosphere.list

RUN sudo apt-get -y update

RUN apt-get -y install mesosphere

RUN echo "zk://localhost:2181/mesos" > /etc/mesos/zk
RUN echo "42" > /etc/zookeeper/conf/myid 
RUN echo "server.42=localhost:2888:3888" >> /etc/zookeeper/conf/zoo.cfg
RUN echo "1" > /etc/mesos-master/quorum
RUN echo "172.17.8.101" > /etc/mesos-master/ip
RUN echo "localhost" > /etc/mesos-master/hostname
RUN echo "localhost" > /etc/marathon/conf
RUN echo "zk://localhost:2181/mesos" > /etc/marathon/conf/master
RUN echo "zk://localhost:2181/marathon" > /etc/marathon/conf/zk

RUN sudo stop mesos-slave
RUN echo manual | sudo tee /etc/init/mesos-slave.override

RUN sudo restart zookeeper
RUN sudo start mesos-master
RUN sudo start marathon