##################################### Variable definition Core Build Params #####################################
#################################################################################################################


variable "tenancy_id" {
  description = "The OCID of your tenancy."
  type        = string
}

variable "tenancy_name" {
  description = "The OCID of your tenancy."
  type        = string
}

variable "region" {
  description = "OCI region."
  type        = string
}

variable "compartment_id" {
  description = "The OCID of the compartment."
  type        = string
}

variable "instance_fault_domain" {
  description = "The fault domain of the instance."
  type        = string
}

variable "availability_domain" {
  description = "The avaibility domain of the instance."
  type        = string
}

variable "display_name" {
  description = "The display name of the instance."
  type        = string
  default     = ""
}

variable "hostname_label" {
  description = "The host name of the instance."
  type        = string
  default     = ""
}

#################################################################################################################
#################################################################################################################


################################# Variable definition of Shape/ Shape CONFIG ####################################
#################################################################################################################


variable "shape" {
  description = "The shape of the instance."
  type        = string
}

variable "shape_config-baseline_ocpu_utilization" {
  description = "OCPU utilization for a subcore burstable VM instance. Leave this attribute blank for a non-burstable instance"
  type        = string
  default     = ""
}

variable "shape_config-memory_in_gbs" {
  description = "Total amount of memory available to the instance, in gigabytes"
  # type        = string
  type        = number
  default     = 16
}

variable "shape_config-nvmes" {
  description = "Number of NVMe drives to be used for storage."
  # type        = string
  type        = number
  default     = null
}

variable "shape_config-ocpus" {
  description = "Total number of OCPUs available to the instance."
  # type        = string
  type        = number
  default     = 2
}

variable "shape_config-vcpus" {
  description = "The total number of VCPUs available to the instance. This can be used instead of OCPUs, in which case the actual number of OCPUs will be calculated based on this value and the actual hardware. This must be a multiple of 2."
  # type        = string
  type        = number
  default     = null
}

variable "source_id" {
  description = "The OCID of the image or boot volume to use as the source for the instance."
  type        = string
}

variable "source_type" {
  description = "The type of source for the instance. It can be either 'image' or 'bootVolume'."
  type        = string
  default     = "Image"
}

#################################################################################################################
#################################################################################################################



################################# Variable definition of attached VNIC ##########################################
#################################################################################################################


variable "create_vnic_details-subnet_id" {
  description = "The OCID of the subnet."
  type        = string
  default     = null
}

# variable "create_vnic_details-hostname_label" {
#   description = "The hostname label for the VNIC. Use the same value as in field HostName Label."
#   type        = string
#   default     = null
# }

variable "create_vnic_details-assign_public_ip" {
  description = "Assign a public IP address."
  type        = bool
  default     = false
}

variable "create_vnic_details-nsg_ids" {
  description = "List of Network Security Group OCIDs."
  type        = list(string)
  default     = []
}

variable "create_vnic_details-private_ip" {
  description = "Use existing Private IP address."
  type        = string
  default     = null
}

variable "create_vnic_details-assign_private_dns_record" {
  description = "Assign a private DNS record."
  type        = bool
  default     = null
}

#################################################################################################################
#################################################################################################################



################################## Variable definition of instance_agent_config #################################
#################################################################################################################


variable "instance_agent_config-are_all_plugins_disabled" {
  description = "Are all plugins disabled. Recommended to keep it unchecked"
  type        = bool
  default     = false
}

variable "instance_agent_config-is_management_disabled" {
  description = "Is management disabled. Recommended to keep it unchecked"
  type        = bool
  default     = false
}

variable "instance_agent_config-is_monitoring_disabled" {
  description = "Is monitoring disabled. Recommended to keep it unchecked"
  type        = bool
  default     = false
}


variable "instance_agent_config-plugin_config_1-set_value" {
  description = "Use this flag to selectively disable  configs for plugin 1"
  type        = bool
}

variable "instance_agent_config-plugin_config_1-desired_state" {
  description = "Desired state of the agent."
  type        = string
  default     = "ENABLED"
}

variable "instance_agent_config-plugin_config_1-name" {
  description = "Name of the agent."
  type        = string
  default     = "Management Agent"
}


variable "instance_agent_config-plugin_config_2-set_value" {
  description = "Use this flag to selectively disable  configs for plugin 2"
  type        = bool
}

variable "instance_agent_config-plugin_config_2-desired_state" {
  description = "Desired state of the agent."
  type        = string
  default     = "ENABLED"
}

