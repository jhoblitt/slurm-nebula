all: $(BIN_DIR) id_rsa id_rsa.pub munge.key

BIN_DIR=./bin
TF_VERSION=0.6.14
ZIP_FILE=terraform_$(TF_VERSION)_linux_amd64.zip

$(BIN_DIR):
	mkdir $@
	cd $@; wget -nc https://releases.hashicorp.com/terraform/$(TF_VERSION)/$(ZIP_FILE)
	cd $@; unzip $(ZIP_FILE)

id_rsa id_rsa.pub:
	ssh-keygen -t rsa -b 2048 -C slurm -N "" -f id_rsa

munge.key:
	dd if=/dev/random bs=1 count=1024 > munge.key

clean:
	rm id_rsa id_rsa.pub munge.key
