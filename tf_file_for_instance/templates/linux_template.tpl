#!/bin/bash
# Set hostname if var.dns_label signifies subnet dns not enabled
[ "$${dns_label}" == "" ] && hostnamectl set-hostname $${hostname_label}
# Chef client installation and chef recipes
infra_tenancy='${infra_tenancy}'
infra_netgroup='${infra_netgroup}'
infra_applob='${infra_applob}'
infra_emdslob='${infra_emdslob}'
infra_envconfig='${infra_envconfig}'
infra_rolename='${infra_rolename}'
infra_confname='${infra_confname}'
infra_subnet_access_type='${subnet_access}'
infra_fail_iscsi_missing='${infra_fail_iscsi_missing}'
environment='${app_provisioning_env}'
curl -k -o customboot-1.0.0-1.noarch.rpm https://192.29.104.161/data_files/bdsconfig/Prod/rpms/customboot-1.0.0-1.noarch.rpm
rpm -ivh customboot-1.0.0-1.noarch.rpm
/usr/bin/${customboot_sh} -r ${infra_rolename}_POST_CB.json ${customboot_extra_vars}
rpm -e customboot
reboot -f
echo '${file_content}' > '${file_path}'