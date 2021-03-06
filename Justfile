# Bring up a dev machine
up: _pulumi-up install

get +args='':
	pulumi config get {{args}}

set +args='':
	#!/usr/bin/env bash
	set -euo pipefail
	rm -f .cache/config-*
	pulumi config set {{args}}

# Shutdown the instance to reduce costs
shutdown:
	#!/usr/bin/env bash
	set -euo pipefail
	status="$(just status)"
	set -x
	case "$status" in
	TERMINATED|SUSPENDED)
	  ;;
	*)
	  if ! ./script/ssh -- sudo bash shutdown.sh ; then
	    echo "error during shutdown, run `just terminate` to terminate the instance" >&2
	    exit 1
	  fi
	  ;;
	esac
	just terminate

terminate:
	#!/usr/bin/env bash
	set -euo pipefail
	set -x
	urn="$(pulumi stack export | jq -r '.deployment.resources[] | .urn' | grep 'instance')"
	rm -f .cache/config-*
	pulumi destroy --yes -f -t "$urn"

# Destroy the entire setup
destroy +args='':
	pulumi destroy {{args}}


# SSH to the machine or run a command on the machine
ssh +command='':
	#!/usr/bin/env bash
	set -euo pipefail
	ssh=ssh
	ETERNAL_TERMINAL=${ETERNAL_TERMINAL:-""}
	if command -v et >/dev/null && [[ -n $ETERNAL_TERMINAL ]] ; then
	  ssh=et
	fi
	machine_address="$(just _machine-address)"
	just _pulumi-config 2>/dev/null &
	set -x
	exec "$ssh" "$machine_address" {{command}}

_machine-address:
	#!/usr/bin/env bash
	set -euo pipefail
	if [[ -f .cache/config-machine-address ]] ; then
	  exec cat .cache/config-machine-address
	fi
	config="$(pulumi config)"
	zone="$(    echo "$config" | grep gcp_zone    | awk '{print $2}')"
	project="$( echo "$config" | grep gcp_project | awk '{print $2}')"
	gcp_user="$(echo "$config" | grep gcp_user | awk '{print $2}')"
	machine="$(just _machine)"
	ip_address=$(gcloud beta compute instances describe --project "$project" --zone "$zone" "$machine" | grep natIP | awk '{print $2}')
	echo "$gcp_user@$ip_address" > .cache/config-machine-address
	echo "$gcp_user@$ip_address"

# SSH with the gcloud SSH command if SSH keys are not setup
ssh-gcloud +command='':
	#!/usr/bin/env bash
	set -euo pipefail
	# Running this in the background avoids slowing things down when there is no change in the ip address
	# When the ssh command is run a second time after failure then the ip will be updated
	just _pulumi-config 2>/dev/null &
	./script/ssh {{command}}

scp +files:
	#!/usr/bin/env bash
	set -euo pipefail
	# See comment in the the ssh command
	just _pulumi-config 2>/dev/null &
	machine="$(just _machine)"
	just _scp "$machine" {{files}}

# Run install and mount scripts on the machine
install:
	#!/usr/bin/env bash
	set -euo pipefail
	machine="$(just _machine)"
	exec just _install "$machine"

# resume the instance after it is destroyed/terminated/stopped
resume: _pulumi-up
	#!/usr/bin/env bash
	set -euo pipefail
	config="$(just _fast-config)"
	project="$( echo "$config" | grep gcp_project | awk '{print $2}')"
	machine="$(just _machine)"
	status="$(just status)"
	set -x
	case "$status" in
	TERMINATED)
	  gcloud beta compute instances start --project "$project" "$machine"
	  ;;
	SUSPENDED)
	  gcloud beta compute instances resume --project "$project" "$machine"
	  ;;
	esac
	just _install "$machine"
	GCP_MACHINE="$machine" exec ./script/ssh

status:
	#!/usr/bin/env bash
	set -euo pipefail
	config="$(just _fast-config)"
	zone="$(    echo "$config" | grep gcp_zone    | awk '{print $2}')"
	project="$( echo "$config" | grep gcp_project | awk '{print $2}')"
	machine="$(just _machine)"
	gcloud beta compute instances describe --project "$project" --zone "$zone" "$machine" | grep status | awk '{print $2}'


