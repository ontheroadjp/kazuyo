
REPORT=''

function _init_report() {
    REPORT="${1}"
    : >| ${REPORT}
}

# $1: report text
function _log() {
    printf "$1" >> ${REPORT}
}
