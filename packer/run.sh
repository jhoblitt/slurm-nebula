#!/bin/bash

bundle install
bundle exec librarian-puppet install

#./bin/packer build -var source_image=0f1963d5-e9f3-464f-a4e4-308d83b47b76 slurm.json
