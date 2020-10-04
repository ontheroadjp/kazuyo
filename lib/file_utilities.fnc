#!/bin/bash

# $1: file list
function _filename_formatter() {
    local files=($@)

    STASH_IFS=${IFS}; IFS=$'\n'
    for file in ${files[@]}; do
        _replace_space_to_underbar ${file}
        _replace_double_to_single_within_filename $(echo ${file} | sed 's/ /_/g')
    done
    IFS=${STASH_IFS}
}

# $1: file
function _replace_space_to_underbar() {
    mv -n "${1}" $(echo "${1}" | sed -e 's/ /_/g')
}

# $1: file
function _replace_double_to_single_within_filename() {
    local double_big_letters="ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"
    local double_small_letters="ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏpｑｒｓｔｕｖｗｘｙｚ"
    local single_big_letters="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local single_small_letters="abcdefghijklmnopqrstuvwxyz"
    local double_numbers="０１２３４５６７８９"
    local single_numbers="0123456789"
    local double_marks="　／\［\］：；！＠＃＄％＾＆＊（）"
    local single_marks=" \/\[\]:;!@#$%^&*()"

    new_file=$(echo "${1}" | \
        sed -e "y/${double_big_letters}/${single_big_letters}/" | \
        sed -e "y/${double_small_letters}/${single_small_letters}/" | \
        sed -e "y/${double_numbers}/${single_numbers}/" | \
        sed -e "y/${double_marks}/${single_marks}/"
    )
    mv -n "${1}" "${new_file}"
}

# (md5) -------------------------------------------------

# $1: md5 (= $(md5sum some_file.ext))
function _get_md5_filename() {
    echo $(echo $1 | cut -d ' ' -f 3)
}

# $1: md5 (= $(md5sum some_file.ext))
function _get_hash_value() {
    echo $(echo $1 | cut -d ' ' -f 1)
}

# $1: md5 $(md5sum some_file.ext)), $2: file extension
function _get_hash_filename() {
#    hash=$(_get_hash_value "$1")
#    original_filename=$(_get_md5_filename "$1")
#    echo ${hash}.${original_filename##*.}
    local filename=$(_get_md5_filename "$1")
    echo $(_get_hash_value "$1").${filename##*.}
}


