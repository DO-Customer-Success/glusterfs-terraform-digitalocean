output "You can access your GlusterFS client at this address" {
  value = "${digitalocean_droplet.client.ipv4_address}"
}

output "GlusterFS Volume Mountpoint" {
  value = "/mnt/gluster"
}

output "***Security Recommendation***" {
  value = "You can run, via SSH, the following command on any of your storage nodes to restrict access only to your client:\n \t gluster volume set volume1 auth.allow ${digitalocean_droplet.client.ipv4_address_private}\n Your primary storage node address is:\n \t ${digitalocean_droplet.primary.ipv4_address}"
}
