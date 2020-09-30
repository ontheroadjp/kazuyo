#!/bin/bash

LOG_INFO=1
LOG_DEBUG=2
LOG_LEVEL=${LOG_INFO}
#LOG_FILE=''
if ${IS_DEBUG_MODE}; then LOG_LEVEL=${LOG_DEBUG}; fi

# $1: log text, $2: log level
function _log() {
    if [ ${LOG_LEVEL} -ge $2 ]; then
        printf "$1" >> ${DIST_DIR}/tidy_photo.log
    fi
}

