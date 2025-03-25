# Note, we will only export thorse vars in config.json that are required in post provisioning
# Our post.sh expects few params and not all vars
# This is to overcome the issue of RMS, where we are not storing any variable value that we need for post provisioning in any file in RMS

resource "null_resource" "export_variables" {
  provisioner "local-exec" {
    command = <<EOT
      echo '${jsonencode(local.exported_vars)}' > config.json
    EOT
  }
}

locals {
  exported_vars = merge(
    {
      tenancy_name                  = var.tenancy_name,
      region                        = var.region,
      compartment_id                = var.compartment_id,
      display_name                  = var.display_name,
      create_vnic_details-subnet_id = var.create_vnic_details-subnet_id
      app_short_name                = var.app_short_name,
      app_provisioning_env          = var.app_provisioning_env,
      operating_system              = var.operating_system
    },
    var.attach_block_volume_1 ? merge(
      {
        "block_volume_1-volume_size_in_gbs" = var.block_volume_1-volume_size_in_gbs,
        "block_volume_1-block_volume_name" = var.block_volume_1-block_volume_name,
        "block_volume_1-block_volume_attachment_type" = var.block_volume_1-block_volume_attachment_type
      },
      var.block_volume_1-block_volume_partition_1-block_volume_partition_size != null ? {
        "block_volume_1-block_volume_partition_1-block_volume_partition_size"  = var.block_volume_1-block_volume_partition_1-block_volume_partition_size,
        "block_volume_1-block_volume_partition_1-block_volume_filesystem_type" = var.block_volume_1-block_volume_partition_1-block_volume_filesystem_type,
        "block_volume_1-block_volume_partition_1-block_volume_mount_point"     = var.block_volume_1-block_volume_partition_1-block_volume_mount_point
      } : {},
      var.block_volume_1-block_volume_partition_2-block_volume_partition_size != null ? {
        "block_volume_1-block_volume_partition_2-block_volume_partition_size"  = var.block_volume_1-block_volume_partition_2-block_volume_partition_size,
        "block_volume_1-block_volume_partition_2-block_volume_filesystem_type" = var.block_volume_1-block_volume_partition_2-block_volume_filesystem_type,
        "block_volume_1-block_volume_partition_2-block_volume_mount_point"     = var.block_volume_1-block_volume_partition_2-block_volume_mount_point
      } : {}
    ) : {},
    var.attach_block_volume_2 ? merge(
      {
        "block_volume_2-volume_size_in_gbs" = var.block_volume_2-volume_size_in_gbs,
        "block_volume_2-block_volume_name" = var.block_volume_2-block_volume_name,
        "block_volume_2-block_volume_attachment_type" = var.block_volume_2-block_volume_attachment_type
      },
      var.block_volume_2-block_volume_partition_1-block_volume_partition_size != null ? {
        "block_volume_2-block_volume_partition_1-block_volume_partition_size"  = var.block_volume_2-block_volume_partition_1-block_volume_partition_size,
        "block_volume_2-block_volume_partition_1-block_volume_filesystem_type" = var.block_volume_2-block_volume_partition_1-block_volume_filesystem_type,
        "block_volume_2-block_volume_partition_1-block_volume_mount_point"     = var.block_volume_2-block_volume_partition_1-block_volume_mount_point
      } : {},
      var.block_volume_2-block_volume_partition_2-block_volume_partition_size != null ? {
        "block_volume_2-block_volume_partition_2-block_volume_partition_size"  = var.block_volume_2-block_volume_partition_2-block_volume_partition_size,
        "block_volume_2-block_volume_partition_2-block_volume_filesystem_type" = var.block_volume_2-block_volume_partition_2-block_volume_filesystem_type,
        "block_volume_2-block_volume_partition_2-block_volume_mount_point"     = var.block_volume_2-block_volume_partition_2-block_volume_mount_point
      } : {}
    ) : {}
  )
}
