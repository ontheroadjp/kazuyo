
function _is_exist() {
    type $@ > /dev/null 2>&1
}

function _log() {
    echo  "[${SCRIPT_NAME}] $@"
}

function _failed()  {
    [ -d "${TMP_DIR}" ] && rm -rf "${TMP_DIR}"
    _log $@
    exit 1
}

