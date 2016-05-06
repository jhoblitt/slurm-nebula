Slurm on Nebula
===

Trivial end-user instructions
---

* setup OpenStack/Nebula env vars
* clone this repo
* run the terraform makefile to install tf locally
* invoke terraform
* ssh into slurm ctrl/bastion node

```sh
. LSST-openrc.sh
git clone https://github.com/jhoblitt/slurm-nebula
cd slurm-nebula/terraform
make
./bin/terraform apply

<lots of output>
```

Wait for output similar to:

```sh
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

  SLURM_CTRL_IP = 141.142.211.82
```

    ssh -i id_rsa -l vagrant 141.142.211.82

`id_rsa` should have been created by `make`.

__Note that ssh may fail (`Permission denied (publickey).`) initially as
terraform may return before the boot/init process is completed on the
ctrl/bastion node.__

If you want to ssh into any of the slave nodes, you'll ned to do something like

    ssh-add id_rsa
    ssh -A -l vagrant 141.142.211.82

Cleanup
---

**This will destroy all data**

    ./bin/terraform destroy --force

Known problms
---

* https://github.com/hashicorp/terraform/issues/6317

XXX Document Me
---

* basic architecture of what is bein deployed
* munge configuration
* slurm package creation / configuration
* how to create the s3 hosted yum repo for slurm packages
* how to rebuild the node image with packer
* how to pass options to terraform
* all of the TODO/XXX code comments items
