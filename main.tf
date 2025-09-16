terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">=2.3.1" #Latest version supports 4.1 APIs
    }
  }
}

provider "nutanix" {
  username = var.prism_central_username
  password = var.prism_central_password
  endpoint = var.prism_central_endpoint
  insecure = true
}

# Fetch all clusters from Prism Central
data "nutanix_clusters_v2" "clusters" {}

# Get the ID of the first cluster that is not a Prism Central cluster
locals {
  cluster_ext_id = [
    for cluster in data.nutanix_clusters_v2.clusters.cluster_entities :
    cluster.ext_id if cluster.config[0].cluster_function[0] != "PRISM_CENTRAL" # Exclude Prism Central cluster
  ][0]                                                                         # Select the first available cluster
}

# pull image data
data "nutanix_images_v2" "vm-image" {
  filter = "name eq '${var.image_name}'"
  limit  = 1
}

# Setup user numbers and VM name prefix
locals {
  user_numbers = [for i in range(var.user_number, var.user_number + var.number_of_users) : i]
}

# Create a category for tagging VMs
resource "nutanix_category_v2" "backupTag" {
  key   = "Shared Move VMs"
  value = "Local Backups"
}

data "nutanix_subnets_v2" "vm_subnet" {
  filter = "name eq '${var.subnet_name}'"
  limit  = 1
}

# Create user VMs, both tagged and untagged, using image pulled above
resource "nutanix_virtual_machine_v2" "user_vms" {
  for_each = {
    for pair in flatten([
      for user in local.user_numbers : [
        { key = "${user}_tagged", value = { user = user, tagged = true } },
        { key = "${user}_untagged", value = { user = user, tagged = false } }
      ]
    ]) : pair.key => pair.value
  }
  name = "${var.user_vm_name_prefix}${format("%0${var.number_of_users >= 100 ? 3 : 2}d", each.value.user)}${each.value.tagged ? "_Tagged" : ""}"
  cluster {
    ext_id = local.cluster_ext_id
  }
  num_cores_per_socket = 2
  num_sockets          = 1
  memory_size_bytes    = 4 * 1024 * 1024 * 1024
  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_images_v2.vm-image.images[0].ext_id
            }
          }
        }
      }
    }
  }
  nics {
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = data.nutanix_subnets_v2.vm_subnet.subnets[0].ext_id
      }
      vlan_mode = "ACCESS"
    }
  }
  power_state = "ON"
  dynamic "categories" {
    for_each = each.value.tagged ? [resource.nutanix_category_v2.backupTag.id] : []
    content {
      ext_id = categories.value
    }
  }
  guest_customization {
    config {
      cloud_init {
        cloud_init_script {
          user_data {
            value = base64encode(<<-EOT
              #cloud-config
              chpasswd:
                list: |
                  rocky:${var.prism_central_password}
                expire: false
              runcmd:
                - hostnamectl set-hostname ${var.user_vm_name_prefix}${format("%0${var.number_of_users >= 100 ? 3 : 2}d", each.value.user)}${each.value.tagged ? "_Tagged" : ""}
              EOT
            )
          }
        }
      }
    }
  }
}