# Installation of MicSE

## Table of Contents

- [Installation of MicSE](#installation-of-micse)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
    - [I. Using Vagrant Box](#i-using-vagrant-box)
      - [I.1. Clone and build environment](#i1-clone-and-build-environment)
      - [I.2. Connect ssh to vm](#i2-connect-ssh-to-vm)
      - [I.3. Vagrant management commands](#i3-vagrant-management-commands)
      - [I.i. Prerequisite](#ii-prerequisite)
      - [I.ii. Customize Virtual Machine](#iii-customize-virtual-machine)
    - [II. Using Docker Image (TBA)](#ii-using-docker-image-tba)
    - [III. Direct Installation with Installation Script](#iii-direct-installation-with-installation-script)
    - [IV. Direct Installation from Source](#iv-direct-installation-from-source)
      - [IV.1. Clone, Build](#iv1-clone-build)
      - [IV.i. Prerequisite](#ivi-prerequisite)
      - [IV.ii. Ocaml Package dependencies](#ivii-ocaml-package-dependencies)

## Installation

MicSE can be installed in four ways:

I. [Using vagrant box](#i-using-vagrant-box)
II. Using docker image (TBA)
III. [Direct installation with installation script](#iii-direct-installation-with-installation-script)
IV. [Direct installation from source](#iv-direct-installation-from-source)

### I. Using Vagrant Box

MicSE provides a Vagrant Box. This box is based on Ubuntu 20.04 LTS (Focal Fossa) v20210304.0.0. And, provider of this box is only VirtualBox now. So you can install [Vagrant](https://www.vagrantup.com/) and [Virtual Box](https://www.virtualbox.org/) for convenience, and build environment in VirtualBox.

#### I.1. Clone and build environment

```bash
$ git clone https://github.com/kupl/MicSE-Public
$ cd MicSE-Public
$ vagrant up
Bringing machine 'micse' up with 'virtualbox' provider...
...
```

If bootstrapping is done well, MicSE may be installed well in vm.

#### I.2. Connect ssh to vm

```bash
$ vagrant ssh

# (optional) You can check whether core executable files are installed well
$ which baseline micse taq
```

#### I.3. Vagrant management commands

If you stop or remove vm, please refer to the following commands.

```bash
# Create or load virtual machine with Vagrant box
$ vagrant up
Bringing machine 'micse' up with 'virtualbox' provider...
...

# Connect to the machine
$ vagrant ssh
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-66-generic x86_64)
... # Project directory is mounted to `~/MicSE` directory

# Halt the machine after exit the connection
$ vagrant halt
==> micse: Attempting graceful shutdown of VM...
...

# Destroy and delete the machine
$ vagrant destroy
    micse: Are you sure you want to destroy the 'micse' VM? [y/N] y
==> micse: Destroying VM and associated drives...
...
```

If you don't need bootstrapping when you run the machine, load machine with option `--no-provision`.

```bash
# Create or load virtual machine without bootstrapping
$ vagrant up --no-provision
```

#### I.i. Prerequisite

- [Vagrant](https://www.vagrantup.com/docs/installation)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

#### I.ii. Customize Virtual Machine

If you want to customize virtual machine (e.g., size of disk, memory, number of cores, ...) depending on your system spec,
you can modify following parts of [`Vagrantfile`](../Vagrantfile) for such purpose.

```ruby
...
# Default Disk Size: 40GB
config.disksize.size = "40GB"

# Provider settings: VirtualBox
config.vm.provider "virtualbox" do |vb|
  ...
  # Default Memory Size: 100GB
  vb.memory = 102400
  # Default Cores: 10
  vb.cpus = 10
end
...
```

### II. Using Docker Image (TBA)

### III. Direct Installation with Installation Script

To install the MicSE directly:

```bash
wget -O - https://raw.githubusercontent.com/kupl/MicSE-Public/main/bootstrap.sh | bash
```

### IV. Direct Installation from Source

#### IV.1. Clone, Build

We are not providing the version build file now.
To use the tool of MicSE, you have to clone this repository and build it manually.

```bash
$ git clone https://github.com/kupl/MicSE-Public.git
$ cd MicSE-Public
# Assuming that ocaml, opam are installed
$ opam install -y -q ./ --deps-only
$ make
dune build
...
```

#### IV.i. Prerequisite

- cmake: `^3.22.1`
- build-essential: `^12.9`
- python2.7: `^2.7.18`
- libgmp-dev: `^6.2.1`
- opam: `^2.1.2`
- ocaml-findlib: `^1.9.1`
- nodejs: `^12.22.9`

#### IV.ii. Ocaml Package dependencies

MicSE uses these packages.

| System Package Name | Version |
| :------------------ | :-----: |
| make                | ^4.2.1  |
| ocaml               | =4.10.0 |
| opam                | ^2.0.5  |

| Opam Package Name |  Version  |
| :---------------- | :-------: |
| Batteries         |  =3.3.0   |
| Core              |  =0.14.1  |
| Dune              |  =2.4.0   |
| Menhir            | =20210419 |
| Ocamlgraph        |  =2.0.0   |
| Ptime             |  =0.8.5   |
| Yojson            |  =1.7.0   |
| Z3                |  =4.8.13  |
| Zarith            |   =1.11   |
| OUnit2            |  =2.2.4   |
| BigNum            | =v0.14.0  |
| ppx_deriving      |  =5.2.1   |
| Mtime             |  =1.2.0   |
| Logs              |  =0.7.0   |
