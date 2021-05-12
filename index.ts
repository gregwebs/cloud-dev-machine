import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import { AttachedDisk } from "@pulumi/gcp/compute";

let config = new pulumi.Config();
const gcpProject = config.require("gcp_project");
const gcpEmail = config.require("gcp_email");
const gcpUser = config.require("gcp_user");
const gcpZone = config.require("gcp_zone");
const gcpMachineType = config.require("gcp_machine_type");
const myIPAddress = config.require("my_ip_address");
const gcpImage = config.require("gcp_image");

const labels = {
    environment: "dev",
    user: gcpUser,
    email: gcpEmail.replace('@', '_').replace('.', '_'),
}

/* Allow access but only from your IP address */
const machineAccess = new gcp.compute.Firewall("my-dev-ssh", {
    network: "default",
    allows: [
        {
            protocol: "tcp",
            ports: [
              "22",
	      "2022" // Eternal Terminal
	    ]
        },
        {
            protocol: "udp",
            ports: ["60001"] // mosh
        },
    ],
    targetTags: ["dev"],
    sourceRanges: [
        myIPAddress + "/32",
        "35.235.240.0/20", // IAP access (Google Console SSH)
    ],
});

/* This disk is maintained as your home directory
 * An install script needs to mount it and add your user
 */
const homeDisk = new gcp.compute.Disk("my-dev-home", {
    labels: labels,
    type: "pd-ssd",
    zone: gcpZone,
    size: 100,
});

const myInstance = new gcp.compute.Instance("my-dev-machine", {
    labels: labels,
    project: gcpProject,
    machineType: gcpMachineType,
    zone: gcpZone,
    tags: [
        "dev",
    ],
    bootDisk: {
        initializeParams: {
            image: gcpImage
        }
        /*
        source: bootDisk.id,
        autoDelete: false,
        */
    },
    attachedDisks: [{
        deviceName: "home",
        source: homeDisk.id,
    }],
    scratchDisks: [{
        "interface": "NVME",
    }],
    networkInterfaces: [{
        network: "default",
        accessConfigs: [{}],
    }],
    metadata: {
        user: gcpUser,
        email: gcpEmail,
        "enable-oslogin": 'TRUE',
    },
    /*
    metadataStartupScript: "useradd -M -s /bin/zsh -G sudo -u 1010 " + gcpUser,
    serviceAccount: {
        email: serviceAccount.email,
        scopes: ["cloud-platform"],
    }
    */
},
{
    ignoreChanges: ["attached_disk", "attached_disks"]
});

const bucket = new gcp.storage.Bucket("my-dev-bucket", {
    project: gcpProject,
    name: gcpUser + "-dev-machine",
});


/* TODO: retain the boot disk
const bootDisk = new gcp.compute.Disk("boot", {
    image: gcpImage,
    labels: labels,
    type: "pd-ssd",
    zone: gcpZone,
    size: 10,
});
*/

/* TODO: service account for the instance
const serviceAccount = new gcp.serviceaccount.Account("my-dev-bucket-access", {
    project: gcpProject,
    accountId: "my-dev-bucket-access",
    displayName: gcpUser + "dev bucket access",
});

serviceAccount.id.apply(name => {
//  const _ = new gcp.serviceaccount.IAMBinding("my-dev-iam-binding", {
//   serviceAccountId: name,
//    role: "roles/owner",
//    members: ["user:" + gcpEmail],
//  });
// })

    // role: "roles/iam.serviceAccountUser",
    // role: "roles/owner",
const devPolicy = gcp.organizations.getIAMPolicy({
    bindings: [{
        role: "roles/iam.serviceAccountUser",
        members: ["user:" + gcpEmail],
    },{
        role: "roles/owner",
        members: ["serviceAccount:" + name],
    }],
});

const _iamPolicy = new gcp.serviceaccount.IAMPolicy("my-dev-iam", {
    serviceAccountId: serviceAccount.name,
    policyData: devPolicy.then(policy => policy.policyData),
})

})
*/