variable "instance_agent_config-plugin_config_2-name" {
  description = "Name of the agent."
  type        = string
  default     = "Block Volume Management"
}


variable "instance_agent_config-plugin_config_3-set_value" {
  description = "Use this flag to selectively disable  configs for plugin 3"
  type        = bool
}

variable "instance_agent_config-plugin_config_3-desired_state" {
  description = "Desired state of the agent."
  type        = string
  default     = "ENABLED"
}

variable "instance_agent_config-plugin_config_3-name" {
  description = "Name of the agent."
  type        = string
  default     = "Vulnerability Scanning"
}


variable "instance_agent_config-plugin_config_4-set_value" {
  description = "Use this flag to selectively disable  configs for plugin 4"
  type        = bool
}

variable "instance_agent_config-plugin_config_4-desired_state" {
  description = "Desired state of the agent."
  type        = string
  default     = "ENABLED"
}

variable "instance_agent_config-plugin_config_4-name" {
  description = "Name of the agent."
  type        = string
  default     = "Custom Logs Monitoring"
}


variable "instance_agent_config-plugin_config_5-set_value" {
  description = "Use this flag to selectively disable  configs for plugin 5"
  type        = bool
}

variable "instance_agent_config-plugin_config_5-desired_state" {
  description = "Desired state of the agent."
  type        = string
  default     = "DISABLED"
}

variable "instance_agent_config-plugin_config_5-name" {
  description = "Name of the agent."
  type        = string
  default     = "Cloud Guard Workload Protection"
}


#################################################################################################################
#################################################################################################################



#################################################################################################################
# Variable definition of block_volume 
#################################################################################################################

variable "boot_volume_backup_policy_id" {
  description = "Backup Policy of Boot volume"
  type        = string
}

variable "boot_volume_size_in_gbs" {
  description = "The size of the boot volume in GBs."
  type        = number
  default     = 50
}

variable "block_volume_backup_policy_id" {
  description = "Backup Policy of Block volume"
  type        = string
}

# Block Volume 1
variable "attach_block_volume_1" {
  description = "Flag to indicate whether Block Volume 1 should be attached."
  type        = bool
  default     = true
}

variable "block_volume_1-volume_size_in_gbs" {
  description = "Block volume 1 size in GBs."
  type        = number
  default     = 50
}

variable "block_volume_1-block_volume_name" {
  description = "Name of block volume 1."
  type        = string
  default     = "bv1"
}

variable "block_volume_1-block_volume_attachment_type" {
  description = "Attachment type of block volume 1."
  type        = string
  default     = "ISCSI"
}

# Block Volume 1 - Partition 1
variable "block_volume_1-block_volume_partition_1-block_volume_partition_size" {
  description = "Partition 1 size in GBs for block volume 1."
  type        = number
  default     = null
}

variable "block_volume_1-block_volume_partition_1-block_volume_filesystem_type" {
  description = "Filesystem type for partition 1 of block volume 1."
  type        = string
  default     = null
}

variable "block_volume_1-block_volume_partition_1-block_volume_mount_point" {
  description = "Mount point for partition 1 of block volume 1."
  type        = string
  default     = null
}

# Block Volume 1 - Partition 2
variable "block_volume_1-block_volume_partition_2-block_volume_partition_size" {
  description = "Partition 2 size in GBs for block volume 1."
  type        = number
  default     = null
}

variable "block_volume_1-block_volume_partition_2-block_volume_filesystem_type" {
  description = "Filesystem type for partition 2 of block volume 1."
  type        = string
  default     = null
}

variable "block_volume_1-block_volume_partition_2-block_volume_mount_point" {
  description = "Mount point for partition 2 of block volume 1."
  type        = string
  default     = null
}

# Block Volume 2
variable "attach_block_volume_2" {
  description = "Flag to indicate whether Block Volume 2 should be attached."
  type        = bool
  default     = true
}

variable "block_volume_2-volume_size_in_gbs" {
  description = "Block volume 2 size in GBs."
  type        = number
  default     = 50
}

variable "block_volume_2-block_volume_name" {
  description = "Name of block volume 2."
  type        = string
  default     = "bv2"
}

variable "block_volume_2-block_volume_attachment_type" {
  description = "Attachment type of block volume 2."
  type        = string
  default     = "ISCSI"
}

# Block Volume 2 - Partition 1
variable "block_volume_2-block_volume_partition_1-block_volume_partition_size" {
  description = "Partition 1 size in GBs for block volume 2."
  type        = number
  default     = null
}

