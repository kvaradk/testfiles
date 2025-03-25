###################
# Compute Instance#
###################

resource "null_resource" "generate_metadata" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Contents of config.json is:"
      cat config.json | jq '.'
      python3 generate_metadata.py
      cat metadata.json | jq '.'
    EOT
  }

  # Below is defined in data-parser.tf
  depends_on = [null_resource.export_variables]
}


resource "null_resource" "run_hostname_generator" {
  provisioner "local-exec" {
    command = "python3 ./templates/refactor_hostname.py > hostname.txt"
  }

  depends_on = [null_resource.export_variables]
}


data "local_file" "hostname" {
  depends_on = [null_resource.run_hostname_generator]
  filename   = "hostname.txt"
}


data "local_file" "metadata_json" {
  depends_on = [null_resource.generate_metadata]
  filename   = "metadata.json"
}

# output "parsed_metadata" {
#   value = jsondecode(data.local_file.metadata_json.content)
# }

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "oci_vault_secret" "ssh_private_key" {

  count = length(data.oci_vault_secrets.existing_secrets_private.secrets) == 0 ? 1 : 0

  compartment_id = var.vault_compartment_id
  secret_name    = "${local.secret_name}_pri"
  vault_id       = var.vault_id
  key_id         = var.key_id

  metadata = local.secret_annotation

  secret_content {
    content      = base64encode(tls_private_key.this.private_key_pem)
    content_type = "BASE64"
  }

  depends_on = [
    tls_private_key.this
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_vault_secret" "ssh_public_key" {

  count = length(data.oci_vault_secrets.existing_secrets_public.secrets) == 0 ? 1 : 0

  compartment_id = var.vault_compartment_id
  secret_name    = "${local.secret_name}_pub"
  vault_id       = var.vault_id
  key_id         = var.key_id

  metadata = local.secret_annotation

  secret_content {
    content      = base64encode(tls_private_key.this.public_key_openssh)
    content_type = "BASE64"
  }

  depends_on = [
    tls_private_key.this
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_instance" "this" {
  availability_domain = local.availability_domain
  # fault_domain        = var.instance_fault_domain
  compartment_id = var.compartment_id
  display_name   = local.generated_hostname
  shape          = var.shape


  shape_config {
    memory_in_gbs = var.shape_config-memory_in_gbs
    ocpus         = var.shape_config-ocpus

    # Convert "null" string to actual null, then assign 0 if it's null
    baseline_ocpu_utilization = var.shape_config-baseline_ocpu_utilization
    nvmes                     = var.shape_config-nvmes
    vcpus                     = var.shape_config-vcpus
    # baseline_ocpu_utilization = (var.shape_config-baseline_ocpu_utilization != null && var.shape_config-baseline_ocpu_utilization != "null") ? var.shape_config-baseline_ocpu_utilization : "BASELINE_1_1"
    # nvmes                     = (var.shape_config-nvmes != null && var.shape_config-nvmes != "null") ? var.shape_config-nvmes : 0
    # vcpus                     = (var.shape_config-vcpus != null && var.shape_config-vcpus != "null") ? var.shape_config-vcpus : 0
  }


  source_details {
    source_id               = var.source_id
    source_type             = var.source_type
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  create_vnic_details {
    subnet_id                 = var.create_vnic_details-subnet_id
    hostname_label            = local.generated_hostname
    assign_public_ip          = var.create_vnic_details-assign_public_ip
    nsg_ids                   = var.create_vnic_details-nsg_ids
    private_ip                = var.create_vnic_details-private_ip
    assign_private_dns_record = var.create_vnic_details-assign_private_dns_record
  }

  # metadata = {
  #   ssh_authorized_keys = base64decode(data.oci_secrets_secretbundle.ssh_public_key.secret_bundle_content[0].content)
  #   user_data           = data.template_cloudinit_config.this.rendered
  # }

  metadata = {
    # Conditional expression to include ssh_authorized_keys only when operating_system is Linux
    ssh_authorized_keys = var.operating_system == "Oracle Linux" ? base64decode(data.oci_secrets_secretbundle.ssh_public_key.secret_bundle_content[0].content) : null
    # Currently, custom cloud-init cannot be supplied by end-user
    user_data = (
      var.operating_system == "Oracle Linux" && (var.image_type == "aims" || var.image_type == "native")
      ) ? "${data.template_cloudinit_config.this.rendered}" : (
      var.operating_system == "Windows" && (var.image_type == "aims" || var.image_type == "native")
      ) ? base64encode(<<-EOF
                    <powershell>
                      # Wait for 60 sec before trigger of post provisioning. This allows windows system to sync
                      Start-Sleep -Seconds 60
                      # Download and run the PowerShell script
                      # $baseUrl = "https://lb-yum-phx.appoci.oraclecorp.com/data_files/bdsconfig/Stage/tarballs/"                      
                      $baseUrl = "https://lb-yum-phx.appoci.oraclecorp.com/data_files/bdsconfig/Prod/tarballs/Windows/"
                      $filesToDownload = @("win_init.ps1", "crowdstrike_install.ps1", "proxy_configurations.ps1", "rsm_install.ps1", "crowdstrike_install_startup.ps1", "set_proxy.ps1", "startup_script_user_login.ps1", "certificate.pem", "startup.vbs", "manual_setup.vbs", "crowdstrike.exe", "RSM.msi")
                      $targetDirectory = "C:\postscript"
                      if (!(Test-Path -Path $targetDirectory)) {
                        New-Item -ItemType Directory -Path $targetDirectory
                      }

                      # Loop through the files and download each one
                      foreach ($file in $filesToDownload) {
                          $url = $baseUrl + $file
                          $filePath = Join-Path $targetDirectory $file
                          Invoke-WebRequest -Uri $url -OutFile $filePath
                          # if ($file -match '\.exe$|\.msi$') {
                          if ($file -match '\.exe$') {
                              Start-Sleep -Seconds 120
                          } else {
                              Start-Sleep -Seconds 20
                          }
                      }                      
                      $postScriptFilePath = Join-Path $targetDirectory "win_init.ps1"
                      $customboot_extra_vars = @{
                          driveFormat = "${var.block_volume_1-block_volume_partition_1-block_volume_filesystem_type}"
                          driveNames = "${var.block_volume_1-block_volume_partition_1-block_volume_mount_point}"                     
                          tenancyName = "${var.tenancy_name}" 
                          regionName = "${var.region}" 
                      }
                      & $postScriptFilePath @customboot_extra_vars
                    </powershell>
                  EOF
    ) : null
  }

  extended_metadata = {
    # metadata_details = jsondecode(data.local_file.metadata_json.content)
    metadata_details = var.extended_metadata_value
  }

  defined_tags  = local.app_tags
  freeform_tags = local.freeform_tags


  agent_config {
    are_all_plugins_disabled = var.instance_agent_config-are_all_plugins_disabled
    is_management_disabled   = var.instance_agent_config-is_management_disabled
    is_monitoring_disabled   = var.instance_agent_config-is_monitoring_disabled

    dynamic "plugins_config" {
      for_each = local.enabled_plugins

      content {
        desired_state = plugins_config.value.desired_state
        name          = plugins_config.value.name
      }
    }
  }


  ##################################
  ## CIS Benchmark Recommendation
  ##################################

  instance_options {

    #Optional
    are_legacy_imds_endpoints_disabled = var.are_legacy_imds_endpoints_disabled
  }


  # is_pv_encryption_in_transit_enabled = var.instance_is_pv_encryption_in_transit_enabled
  launch_options {
    #Optional
    network_type                        = var.network_type
    is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled
  }
  # platform_config {
  #   #Required
  #   type = var.instance_platform_config_type
  #   #Optional
  #   is_secure_boot_enabled = var.instance_platform_config_is_secure_boot_enabled
  # }

  depends_on = [
    null_resource.generate_metadata,
    tls_private_key.this,
    oci_vault_secret.ssh_private_key,
    oci_vault_secret.ssh_public_key
  ]


  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      metadata,
      extended_metadata,
    ]
  }
}

################
# Block-Volume #
################
resource "oci_core_volume" "this" {
  for_each = { for k, v in local.block_volumes : k => v if v.attach }

  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = each.value.block_volume_name != null && each.value.block_volume_name != "" ? each.value.block_volume_name : "${var.display_name}_${each.key}"
  size_in_gbs         = each.value.volume_size_in_gbs
  defined_tags        = local.app_tags
  freeform_tags       = local.freeform_tags

  depends_on = [
    oci_core_instance.this
  ]

  lifecycle {
    prevent_destroy = true
  }
}
#################################
# Block Volume Creation
#################################

###########################
# Block-Volume Attachment #
###########################
resource "oci_core_volume_attachment" "this" {
  for_each = { for k, v in local.block_volumes : k => v if v.attach }

  attachment_type = each.value.attachment_type
  instance_id     = oci_core_instance.this.id
  volume_id       = oci_core_volume.this[each.key].id
  display_name    = each.value.block_volume_name != null && each.value.block_volume_name != "" ? each.value.block_volume_name : "${var.display_name}_${each.key}"

  depends_on = [
    oci_core_instance.this,
    oci_core_volume.this
  ]

  lifecycle {
    prevent_destroy = true
  }
}

########################################
# Block-Volume Backup Policy Assignment
########################################
resource "oci_core_volume_backup_policy_assignment" "this_block" {
  for_each = var.block_volume_backup_policy_id != null ? { for k, v in local.block_volumes : k => v if v.attach } : {}

  asset_id  = oci_core_volume.this[each.key].id
  policy_id = var.block_volume_backup_policy_id

  depends_on = [
    oci_core_volume.this
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# ######################################
# # Boot-Volume backup policy assignment 
# ######################################
resource "oci_core_volume_backup_policy_assignment" "this_boot" {
  count     = var.boot_volume_backup_policy_id == null ? 0 : 1
  asset_id  = oci_core_instance.this.boot_volume_id
  policy_id = local.boot_volume_backup_policy_id
  depends_on = [
    oci_core_instance.this
  ]
  lifecycle {
    prevent_destroy = true
  }
}

locals {

  block_volumes = {
    "bv1" = {
      attach             = var.attach_block_volume_1
      volume_size_in_gbs = var.block_volume_1-volume_size_in_gbs
      block_volume_name  = var.block_volume_1-block_volume_name
      attachment_type    = var.block_volume_1-block_volume_attachment_type
    }
    "bv2" = {
      attach             = var.attach_block_volume_2
      volume_size_in_gbs = var.block_volume_2-volume_size_in_gbs
      block_volume_name  = var.block_volume_2-block_volume_name
      attachment_type    = var.block_volume_2-block_volume_attachment_type
    }
  }


  instance_agent_plugins = {
    "plugin_1" = {
      set_value     = var.instance_agent_config-plugin_config_1-set_value
      desired_state = var.instance_agent_config-plugin_config_1-desired_state
      name          = var.instance_agent_config-plugin_config_1-name
    }
    "plugin_2" = {
      set_value     = var.instance_agent_config-plugin_config_2-set_value
      desired_state = var.instance_agent_config-plugin_config_2-desired_state
      name          = var.instance_agent_config-plugin_config_2-name
    }
    "plugin_3" = {
      set_value     = var.instance_agent_config-plugin_config_3-set_value
      desired_state = var.instance_agent_config-plugin_config_3-desired_state
      name          = var.instance_agent_config-plugin_config_3-name
    }
    "plugin_4" = {
      set_value     = var.instance_agent_config-plugin_config_4-set_value
      desired_state = var.instance_agent_config-plugin_config_4-desired_state
      name          = var.instance_agent_config-plugin_config_4-name
    }
    "plugin_5" = {
      set_value     = var.instance_agent_config-plugin_config_5-set_value
      desired_state = var.instance_agent_config-plugin_config_5-desired_state
      name          = var.instance_agent_config-plugin_config_5-name
    }
  }
  # Filter only the plugins where set_value is true
  enabled_plugins = {
    for k, v in local.instance_agent_plugins : k => v if v.set_value
  }


  # Extract only non-empty defined tags
  base_tags = {
    "${var.defined_tag_namespace}.CreatedBy"      = "$${iam.principal.name}"
    "${var.defined_tag_namespace}.CreateDateTime" = "$${oci.datetime}"
    "${var.defined_tag_namespace}.CreateUserType" = "$${iam.principal.type}"
  }

  # Filtering only non-empty defined tags
  defined_tags_filtered = {
    for k, v in {
      "AppID"            = var.defined_tags-AppID
      "ApplicationName"  = var.defined_tags-ApplicationName
      "EnvironmentType"  = var.defined_tags-EnvironmentType
      "EnvironmentName"  = var.defined_tags-EnvironmentName
      "Lob"              = var.defined_tags-Lob
      "EnvironmentGroup" = var.defined_tags-EnvironmentGroup
      "ServiceArea"      = var.defined_tags-ServiceArea
      "Requestor"         = var.defined_tags-Requestor
      "Org"              = var.defined_tags-Org
    } : "${var.defined_tag_namespace}.${k}" => v if v != "" && v != null
  }

  # Merging base tags with filtered defined tags
  app_tags = merge(local.base_tags, local.defined_tags_filtered)

  # Dynamically filter non-empty freeform tags
  freeform_tags_filtered = {
    for k, v in {
      "CatalogItemVersion" = var.freeform_tags-catalog_item_version
      # Future tags can be added here
      # "CostCentre"" = var.freeform_tags-cost_centre
    } : k => v if v != "" && v != null
  }
  freeform_tags = local.freeform_tags_filtered


  availability_domain = var.availability_domain != null ? var.availability_domain : lookup(data.oci_identity_availability_domains.this.availability_domains[0], "name")

  block_volume_backup_policy_id = var.block_volume_backup_policy_id != null ? var.block_volume_backup_policy_id : lookup(data.oci_core_volume_backup_policies.this.volume_backup_policies[0], "id")

  boot_volume_backup_policy_id = var.boot_volume_backup_policy_id != null ? var.boot_volume_backup_policy_id : lookup(data.oci_core_volume_backup_policies.this.volume_backup_policies[0], "id")

  fault_domain = var.instance_fault_domain != null ? var.instance_fault_domain : lookup(data.oci_identity_fault_domains.this.fault_domains[0], "name")

  region_middle = element(regexall("[^-]+-([^-]+)-[^-]+", var.region), 0)[0]

  # secret_name = "T_${data.oci_identity_tenancy.this.name}_C_${data.oci_identity_compartment.this.name}_R_${local.region_middle}_N_${var.display_name}"
  secret_name = "T_${var.tenancy_name}_C_${data.oci_identity_compartment.this.name}_R_${local.region_middle}_N_${var.display_name}"

  # SiV requirement: https://confluence.oraclecorp.com/confluence/display/OCISMS/SiV%3A+Annotating+Secrets
  secret_annotation = {
    "secret_type" : "SSH_KEY",
    "target_system" : var.operating_system == "Windows" ? "WINDOWS" : "LINUX"
  }
  generated_hostname = trimspace(data.local_file.hostname.content)
}