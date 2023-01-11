# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # OS version: Ubuntu 20.04 LTS (Focal Fossa) v20210720.0.1
  config.vm.box = "ubuntu/focal64"
  config.vm.box_version = "20210720.0.1"

  # Provider settings: VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.name = "MicSE"
    #vb.memory = 102400
    vb.memory = 4096
    vb.cpus = 4
  end

  # Etc
  config.vm.hostname = "kupl"

  # Provisioning
  config.vm.provision "bootstrap", type: "shell",
      privileged: false, run: "always" do |bs|
    bs.path = "bootstrap.sh"
  end
end
