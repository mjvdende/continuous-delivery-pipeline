# Continuous Delivery Pipeline 

Prerequisites

- [Vagrant](https://www.vagrantup.com/) + [VirtualBox](https://www.virtualbox.org/)

Given:

    git clone https://github.com/mjvdende/continuous-delivery-pipeline.git 
    cd continuous-delivery-pipeline

When:

    $ vagrant up

Then:

    start building!

It can take a while before services are running because docker is downloading images from the docker hub.
Therefor you can follow the progress of services booting when logging on to a core, for example core-02.

    $ vagrant ssh core-02
    $ journalctl -u jenkins.service -f

## Services Provided

### core-01

- docker.service
- docker-registry.service - URL: http://172.17.8.101:5000
- docker-registry-web.service - URL: http://172.17.8.101:8181
- gitbucket.service - URL: http://172.17.8.101:8282 (login:root-root)

### core-02

- docker.service
- jenkins.service - URL: http://172.17.8.102:8888
- xldeploy.service - URL: http://172.17.8.102:4516
- artifactory.service - URL: http://172.17.8.102:8081

### core-03

- docker.service

## Add a Service

You can add a serivce yourself to one of the ```*.user-data``` config files. 
Have a look at already defined services for examples. 

    - name: xldeploy.service
      command: start
      enable: true
      content: |
        [Unit]
        Description=XL Deploy
        After=docker.service
        Requires=docker.service

        [Service]
        TimeoutStartSec=0
        ExecStartPre=-/usr/bin/docker kill xldeploy
        ExecStartPre=-/usr/bin/docker rm xldeploy
        ExecStart=/usr/bin/docker run \
                         -p 4516:4516 \
                         --name="xldeploy" \
                         mjvdende/docker-xldeploy
        ExecStop=/usr/bin/docker stop xldeploy

To apply changes to ```*.user-data``` reload vagrant provisioning: 

    vagrant reload --provision

### Todo

- make jenkins and docker registry data persistent 
- sonar, xlrelease, xlview, tc server 

## Config 

To start our cluster, we need to provide some config parameters in cloud-config format via the ```user-data``` file and set the number of machines in the cluster in ```config.rb```.
For each core a user-data file exists. Our cluster will use an etcd discovery URL to bootstrap the cluster of machines and elect an initial etcd leader. 
Be sure to replace <token> with your own URL from https://discovery.etcd.io/new in each user-data file. More info: [coreos - vagrant](https://github.com/coreos/coreos-vagrant)

#### Shared Folder Setup

There is optional shared folder setup.
You can try it out by adding a section to your Vagrantfile like this.

```
config.vm.synced_folder ".", "/home/core/share", id: "core", :nfs => true,  :mount_options   => ['nolock,vers=3,udp']
```

