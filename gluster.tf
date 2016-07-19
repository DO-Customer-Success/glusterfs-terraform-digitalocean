variable "region" {}
variable "size" {}
variable "ssh_key_fingerprint" {}
variable "ssh_pub_key" {
  description = "Path to public key file"
}
variable "ssh_pvt_key" {
  description = "Path to private key file"
}
variable "digitalocean_token" {}
variable "peer_count" {
  description = "Number of peer nodes (in addition to the two primary nodes created)"
}

provider "digitalocean" {
  token = "${var.digitalocean_token}"
}

resource "digitalocean_droplet" "primary" {
  name = "gluster-01"

  image = "ubuntu-14-04-x64"
  size             = "${var.size}"
    ssh_keys = ["${var.ssh_key_fingerprint}"]
  connection {
    user = "root"
    private_key = "${var.ssh_pvt_key}"
  }
  private_networking = true
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.ssh_pub_key}")}\"\n"
  region      = "${var.region}"

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address_private}\" ${self.name} >> hosts.txt"
  }

  provisioner "remote-exec" {
  inline = [
    "apt-get update",
    "apt-get install glusterfs-server -y",
    "mkdir /storage"
    ]
  }
}

resource "digitalocean_droplet" "peer" {
  name = "${format("gluster-peer-%02d", count.index)}"
  count         = "${var.peer_count}"
  image = "ubuntu-14-04-x64"
  size             = "${var.size}"
  depends_on = ["digitalocean_droplet.primary"]
  ssh_keys = ["${var.ssh_key_fingerprint}"]
  connection {
    user = "root"
    private_key = "${var.ssh_pvt_key}"
  }
  private_networking = true
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.ssh_pub_key}")}\"\n"
  region      = "${var.region}"

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address_private}\" ${self.name} >> hosts.txt"
  }

  provisioner "remote-exec" {
  inline = [
    "apt-get update",
    "apt-get install glusterfs-server -y",
    "mkdir /storage"
    ]
  }
}

resource "digitalocean_droplet" "peer-prober" {
  name = "gluster-02"
  image = "ubuntu-14-04-x64"
  size             = "${var.size}"
  depends_on = ["digitalocean_droplet.peer"]
  ssh_keys = ["${var.ssh_key_fingerprint}"]
  connection {
    user = "root"
    private_key = "${var.ssh_pvt_key}"
  }
  private_networking = true
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.ssh_pub_key}")}\"\n"
  region      = "${var.region}"

  provisioner "local-exec" {
    command = "echo \"${self.ipv4_address_private}\" ${self.name} >> hosts.txt"
  }

  provisioner "file" {
    source = "./hosts.txt"
    destination = "/tmp/hosts.txt"
  }

  provisioner "local-exec" {
    command = "rm hosts.txt"
  }

  provisioner "remote-exec" {
  inline = [
    "apt-get update",
    "apt-get install glusterfs-server -y",
    "mkdir /storage",
    "for host in `cat /tmp/hosts.txt | awk '{print $1}' | grep -v ${self.ipv4_address_private}`; do gluster peer probe $host; done",
    "echo `cat /tmp/hosts.txt` >> /etc/hosts",
    "export GLUSTER_COUNT = `cat /tmp/hosts.txt | wc -l`",
    "for host in `cat /tmp/hosts.txt | awk '{print $1}'`; do export GLUSTER_HOSTS=\"$GLUSTER_HOSTS $host:/storage \"; done",
    "gluster volume create volume1 replica $GLUSTER_COUNT transport tcp $GLUSTER_HOSTS force",
    "gluster volume start volume1"
    ]
  }
}

resource "digitalocean_droplet" "client" {
  name = "gluster-client"
  image = "ubuntu-14-04-x64"
  size  = "${var.size}"
  depends_on = ["digitalocean_droplet.peer-prober"]
  ssh_keys = ["${var.ssh_key_fingerprint}"]
  connection {
    user = "root"
    private_key = "${var.ssh_pvt_key}"
  }
  private_networking = true
  user_data     = "#cloud-config\n\nssh_authorized_keys:\n  - \"${file("${var.ssh_pub_key}")}\"\n"
  region      = "${var.region}"

  provisioner "file" {
    source = "./hosts.txt"
    destination = "/tmp/hosts.txt"
  }

  provisioner "local-exec" {
    command = "rm hosts.txt"
  }

  provisioner "remote-exec" {
  inline = [
    "apt-get update",
    "apt-get install glusterfs-client -y",
    "mkdir /mnt/gluster",
    "mount -t glusterfs ${digitalocean_droplet.primary.ipv4_address_private}:/storage /mnt/gluster"
    ]
  }
}
