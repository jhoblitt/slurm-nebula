output "NETWORK_ID" {
  value = "${openstack_networking_network_v2.network_1.id}"
}

output "SECURITY_GROUP_ID_INTERNAL" {
  value = "${openstack_compute_secgroup_v2.secgroup_1.id}"
}
