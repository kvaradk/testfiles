#!/usr/bin/env bash
###############
# Script to update compute metadata with iscsi details
###############
set -euo pipefail
IFS=$'\n\t'

PROGNAME="$(basename "$0")"
readonly PROGNAME

PROGNAME_NOEXT="$(basename "$0" '.sh')"
readonly PROGNAME_NOEXT

DIRNAME="$(dirname "$0")"
readonly DIRNAME

POST_SCRIPTS_DIRNAME="${DIRNAME}/post_scripts"
readonly POST_SCRIPTS_DIRNAME

START_TIME="$(date +'%Y-%m-%d %H:%M:%S')"
readonly START_TIME

#START_TIME_STR="$(echo "${START_TIME}" | tr ' :' '-')"
#readonly START_TIME_STR

OCI_CLI_DOCKER_IMAGE="bds-docker.dockerhub-phx.oci.oraclecorp.com/bds-pipeline/oci-cli:3.16.0"
readonly OCI_CLI_DOCKER_IMAGE

# Functions
info()    { echo "[INFO]    $*" >&2 ; }
warning() { echo "[WARNING] $*" >&2 ; }
error()   { echo "[ERROR]   $*" >&2 ; }
fatal()   { echo "[FATAL]   $*" >&2 ; exit 1 ; }
join_by() { local IFS="$1"; shift; echo "$*"; }

cleanup() {
    [ -z "${TMP_FILE:-}" ] && return 0
    rm -f "${TMP_FILE}"
    return 0
}

usage(){
    cat <<-EOF
    Usage:
        ${PROGNAME} -h
        ${PROGNAME} [-c <compartment-id>] [-d <host-displayname>] [-r <region-key>] [-t <tenancy-name>] [-w <secs>]
    
    Options:

        -c <compartment-id>
            The OCI compartment id for the compute.
            This is required.

        -d <host-displayname>
            The compute display name.
            This is required.

        -r <region-key>
            The OCI region key of the compute.
            This is required.
    
        -t <tenancy-name>
            The OCI tenancy name of the compute.
            This is required.

        -w <secs>
            The number of secs after which to abort retrying lookups for the
            compute instance and block-volume.
            The default is 60.
EOF
}

# check_connectivity(){
#     HOST="ipcontrol.oraclecorp.com"
#     PORT="8443"
#     # Use curl to test connectivity
#     echo "Checking connectivity to $HOST:$PORT using curl..."
#     # curl --connect-timeout 5 -v https://$HOST:$PORT >/dev/null 2>&1
#     curl --connect-timeout 5 -v https://$HOST:$PORT

#     # if [ $? -eq 0 ]; then
#     #     echo "Successfully connected to $HOST:$PORT"
#     # else
#     #     echo "Failed to connect to $HOST:$PORT"
#     #     exit 1
#     # fi
# }


declare_vars(){

    info "Declaring required vars"
    # Set required global vars
    declare -g DISPLAY_NAME=""
    declare -g REGION
    declare -g COMPARTMENT_ID
    declare -g SUBNET_ID
    declare -g TENANCY_NAME
    declare -g INCREMENT_SECS=20
    declare -g OCI_INSTANCE=""
    declare -g OCI_INSTANCE_ID=""
    declare -g OCI_BV=""
    declare -g OCI_BV_ID=""
    declare -g TMP_FILE=""
    declare -g SUBNET_DOMAIN_NAME=""
    declare -g BV_DISPLAYNAME
}

get_json_files_touchless_pipeline(){
    declare -g PAYLOAD_JSON

    PAYLOAD_JSON="./config.json"

    if [[ -f "${PAYLOAD_JSON}" ]]; then
        info "Found payload JSON file ${PAYLOAD_JSON}"
    else
        fatal "The payload JSON file ${PAYLOAD_JSON} does not exist"
    fi
}

