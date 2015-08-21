require 'fileutils'

Vagrant.require_version ">= 1.6.0"

CLOUD_CONFIG_CORE01_PATH = File.join(File.dirname(__FILE__), "core01.user-data")
CLOUD_CONFIG_CORE02_PATH = File.join(File.dirname(__FILE__), "core02.user-data")
CLOUD_CONFIG_CORE03_PATH = File.join(File.dirname(__FILE__), "core03.user-data")
CONFIG = File.join(File.dirname(__FILE__), "config.rb")

$aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
$aws_ami = "ami-aa85dbdd"
$aws_availability_zone = nil
$aws_elastic_ips = {}
$aws_instance_type = "m3.large"
$aws_keypair_name = ENV['AWS_KEYPAIR_NAME'] || "Training"
$aws_keypair_path = '~/.ssh/id_rsa'
$aws_region = "eu-west-1"
$aws_rootfs_size = 32
$aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
$aws_security_groups = ["Training"]
$aws_slave_group = nil
$aws_subnet_id = nil

# Attempt to apply the deprecated environment variable NUM_INSTANCES to
# $num_instances while allowing config.rb to override it
if ENV["NUM_INSTANCES"].to_i > 0 && ENV["NUM_INSTANCES"]
  $num_instances = ENV["NUM_INSTANCES"].to_i
end

if File.exist?(CONFIG)
  require CONFIG
end

Vagrant.configure("2") do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false

  if $image_version != "current"
      config.vm.box_version = $image_version
  end
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/%s/coreos_production_vagrant.json" % [$update_channel, $image_version]


  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  config.vm.provider :aws do |aws, override|

    aws.region_config $aws_region do |region|
      region.ebs_optimzed = true
    end

    config.vm.box = "dummy"
    config.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
    config.vm.synced_folder ".", "/vagrant", disabled: true

    aws.access_key_id = $aws_access_key_id
    aws.ami = $aws_ami
    aws.instance_type = $aws_instance_type
    aws.keypair_name = $aws_keypair_name
    aws.region = $aws_region
    aws.secret_access_key = $aws_secret_access_key
    aws.security_groups = $aws_security_groups
    aws.subnet_id = $aws_subnet_id

    # Store root filesystem on SSD and increase its size to be able to store the docker images and volumes
    #  http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_EbsBlockDevice.html
    aws.block_device_mapping = [{ 'DeviceName' => '/dev/xvda', 'Ebs.VolumeType' => 'gp2', 'Ebs.VolumeSize' => $aws_rootfs_size }]

    override.ssh.private_key_path = $aws_keypair_path
    override.ssh.insert_key = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  (1..$num_instances).each do |i|
    config.vm.define vm_name = "core-%02d" % i do |config|
      config.vm.hostname = vm_name

      if $enable_serial_logging
        logdir = File.join(File.dirname(__FILE__), "log")
        FileUtils.mkdir_p(logdir)

        serialFile = File.join(logdir, "%s-serial.txt" % vm_name)
        FileUtils.touch(serialFile)

        config.vm.provider :virtualbox do |vb, override|
          vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
          vb.customize ["modifyvm", :id, "--uartmode1", serialFile]
        end
      end

      if $expose_docker_tcp
        config.vm.network "forwarded_port", guest: 2375, host: ($expose_docker_tcp + i - 1), auto_correct: true
      end


      $forwarded_ports.each do |guest, host|
        config.vm.network "forwarded_port", guest: guest, host: host, auto_correct: true
      end

      config.vm.provider :virtualbox do |vb|
        vb.gui = $vb_gui
        vb.memory = $vb_memory
        vb.cpus = $vb_cpus
      end

      ip = "172.17.8.#{i+100}"
      config.vm.network :private_network, ip: ip

      # $shared_folders.each_with_index do |(host_folder, guest_folder), index|
      #   config.vm.synced_folder host_folder.to_s, guest_folder.to_s, id: "core-share%02d" % index, nfs: true, mount_options: ['nolock,vers=3,udp']
      # end

      if i == 1
        config.vm.provision :file, :source => "#{CLOUD_CONFIG_CORE01_PATH}", :destination => "/tmp/vagrantfile-user-data"
      elsif i == 2
        config.vm.synced_folder "jenkins-data/", "/jenkins-data", id: "core-share", nfs: true, mount_options: ['nolock,vers=3,udp']
        config.vm.provision :file, :source => "#{CLOUD_CONFIG_CORE02_PATH}", :destination => "/tmp/vagrantfile-user-data"
      else
        config.vm.provision :file, :source => "#{CLOUD_CONFIG_CORE03_PATH}", :destination => "/tmp/vagrantfile-user-data"
      end

      config.vm.provider :aws do |aws, override|
        aws.tags = {
          'Name' => vm_name,
        }
      end

      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true

    end
  end
end
