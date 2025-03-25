data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_id
}

data "oci_identity_compartment" "this" {
  id = var.compartment_id
}

data "oci_identity_compartment" "oci_vault_compartment" {
  id = var.vault_compartment_id
}

data "oci_identity_availability_domains" "this" {
  compartment_id = var.compartment_id
}

data "oci_identity_fault_domains" "this" {
  #Required
  availability_domain = lookup(data.oci_identity_availability_domains.this.availability_domains[0], "name")
  compartment_id      = var.compartment_id
}

data "oci_core_volume_backup_policies" "this" {
  #Optional
  compartment_id = var.compartment_id
}

data "oci_vault_secrets" "existing_secrets_private" {
  compartment_id = var.vault_compartment_id
  # name           = "${"T_${data.oci_identity_tenancy.this.name}_C_${data.oci_identity_compartment.oci_vault_compartment.name}_R_${local.region_middle}_N_${var.display_name}"}_pri"
  name           = "${"T_${var.tenancy_name}_C_${data.oci_identity_compartment.this.name}_R_${local.region_middle}_N_${var.display_name}"}_pri"
  vault_id       = var.vault_id
}

data "oci_vault_secrets" "existing_secrets_public" {
  compartment_id = var.vault_compartment_id
  # name           = "${"T_${data.oci_identity_tenancy.this.name}_C_${data.oci_identity_compartment.oci_vault_compartment.name}_R_${local.region_middle}_N_${var.display_name}"}_pub"
  name           = "${"T_${var.tenancy_name}_C_${data.oci_identity_compartment.this.name}_R_${local.region_middle}_N_${var.display_name}"}_pub"
  vault_id       = var.vault_id
}

data "oci_secrets_secretbundle" "ssh_private_key" {
  # secret_id = oci_vault_secret.ssh_private_key[0].id
  # secret_id = data.oci_vault_secrets.existing_secrets_private.secrets[0].id

  secret_id = length(data.oci_vault_secrets.existing_secrets_private.secrets) > 0 ? data.oci_vault_secrets.existing_secrets_private.secrets[0].id : oci_vault_secret.ssh_private_key[0].id
}

data "oci_secrets_secretbundle" "ssh_public_key" {
  # secret_id = oci_vault_secret.ssh_public_key[0].id
  # secret_id = data.oci_vault_secrets.existing_secrets_public.secrets[0].id
  secret_id = length(data.oci_vault_secrets.existing_secrets_public.secrets) > 0 ? data.oci_vault_secrets.existing_secrets_public.secrets[0].id : oci_vault_secret.ssh_public_key[0].id
}

################################
# Template for cloud-init_config
################################
data "template_cloudinit_config" "this" {
  gzip          = true
  base64_encode = true
  part {
    filename     = "init.sh"
    content_type = "text/x-shellscript" #"text/cloud-config"
    content      = data.template_file.linux_template.rendered
  }
}

##############################
# Template-file for cloud-init
##############################
data "template_file" "linux_template" {
  template = "${file("${path.module}/templates/linux_template.tpl")}"

  vars = {
    file_path    = "/tmp/myfile.txt"
    file_content = "This is the content passed from Terraform"
    instance_name = var.display_name
    # infra_tenancy = upper("${data.oci_identity_tenancy.this.name}")
    infra_tenancy = upper("${var.tenancy_name}")
    infra_netgroup = local.infra_netgroup
    infra_applob = var.defined_tags-Lob
    infra_emdslob = var.defined_tags-Lob
    infra_fail_iscsi_missing = var.fail_iscsi_missing
    infra_rolename = local.infra_rolename
    infra_envconfig = local.infra_envconfig
    infra_confname = local.infra_confname
    subnet_access = var.subnet_access
    customboot_extra_vars = local.customboot_extra_vars
    app_provisioning_env = var.app_provisioning_env
    customboot_sh = local.customboot_sh
    dns_label = var.dns_label == null ? "" : var.dns_label
    # hostname_label = var.hostname_label
    hostname_label = local.generated_hostname
  }
}

# data "template_file" "linux_template" {

#   template = "${file("${path.module}/templates/linux_template.tpl")}"

#   vars = {
#     file_path    = "/tmp/myfile.txt"
#     file_content = "This is the content passed from Terraform"
#   }
# }



