provider "openstack" {
}

resource "openstack_networking_network_v2" "network_1" {
  name = "slurm_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name = "slurm_subnet"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr = "192.168.52.0/24"
  gateway_ip = "192.168.52.1"
  ip_version = 4
  dns_nameservers = ["141.142.2.2", "141.142.230.144"]
}

resource "openstack_networking_router_v2" "router_1" {
  name = "slurm_router"
  admin_state_up = "true"
  external_gateway = "bef0fe11-1646-4826-9776-3afdf95e53b9"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

resource "openstack_compute_secgroup_v2" "bastion" {
  name = "slurm_bastion"
  description = "slurm ctrl/bastion"

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
}

resource "openstack_compute_secgroup_v2" "internal" {
  name = "slurm_internal"
  description = "slurm internal traffic"

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

# XXX convert node resources to templates
resource "openstack_compute_instance_v2" "ctrl" {
  name = "slurm-ctrl"
  flavor_id = "${var.flavor_id}"
  user_data = <<EOT
  #cloud-config
  write_files:
    - path: /etc/munge/munge.key
      owner: munge:munge
      permissions: '0600'
      encoding: b64
      content: "${base64encode(file("munge.key"))}"
    - path: /etc/slurm/slurm.conf
      owner: root:root
      permissions: '0644'
      encoding: b64
      content: "${base64encode(file("slurm.conf"))}"
  EOT
  depends_on = [ "null_resource.munge-key" ]

  metadata {
    slurm_node_type = "ctrl"
  }
  key_pair = "github"
  network {
    uuid = "${openstack_networking_network_v2.network_1.id}"
    floating_ip = "${openstack_compute_floatingip_v2.floatip_1.address}"
    fixed_ip_v4 = "192.168.52.10"
  }
  security_groups = [
      "${openstack_compute_secgroup_v2.bastion.name}",
      "${openstack_compute_secgroup_v2.internal.name}"
  ]
  block_device {
    uuid = "${var.image_id}"
    source_type = "image"
    volume_size = "${var.scratch_size}"
    destination_type = "volume"
    delete_on_termination = true
  }
  /*
  provisioner "remote-exec" {
    inline = [
      "sudo sh -c 'echo ${openstack_compute_instance_v2.test-ctrl.access_ip_v4} tf-ctrl >> /etc/hosts'"
    ]
    connection {
      type = "ssh"
      user = "vagrant"
      private_key = "${file("~/.ssh/id_rsa_github")}"
    }
  }
  */
}

resource "openstack_compute_instance_v2" "slave" {
  count = "${var.num_slaves}"
  # index hostnames from 1
  name = "slurm-slave${count.index + 1}"
  image_id = "${var.image_id}"
  flavor_id = "${var.flavor_id}"
  user_data = <<EOT
  #cloud-config
  write_files:
    - path: /etc/munge/munge.key
      owner: munge:munge
      permissions: '0600'
      encoding: b64
      content: "${base64encode(file("munge.key"))}"
    - path: /etc/slurm/slurm.conf
      owner: root:root
      permissions: '0644'
      encoding: b64
      content: "${base64encode(file("slurm.conf"))}"
  EOT
  depends_on = [ "null_resource.munge-key" ]

  metadata {
    slurm_node_type = "slave"
  }
  key_pair = "github"
  network {
    uuid = "${openstack_networking_network_v2.network_1.id}"
    fixed_ip_v4 = "192.168.52.${count.index + 10 + 1}"
  }
  security_groups = ["${openstack_compute_secgroup_v2.internal.name}"]
  /*
  provisioner "remote-exec" {
    inline = [
      "sudo sh -c 'echo ${openstack_compute_instance_v2.test-ctrl.access_ip_v4} tf-ctrl >> /etc/hosts'"
    ]
    connection {
      type = "ssh"
      user = "vagrant"
      bastion_host = "${openstack_compute_instance_v2.test-ctrl.name}"
      host = "${self.access_ip_v4}"
      private_key = "${file("~/.ssh/id_rsa_github")}"
    }
  }
  */
}

resource "null_resource" "munge-key" {
  provisioner "local-exec" {
    command = "dd if=/dev/random bs=1 count=1024 > munge.key"
  }
}
