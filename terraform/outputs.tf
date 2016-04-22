output "SLURM_CTRL_IP" {
  value = "${openstack_compute_floatingip_v2.floatip_1.address}"
}
