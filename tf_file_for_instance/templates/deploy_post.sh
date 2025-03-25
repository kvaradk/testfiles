#!/usr/bin/env bash
###############
# Script to run post.sh in touchless pipeline
###############
set -euo pipefail
IFS=$'\n\t'

PROGNAME="$(basename "$0")"
readonly PROGNAME

PROGNAME_NOEXT="$(basename "$0" '.sh')"
readonly PROGNAME_NOEXT

DIRNAME="$(dirname "$0")"
readonly DIRNAME

START_TIME="$(date +'%Y-%m-%d %H:%M:%S')"
readonly START_TIME


# Functions
info()    { echo "[INFO]    $*" >&2 ; }
warning() { echo "[WARNING] $*" >&2 ; }
error()   { echo "[ERROR]   $*" >&2 ; }
fatal()   { echo "[FATAL]   $*" >&2 ; exit 1 ; }
join_by() { local IFS="$1"; shift; echo "$*"; }

cleanup() {
    return 0
}

run_post_script(){
    local post_script_path

    echo ">> Executing run_post_script"
    # echo ">> Moving to TF_SRC_ROOT dir" ; cd "${TF_SRC_ROOT}"
    # post_script_path="${MODULE_DIR}/post.sh"
    echo "Current wrking dir is:"
    pwd
    echo "Contents of dir is"
    ls -la
    post_script_path="./templates/post.sh"

    if [[ ! -f "${post_script_path}" ]]; then
        info "Post-script does not exist at ${post_script_path}. Nothing to be done"
        return 0
    fi

    info "Adding execute perms to file ${post_script_path}"
    chmod +x "${post_script_path}"

    info "Running post script ${post_script_path}"
    eval "${post_script_path}"
}

# Main
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap cleanup EXIT

    info "${PROGNAME} starting at ${START_TIME}"
    # run_prechecks
    # prepare_module
    run_post_script
    info "${PROGNAME} complete"
fi
