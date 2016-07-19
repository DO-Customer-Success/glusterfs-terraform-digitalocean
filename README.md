GlusterFS on DigitalOcean
=========================

Requirements & Setup
------------

Create a `terraform.tfvars` file like this one:

```bash
#This can be found on https://cloud.digitalocean.com/settings/api
digitalocean_token = ""

region = "NYC2"

size = "8GB"
#This script always creates at least two nodes; use a value higher than 0 if you wish to initialize with more than a single replica.
peer_count = "3"

#Path to your Private Key
ssh_pvt_key = "do-key"
#Path to your Public key
ssh_pub_key = "./do-key.pub"

ssh_key_fingerprint = ""
```

You can generate a keypair for use above using:

```bash
ssh-keygen -t rsa -P "" do-key
```
and get the fingerprint:

```bash
ssh-keygen -lf do-key.pub | awk '{print $2}'
```
or run it on the path to your existing public keypair.

Deploying
---------

Once your `tfvars` file or all environmental variables are ready, just run:

```bash
terraform apply
```
in your repo directory. Once completed, you'll see some additional connection data at the end:

* Your Client IP address.
* Your GlusterFS Mountpoint on your Client.
* Some additional, totally optional (but recommended) security stuff.

Environment
-----------

This script creates:

* A single pair of GlusterFS nodes (2 droplets); you can set the `peer_count` variable to add any additional servers to the cluster
* A single storage volume for the cluster
* A single client server where it is mounted

You can verify the cluster is up and running using:

```bash
gluster volume info
```
and

```bash
gluster peer status
```

Your data, on the client, will be accessible to the volume mounted on `/mnt/gluster`

It is recommended that, after you've confirmed you can access the client and it can access the cluster, that you run, on any of the storage nodes (not the client):

```bash
gluster volume set volume1 auth.allow <CLIENT DROPLET IP ADDRESS>
```
You can also allow any other public IP addresses you would like to add to the access list.
