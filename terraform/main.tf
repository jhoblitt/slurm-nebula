provider "openstack" {
}

resource "openstack_networking_network_v2" "network_1" {
  name = "tf_test_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name = "tf_test_subnet"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr = "192.168.52.0/24"
  ip_version = 4
  dns_nameservers = ["141.142.2.2", "141.142.230.144"]
}

resource "openstack_networking_router_v2" "router_1" {
  name = "tf_test_router"
  admin_state_up = "true"
  external_gateway = "bef0fe11-1646-4826-9776-3afdf95e53b9"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

resource "openstack_compute_secgroup_v2" "secgroup_1" {
  name = "tf_test_secgroup"
  description = "my security group"

  rule {
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = 2375
    to_port = 2375
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
  rule {
    from_port = -1
    to_port = -1
    ip_protocol = "icmp"
    cidr = "${openstack_networking_subnet_v2.subnet_1.cidr}"
    #self = true
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "tcp"
    cidr = "${openstack_networking_subnet_v2.subnet_1.cidr}"
    #self = true
  }
  rule {
    from_port = 1
    to_port = 65535
    ip_protocol = "udp"
    cidr = "${openstack_networking_subnet_v2.subnet_1.cidr}"
    #self = true
  }
}

resource "openstack_compute_floatingip_v2" "floatip_1" {
  region = ""
  pool = "ext-net"
}

resource "openstack_compute_instance_v2" "test-server" {
  name = "tf-test"
  image_id = "0f1963d5-e9f3-464f-a4e4-308d83b47b76"
  flavor_id = "2a912855-769a-43ff-b4a2-e12cef4c2e9d"
  metadata {
    this = "that"
  }
  key_pair = "github"
  network {
    uuid = "${openstack_networking_network_v2.network_1.id}"
    floating_ip = "${openstack_compute_floatingip_v2.floatip_1.address}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_1.name}"]
}

