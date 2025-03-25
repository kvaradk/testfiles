output "resource_ocid" {
  description = "The OCID of the instance."
  value       = oci_core_instance.this.id
}

output "private_ip" {
  value       = oci_core_instance.this.private_ip
  description = "The private IP address of instance VNIC"
}


output "hostname" {
  value       = local.generated_hostname
}


# output "vnic_details" {
#   description = "The details of the VNIC."
#   value       = oci_core_instance.this.create_vnic_details[0]
# }

