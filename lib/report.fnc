#!/bin/bash

# $1: report text
function _log() {
    printf "$1" >> ${DIST_DIR}/repost.txt
}