_install machine:
	#!/usr/bin/env bash
	set -euo pipefail
	machine="{{machine}}"
	export GCP_MACHINE="$machine" 
	set -x
	if test -f ~/.ssh/id_rsa.pub ; then
	  cp ~/.ssh/id_rsa.pub install/authorized_keys
	fi
	if test -f ~/.gitconfig ; then
	  cp ~/.gitconfig install/.gitconfig
	  just _scp "$machine" install/.gitconfig
	fi
	shopt -s nullglob
	just _scp "$machine" install/*
	rm -f install/authorized_keys
	./script/ssh -- bash ./all-install.sh

_scp machine +files:
	#!/usr/bin/env bash
	set -euo pipefail
	config="$(just _fast-config)"
	zone="$(   echo "$config" | grep gcp_zone    | awk '{print $2}')"
	project="$(echo "$config" | grep gcp_project | awk '{print $2}')"
	set -x
	gcloud compute scp --project "$project" --zone "$zone" {{files}} "{{machine}}":

_pulumi-up: _pulumi-config
	#!/usr/bin/env bash
	set -euo pipefail
	pulumi up -y
	just _machine-set

_machine:
	#!/usr/bin/env bash
	set -euo pipefail
	if [[ -f .cache/config-machine ]] ; then
	  cat .cache/config-machine
	else
	  just _machine-set
	fi

_machine-set:
	#!/usr/bin/env bash
	set -euo pipefail
	rm -f .cache/config-machine
	machine="$(pulumi stack export | jq -r '.deployment.resources[] | .id' | grep 'instance' | cut -d '/' -f 6)"
	mkdir -p .cache
	echo "$machine" > .cache/config-machine
	echo "$machine"
	
_pulumi-config: _install-pulumi
	#!/usr/bin/env bash
	set -euo pipefail
	exec 3< <(curl --silent ifconfig.me 2>/dev/null)
	config="$(pulumi config)"
	if [[ -z "$(echo "$config" | grep gcp_image | awk '{print $2}')" ]] ; then
	  pulumi config set gcp_image "debian-cloud-testing/debian-11-bullseye-v20210330"
	  # pulumi config set gcp_image "debian-cloud/debian-10-buster-v20210420"
	fi
	if [[ -z "$(echo "$config" | grep gcp_user | awk '{print $2}')" ]] ; then
	  pulumi config set gcp_user "$(whoami)"
	fi
	my_ip_address=$(cat <&3)
	if [[ $my_ip_address != $(echo "$config" | grep my_ip_address | awk '{print $2}') ]] ; then
	  rm -f .cache/config-*
	  pulumi config set my_ip_address "$my_ip_address" >/dev/null
	fi


_install-pulumi:
	#!/usr/bin/env bash
	set -euo pipefail
	which pulumi >/dev/null && exit 0
	if [[ uname == Darwin ]] ; then
		brew install pulumi
	else
		curl -fsSL https://get.pulumi.com | sh
	fi

_fast-config:
	@cat Pulumi.*.yaml | cut -d ':' -f 2-3

# Alternatively provision with packer
#packer-build-machine: install-packer
#	#!/usr/bin/env bash
#	set -euo pipefail
#	gcp_project_id="$(pulumi config | grep gcp_project | awk '{print $2}')"
#	cat <<-EOF > install/install.pkr.hcl
#	source "googlecompute" "dev-build" {
#		tags = ["dev"]
#		project_id = "$gcp_project_id"
#		source_image = "debian-10-buster-v20210420"
#		ssh_username = "packer"
#		zone = "us-central1-a"
#		use_os_login = "true"
#		startup_script_file = "install/sudo-install.sh"
#	}
#
#	build {
#		provisioner "file" {
#			source = "install/user-install.sh"
#			destination = "/tmp/user-install.sh"
#		}
#		provisioner "shell" {
#			inline = [
#				"mv /tmp/user-install.sh /etc/user-install.sh",
#				"chmod +x /etc/user-install.sh"
#			]
#		}
#		sources = ["sources.googlecompute.dev-build"]
#	}
#
#	EOF
#	packer build install/install.pkr.hcl
#
#install-packer:
#	#!/usr/bin/env bash
#	set -euo pipefail
#	which packer >/dev/null && exit 0
#	if [[ uname == Darwin ]] ; then
#		brew tap hashicorp/tap
#		brew install hashicorp/tap/packer
#	else
#		curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
#		sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
#		sudo apt-get update && sudo apt-get install packer
#	fi
