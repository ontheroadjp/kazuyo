#!/bin/bash

# no param
function _replace_space_to_underbar_within_filename() {
    _log "[INFO] Replace space char to underbar within filename.\n" ${LOG_INFO}
    find -E ${BASE_DIR} -type f -regex "^.*\.${EXT}$" | while read file; do
        mv "${file}" $(echo "${file}" | sed 's/ /_/g')
    done
}

# (md5) -------------------------------------------------

# $1: md5 (= $(md5sum some_file.ext))
function _get_original_filename() {
    echo $(echo $1 | cut -d ' ' -f 2)
}

# $1: md5 (= $(md5sum some_file.ext))
function _get_hash_value() {
    echo $(echo $1 | cut -d ' ' -f 1)
}

# $1: md5 (= $(md5sum some_file.ext))
function _get_hash_filename() {
#    hash=$(_get_hash_value "$1")
#    original_filename=$(_get_original_filename "$1")
#    echo ${hash}.${original_filename##*.}
    original_filename=$(_get_original_filename "$1")
    echo $(_get_hash_value "$1").${original_filename##*.}
}


