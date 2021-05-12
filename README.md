# Overview

Automated tooling for a cloud dev environment

* Bring up a dev machine with custom installlation scripts
* SSH to the image
* Auto-Shutdown the image to save money
  * Maintain your data across shutdown and resume
* Resume your instance with restored data
* Mount a fast local SSD to /mnt/disks/ssd

# Actions

## Deploying a dev image

	./just.sh resume

./just.sh will download and run `just` if it doesn't exist. You can place `just` in your PATH and then run `just` directly.

This command may fail for you: see the Bootstrap and Configuration sections


## SSH

	just ssh

The SSH firewall is set to allow access only to your current ip address and is automatically updated when running commands.
The `resume` command will also ssh to the instance.


## Bootstrap

Assumed Dependencies:
* gcloud
* jq

Logged in via gcloud

	gcloud auth login

Store Pulumi state in GCP is resilient and works across machines.

	pulumi login gs://$(whoami)-pulumi-dev-machine-state

Initialize pulumi state. Storing in the local fs is faster

	pulumi login file://state/dev-machine-state

## Configuration

When you first run this, it will complain about missing configurations. You need to set them with

	just set KEY VALUE

To see all the configurations, run:

	just get config


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

## Auto shutdown

There is a cron job that will automatically shut down the instance if it isn't used for an hour (no processes running for your user other than idle sessions).

## Change instance type

Don't want to wait so long for Rust to compile things?

	just set gcp_machine_type n2-standard-8
	just shutdown # if you already have a machine running
	just resume

If you are using a bigger instance, try to shut things down when you are finished instead of waiting for auto-shutdown.

## Eternal Terminal support

`just ssh` will use Eternal Terminal rather than ssh if `et` is installed on your machine.

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
TODO: store in GCS


## Sudo

You can login as a user with sudo with:

	just ssh-gcloud bash -l

From there you can set the password for your normal user with:

	sudo passwd <USER>

Your normal user has sudo access.


# TODO

Auto-shutdown when not in use