variable "block_volume_2-block_volume_partition_1-block_volume_filesystem_type" {
  description = "Filesystem type for partition 1 of block volume 2."
  type        = string
  default     = null
}

variable "block_volume_2-block_volume_partition_1-block_volume_mount_point" {
  description = "Mount point for partition 1 of block volume 2."
  type        = string
  default     = null
}

# Block Volume 2 - Partition 2
variable "block_volume_2-block_volume_partition_2-block_volume_partition_size" {
  description = "Partition 2 size in GBs for block volume 2."
  type        = number
  default     = null
}

variable "block_volume_2-block_volume_partition_2-block_volume_filesystem_type" {
  description = "Filesystem type for partition 2 of block volume 2."
  type        = string
  default     = null
}

variable "block_volume_2-block_volume_partition_2-block_volume_mount_point" {
  description = "Mount point for partition 2 of block volume 2."
  type        = string
  default     = null
}

#################################################################################################################
#################################################################################################################



########################################### SSH Breakglass Key Vault Section ######################################
###################################################################################################################
# variable "credentials" {
#   description = "The SSH authorized keys for the instance."
#   type = object({
#     ssh_authorized_keys = string
#   })
# }

variable "vault_compartment_id" {
  description = "The OCID of the compartment of vault."
  type        = string
}

variable "vault_id" {
  description = "The OCID of the vault"
  type        = string
  default     = "ocid1.vault.oc1.iad.bbpk6uf4aaeug.abuwcljs6mfiakmolewxr2que7i2alqsyawk3odftegfrbmgh6ymjsfec3za"
}

variable "key_id" {
  description = "The OCID of the key to use for encryption"
  type        = string
  default     = "ocid1.key.oc1.iad.bbpk6uf4aaeug.abuwcljrbumqpj5w2sai7z4pntqr2hbciv3447qltzvafcgof6c2ns47ttwa"
}

#################################################################################################################
#################################################################################################################



######################################### Variable definition of CIS Benchmark ####################################
###################################################################################################################
## CIS Benchmark Variables
variable "are_legacy_imds_endpoints_disabled" {
  description = "Whether to disable the legacy (/v1) instance metadata service endpoints."
  type        = bool
  default     = false
}

variable "is_pv_encryption_in_transit_enabled" {
  description = "Whether to disable the legacy (/v1) instance metadata service endpoints."
  type        = bool
  default     = true
}

variable "network_type" {
  description = "Emulation type for the physical network interface card "
  default     = "PARAVIRTUALIZED"
}

#################################################################################################################
#################################################################################################################



##################################### Variable definition as per Tag Namespace ####################################
###################################################################################################################


variable "defined_tag_namespace" {
  description = "The tag namespace used in the this tenancy for AMDS tagging e.g. Applications"
  default     = "Applications"
}

variable "defined_tags-AppID" {
  description = "Application ID as per Inventory Database or Application Catalogue"
  type        = string
  default     = null
}

variable "defined_tags-ApplicationName" {
  description = "Name of Application as per Inventory Database or Application Catalogue, e.g. BDS-CICD-Pipeline"
  type        = string
  default     = null
}

variable "defined_tags-EnvironmentType" {
  description = "Environment type, e.g. Dev, Stage, UAT, Prod"
  type        = string
  default     = "Dev"
}

variable "defined_tags-EnvironmentName" {
  description = "Name of Environment as per Inventory Database or Application Catalogue, e.g. BDS-CICD-Pipeline_UAT_OCI"
  type        = string
  default     = null
}

variable "defined_tags-Requestor" {
  description = "Requestor ID or email address of user requesting the stack, e.g. user@oracle.com"
  type        = string
  default     = null
}

variable "defined_tags-EnvironmentGroup" {
  description = "Value of EnvironmentGroup"
  type        = string
  default     = null
}

variable "defined_tags-ServiceArea" {
  description = "Value of ServiceArea"
  type        = string
  default     = null
}

variable "defined_tags-Lob" {
  description = "Value of LOB"
  type        = string
  default     = null
}

variable "defined_tags-Org" {
  description = "Value of Org"
  type        = string
  default     = null
}

variable "freeform_tags-catalog_item_version" {
  description = "Value of Catalog Item Version"
  type        = string
  default     = "1.0.0"
}

#################################################################################################################
#################################################################################################################


######################################### Post provisioning Extended Metadata #####################################
###################################################################################################################

variable "extended_metadata_value" {
  description = "Extended metadata for the instance."
  type        = string
}

##################################################################################################################
##################################################################################################################
