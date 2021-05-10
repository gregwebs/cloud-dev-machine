# Overview

Automated tooling for a cloud dev environment

* Bring up a dev machine with custom installlation scripts
* SSH to the image
* Shutdown and resume the image to save money
  * Maintain your home directory across shutdown and resume
* Mount a fast local SSD to /mnt/disks/ssd
  * This is not maintained across shutdown and resume

# Actions

## Bootstrap

Logged in via gcloud

	gcloud auth login

Storing in GCP is resilient and works across machines.

	pulumi login gs://$(whoami)-pulumi-dev-machine-state

Initialize pulumi state. Storing in the local fs is faster

	pulumi login file://state/dev-machine-state


## Configuration

When you first run this, it will complain about missing configurations. You need to set them with

	pulumi config set KEY VALUE

To see all the configurations, run:

	pulumi config


## Deploying a dev image

	./just.sh resume

./just.sh will download and run `just` if it doesn't exist. You can place `just` in your PATH and then run `just` directly.

## SSH

	just ssh

The SSH firewall is set to allow access only to your current ip address and is automatically updated when running commands.


## Save money

Save yourself some money when you are done by running

	just shutdown

This will preserve your cloud disk.
It will copy your local SSD to the cloud disk (this may take some time).
When you are ready to work again:

    just resume

Currently the system disk is not preserved, but resume will re-run all the installer scripts.

## Save even more

If you don't need your disks, run the following to destroy all infrastructure:

	just destroy

## Change instance type

Don't want to wait so long for Rust to compile things?

	pulumi config set gcp_machine_type n2-standard-4
	just shutdown # if you already have a machine running
	just resume

Just remember to shut things down when you are finished.

## Additional commands

    just --list

# Using local SSD

The machine uses a small boot disk that for now is lost on every shutdown (the resume command will performa re-install at startup).
Your $HOME directory is a cloud disk that is saved across shutdowns so your work will persist.

Local SSD is mounted at `/mnt/disks/ssd`.
`/tmp` is a symlink to `/mnt/disks/ssd/tmp`.
So any data written to `/tmp` will get the benefit of fast local SSD.
However, this data will be lost on shutdown.
To save data, write it to a different folder in `/mnt/disks/ssd/`
For example:

	mkdir -p /mnt/disks/ssd/tikv/target
	ln -s /mnt/disks/ssd/tikv/target

`just shutdown` will run the script `shutdown.sh` which will move the data to `$HOME/ssd/save`.
`just resume` will move the data back to the ssd drive.


## Sudo

You can login as a user with sudo with:

	just ssh-gcloud bash -l

From there you can set the password for your normal user with:

	sudo passwd <USER>

Your normal user has sudo access.


# TODO

Auto-shutdown when not in use
