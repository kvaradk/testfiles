locals {

  infra_netgroup_1 = length(regexall(
    "^legacy-gcsdt-(default|ngcc|oasp|ldap)-v1$", var.app_provisioning_standard
  )) > 0 ? "none" : ""
  infra_netgroup_2 = var.app_provisioning_standard == "scm-servers-peocorpprod" ? "pdit_goc" : ""
  infra_netgroup_final = var.app_provisioning_standard == "default-v1" ? var.app_netgroups : ""
  infra_netgroup_final_final = coalesce(
    local.infra_netgroup_1, local.infra_netgroup_2,
    local.infra_netgroup_final
  )
  infra_netgroup = local.infra_netgroup_final_final == "none" ? "" : local.infra_netgroup_final_final

  infra_rolename_1 = length(regexall(
    "^legacy-gcsdt-(default|ngcc|oasp|ldap)-v1$", var.app_provisioning_standard
  )) > 0 ? "GITCOMPUTE" : ""
  infra_rolename_2 = var.app_provisioning_standard == "scm-servers-peocorpprod" ? "OCI_NATIVE_PROD" : ""
  infra_rolename_final = var.app_provisioning_standard == "default-v1" ? "ENTCOMPUTE" : ""
  infra_rolename = coalesce(
    local.infra_rolename_1, local.infra_rolename_2,
    local.infra_rolename_final
  )

  infra_envconfig_1 = length(regexall(
    "^legacy-gcsdt-(default|ngcc|oasp|ldap)-v1$", var.app_provisioning_standard
  )) > 0 ? "GITCOMPUTE" : ""
  infra_envconfig_2 = var.app_provisioning_standard == "scm-servers-peocorpprod" ? "OCINATIVEDEV" : ""
  infra_envconfig_final = var.app_provisioning_standard == "default-v1" ? "ENTCOMPUTE" : ""
  infra_envconfig = coalesce(
    local.infra_envconfig_1, local.infra_envconfig_2,
    local.infra_envconfig_final
  )

  infra_confname_1 = length(regexall(
    "^legacy-gcsdt-(default|ngcc)-v1$", var.app_provisioning_standard
  )) > 0 ? "GITCOMPUTE" : ""
  infra_confname_2 = var.app_provisioning_standard == "legacy-gcsdt-oasp-v1" ? "GITACS" : ""
  infra_confname_3 = var.app_provisioning_standard == "legacy-gcsdt-ldap-v1" ? "GITCOMPUTE_LDAP" : ""
  infra_confname_4 = var.app_provisioning_standard == "scm-servers-peocorpprod" ? "OCI_NATIVE_PROD" : ""
  infra_confname_final = var.app_provisioning_standard == "default-v1" ? "ENTCOMPUTE" : ""
  infra_confname = coalesce(
    local.infra_confname_1, local.infra_confname_2, local.infra_confname_3, local.infra_confname_4,
    local.infra_confname_final
  )

  customboot_option_e = format(
    "-e 'AppID=%s,ApplicationName=%s,AppShortName=%s,EnvironmentType=%s'",
    var.defined_tags-AppID, var.defined_tags-ApplicationName, var.app_short_name,
    var.defined_tags-EnvironmentName
  )

  # app_provisioning_environ = var.app_provisioning_env

  customboot_extra_vars_1 = length(regexall(
    "^legacy-gcsdt-(default|oasp|ldap)-v1$", var.app_provisioning_standard
  )) > 0 ? "-b ${local.infra_rolename} -t git ${local.customboot_option_e}" : ""
  customboot_extra_vars_2 = var.app_provisioning_standard == "legacy-gcsdt-ngcc-v1" ? "-b ${local.infra_rolename} -t gitngcc ${local.customboot_option_e}" : ""
  customboot_extra_vars_3 = var.app_provisioning_standard == "scm-servers-peocorpprod" ? "-b ${local.infra_envconfig} -l ${lower(var.app_provisioning_env)} -m \"root@localhost\" ${local.customboot_option_e}" : ""
  customboot_extra_vars_windows = var.app_provisioning_standard == "default-v1" && var.operating_system == "Windows"? "-driveFormat ${var.block_volume_1-block_volume_partition_1-block_volume_filesystem_type} -driveNames ${var.block_volume_1-block_volume_partition_1-block_volume_mount_point}" : ""
  customboot_extra_vars_default = var.app_provisioning_standard == "default-v1" && var.operating_system == "Oracle Linux"? "-b ${local.infra_rolename} ${local.customboot_option_e}" : ""
  customboot_extra_vars_final = coalesce(
    local.customboot_extra_vars_1, local.customboot_extra_vars_2, local.customboot_extra_vars_3,
    local.customboot_extra_vars_windows, local.customboot_extra_vars_default
  )
  customboot_extra_vars = local.customboot_extra_vars_final == "none" ? "" : local.customboot_extra_vars_final

  customboot_sh_1 = length(regexall(
    "^legacy-gcsdt-(default|ngcc|oasp|ldap)-v1$", var.app_provisioning_standard
  )) > 0 ? "customboot.sh" : ""
  customboot_sh_2 = var.app_provisioning_standard == "scm-servers-peocorpprod" ? "customboot.sh" : ""
  customboot_sh_final = var.app_provisioning_standard == "default-v1" ? "customboot.sh" : ""
  customboot_sh = coalesce(
    local.customboot_sh_1, local.customboot_sh_2,
    local.customboot_sh_final
  )

}

