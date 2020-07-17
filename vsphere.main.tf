

provider "vsphere" {
  user           = "administrator@osauer.local"
  password       = "XXX"
  vsphere_server = "192.168.1.45"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "PKS-DC"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = "MGMT/Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "ms_t1_int"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network2" {
  name          = "isolated_net"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "ubuntu1604"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }
  network_interface {
    network_id = "${data.vsphere_network.network2.id}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = false
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    customize {
      linux_options {
        host_name = "terraform-test"
        domain    = "test.internal"
      }
      network_interface {
        ipv4_address = "10.4.1.10"
        ipv4_netmask = 24
      }
      network_interface {
        ipv4_address = "10.2.1.10"
        ipv4_netmask = 24
      }


      ipv4_gateway = "10.4.1.1"
    }
  }
  cdrom {
    client_device = true
  }
  connection {
    type     = "ssh"
    host     = "192.168.1.222"
    user     = "ubuntu"
    password = "sauer1357"
    port     = "22"
    agent    = false
  }
}


resource "vsphere_virtual_machine" "vm2" {
  name             = "terraform-test2"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"

  num_cpus = 2
  memory   = 1024
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"


  network_interface {
    network_id = "${data.vsphere_network.network2.id}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks.0.size}"
    thin_provisioned = false
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"
    customize {
      linux_options {
        host_name = "terraform-test"
        domain    = "test.internal"
      }
      network_interface {
        ipv4_address = "10.2.1.20"
        ipv4_netmask = 24
      }

      ipv4_gateway = "10.2.1.1"
    }
  }
  cdrom {
    client_device = true
  }

  connection {
    type     = "ssh"
    host     = "10.2.1.20"
    user     = "ubuntu"
    password = "sauer1357"
    port     = "22"
    agent    = false
  }
}