get_vars_touchless_pipeline(){

    get_json_files_touchless_pipeline
    TENANCY_NAME=$(jq -r '.tenancy_name|select (.!=null)' "${PAYLOAD_JSON}")
    [[ -z "${TENANCY_NAME}" ]] && fatal "Failed to find \"tenancy_name\" in ${PAYLOAD_JSON}"
    TENANCY_NAME=${TENANCY_NAME^^}
    REGION=$(jq -r '.region|select (.!=null)' "${PAYLOAD_JSON}")
    [[ -z "${REGION}" ]] && fatal "Failed to find \"region\" in ${PAYLOAD_JSON}"
    COMPARTMENT_ID=$(jq -r '.compartment_id|select (.!=null)' "${PAYLOAD_JSON}")
    [[ -z "${COMPARTMENT_ID}" ]] && fatal "Failed to find \"compartment_id\" in ${PAYLOAD_JSON}"
    DISPLAY_NAME=$(jq -r '.display_name|select (.!=null)' "${PAYLOAD_JSON}")
    [[ -z "${DISPLAY_NAME}" ]] && fatal "Failed to find \"display_name\" in ${PAYLOAD_JSON}"
    SUBNET_ID=$(jq -r '."create_vnic_details-subnet_id"|select (.!=null)' "${PAYLOAD_JSON}")
    [[ -z "${SUBNET_ID}" ]] && fatal "Failed to find \"subnet_id\" in ${PAYLOAD_JSON}"
    BV_DISPLAYNAME=$(jq -r '."block_volume_1-block_volume_name"|select (.!=null)' "${PAYLOAD_JSON}")
    [[ -z "${BV_DISPLAYNAME}" ]] && fatal "Failed to find \"block_volume_name\" in ${PAYLOAD_JSON}"
    return 0
}


get_oci_instance(){
    NUM_SECS_ELAPSED=0
    info "Attempting to get compute instance with display-name '${DISPLAY_NAME}' via OCI cli"
    local oci_command=(
        'oci compute' 'instance' 'list' '--compartment-id' "${COMPARTMENT_ID}"
        '--region' "${REGION}"
        '--all'
        '--query' "'data[?\"display-name\"==\`""${DISPLAY_NAME}""\`]|[?\"lifecycle-state\"==\`RUNNING\`]|[0]'"
    )
    while [ "${NUM_SECS_ELAPSED}" -le "${WAIT_SECS}" ]; do
        info "Running command: $(join_by ' ' "${oci_command[@]}")"
        OCI_INSTANCE=$(eval "${oci_command[@]}") || fatal "OCI cli command failed"
        if [ -z "${OCI_INSTANCE}" ]; then
            info "Waiting ${INCREMENT_SECS} seconds for compute instance with display-name ${DISPLAY_NAME}"
        else
            break
        fi
        sleep ${INCREMENT_SECS}
        NUM_SECS_ELAPSED=$((NUM_SECS_ELAPSED+INCREMENT_SECS))
    done
    if [ -z "${OCI_INSTANCE}" ]; then
        fatal "Could not find instance with display name ${DISPLAY_NAME}"
    else
        OCI_INSTANCE_ID=$(echo "${OCI_INSTANCE}" | jq -r '.id')
        [ -z "${OCI_INSTANCE_ID}" ] && fatal "Could not find id for instance with display-name ${DISPLAY_NAME}"
        info "Found OCI instance ${DISPLAY_NAME} (id=${OCI_INSTANCE_ID}) in state 'RUNNING'"
    fi
}

get_oci_attached_vol(){
    info "Attempting to get BV with display-name '${BV_DISPLAYNAME}' via OCI cli"
    local oci_command=(
        'oci compute' 'volume-attachment' 'list' '--compartment-id' "${COMPARTMENT_ID}"
        '--region' "${REGION}"
        '--instance-id' "${OCI_INSTANCE_ID}"
        '--query' "'data[?\"display-name\"==\`""${BV_DISPLAYNAME}""\`]|[?\"lifecycle-state\"==\`ATTACHED\`]|[0]'"
    )
    NUM_SECS_ELAPSED=0
    while [ "${NUM_SECS_ELAPSED}" -le "${WAIT_SECS}" ]; do
        info "Running command: $(join_by ' ' "${oci_command[@]}")"
        OCI_BV=$(eval "${oci_command[@]}") || fatal "OCI cli command failed"
        if [ -z "${OCI_BV}" ]; then
            info "Waiting ${INCREMENT_SECS} seconds for BV with display-name ${BV_DISPLAYNAME}"
        else
            break
        fi
        sleep ${INCREMENT_SECS}
        NUM_SECS_ELAPSED=$((NUM_SECS_ELAPSED+INCREMENT_SECS))
    done
    if [ -z "${OCI_BV}" ]; then
        fatal "Could not find BV with display name ${BV_DISPLAYNAME}"
    else
        OCI_BV_ID=$(echo "${OCI_BV}" | jq -r '.id')
        [ -z "${OCI_BV_ID}" ] && fatal "Could not find id for BV with display-name ${BV_DISPLAYNAME}"
        OCI_BV_TYPE=$(echo "${OCI_BV}" | jq -r '."attachment-type"')
        [ -z "${OCI_BV_TYPE}" ] && fatal "Could not find attachment-type for BV with id ${OCI_BV_ID}"
        if [[ "${OCI_BV_TYPE}" = "iscsi" ]]; then
            info "Found OCI BV ${BV_DISPLAYNAME} (id=${OCI_BV_ID}) of type iscsi in state 'ATTACHED'"
            return 0
        else
            info "Found OCI BV ${BV_DISPLAYNAME} (id=${OCI_BV_ID}) of type ${OCI_BV_TYPE} in state 'ATTACHED'. Nothing to be done for this BV type"
            # exit 0
        fi
    fi
}