variable "app_provisioning_standard" {
  type        = string
  description = "The label for the app provisioning standard. This is used to set the appropriate variables for post-provisioning"
  # Currently we accept the following values:
  #   default-v1
  #   legacy-gcsdt-default-v1
  #   legacy-gcsdt-ngcc-v1
  #   legacy-gcsdt-oasp-v1
  #   legacy-gcsdt-ldap-v1
  #   scm-servers-peocorpprod 
  default = "default-v1"
}

variable "app_netgroups" {
  type        = string
  description = "String of netgroups for this application"
  default     = "pe_appops,eis_infra_ops,eis_network_security"
}

variable "app_short_name" {
  type        = string
  description = "The shortname for the app in inventory. This is used to set the appropriate variable for post-provisioning"
  default     = ""
}

variable "fail_iscsi_missing" {
  type        = string
  description = "This is sent to the post-provisioning scripts. This should not be changed unless you are correctly passing iscsi information to the post-provisioning script via the extended_metadata"
  default     = "false"
}

variable "subnet_access" {
  type        = string
  description = "The Access type of subnet being internal or external"
  default     = "internal"
}

variable "app_provisioning_env" {
  type        = string
  description = "The post-provisioning environment to use. This is used to set the appropriate variables for post-provisioning"
  # Currently we accept the following values:
  #   Prod
  #   Stage
  default = "Prod"
}

variable "dns_label" {
  type        = string
  description = "The hostname for the VNIC's primary private IP."
  default = ""
}

variable "operating_system" {
  type        = string
  description = "OCI value of Operating System, e.g. 'Oracle Linux', 'Windows', 'MSDN', 'Oracle Autonomous Linux' etc."
  validation {
    condition     = contains(["Oracle Linux", "Windows"], var.operating_system)
    error_message = "Supported OS must be either 'Oracle Linux' or 'Windows' only."
  }
}

variable "dns_domain_name" {
  description = "Domain Name of DNS as custom field for EE"
  type        = string
  default = ""
}

variable "dns_c_name" {
  description = "C Name of DNS as custom field for EE"
  type        = string
  default = ""
}

variable "image_type" {
  type        = string
  description = "An Enumeration of 'aims' 'native' or 'custom'"
  validation {
    condition     = contains(["aims", "native"], var.image_type)
    error_message = "Supported Image Type must be either 'aims' or 'native' only."
  }
}

resource "null_resource" "run_post_script" {
  provisioner "local-exec" {
    command = "bash ./templates/deploy_post.sh"
  }

  # Ensure this runs after the OCI core instance is created
  depends_on = [
    oci_core_instance.this, 
    oci_core_volume.this, 
    oci_core_volume_attachment.this
    ]
}