get_subnet_domain_name(){
    info "Attempting to get subnet domain name via OCI cli"
    local oci_command=(
        'oci network' 'subnet' 'get' '--subnet-id'  "${SUBNET_ID}"
        '--region' "${REGION}"
        '--raw-output'
        --query "'data.\"subnet-domain-name\"'"  
        )
    info "Running command: $(join_by ' ' "${oci_command[@]}")"
    SUBNET_DOMAIN_NAME=$(eval "${oci_command[@]}") || fatal "OCI cli command failed"
    [ -z "${SUBNET_DOMAIN_NAME}" ] && warning "Subnet Domain not found. Possibly not enabled on subnet: ${SUBNET_ID}"
    info "Subnet Domain Name: ${SUBNET_DOMAIN_NAME}"
}


update_instance_metadata(){
    local curr_metadata
    local ipv4
    local iqn
    local port

    info "Attempting to update the iscsi metadata for instance"
    ipv4=$(echo "${OCI_BV}" | jq -r '.ipv4')
    [ -z "${ipv4}" ] && fatal "Could not get 'ipv4' for BV with id ${OCI_BV_ID}"
    iqn=$(echo "${OCI_BV}" | jq -r '.iqn')
    [ -z "${iqn}" ] && fatal "Could not get 'iqn' for BV with id ${OCI_BV_ID}"
    port=$(echo "${OCI_BV}" | jq -r '.port')
    [ -z "${port}" ] && fatal "Could not get 'port' for BV with id ${OCI_BV_ID}"

    TMP_FILE="/tmp/${PROGNAME_NOEXT}_${DISPLAY_NAME}.json"
    curr_metadata=$(echo "${OCI_INSTANCE}" | jq '.data."extended-metadata"')
    block_volume_attributes=$(cat ./metadata.json | jq '.block_volume_attributes')
    echo "Block Volume Attribute is: " $block_volume_attributes
    echo "${curr_metadata}" | jq ".iscsivolumes={\"volume_attachment1\":{\"iqn\":\"${iqn}\",\"ipv4\":\"${ipv4}\",\"port\":\"${port}\"}}" > "${TMP_FILE}"
    info "Inserting Block Volume Attribute in Core Instance Extended Metadata.."
    var_block_vol_partition_data=$(cat "${TMP_FILE}" | jq '. + { "block_volume_attributes": '"${block_volume_attributes}"' }')
    echo ${var_block_vol_partition_data} | jq '.' > "${TMP_FILE}"

    info "Inserting Subnet Domain Name Attribute in Core Instance Extended Metadata.."
    var_subnet_domain_name_data=$(cat "${TMP_FILE}" | jq '. + { "subnet_domain_name": "'${SUBNET_DOMAIN_NAME}'" }')
    echo ${var_subnet_domain_name_data} | jq '.' > "${TMP_FILE}"

    local oci_command=(
        oci compute instance update
        --region "${REGION}"
        --instance-id "${OCI_INSTANCE_ID}"
        --extended-metadata "file://${TMP_FILE}"
        --force
    )

    info "Running command: $(join_by ' ' "${oci_command[@]}")"
    "${oci_command[@]}" || fatal "OCI cli command failed"
}


# Main
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap cleanup EXIT

    # Global vars for cli options
    declare DISPLAY_NAME=""
    declare TENANCY_NAME=""
    declare REGION=""
    declare COMPARTMENT_ID=""
    declare WAIT_SECS="60"
    declare INCREMENT_SECS=20
    declare SUBNET_ID=""

    info "${PROGNAME} starting at ${START_TIME}"
    declare_vars
    get_vars_touchless_pipeline
    # check_connectivity
    get_oci_instance
    get_oci_attached_vol
    get_subnet_domain_name
    update_instance_metadata
    info "${PROGNAME} complete"
fi
