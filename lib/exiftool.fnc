#!/bin/bash

# $1: single file
function _guess_create_date() {
    local exif_tags=('DateTimeOriginal' 'CreateDate' 'ModifyDate' 'FileModifyDate')

    local exif_date
    local exif_date_tag
    for tag in ${exif_tags[@]}; do
        [ ! -z ${exif_date} ] && continue
        exif_date=$(exiftool "-${tag}" -s -S ${1})
        exif_date_tag=${tag}
    done

    echo "${exif_date_tag},${exif_date}"
}

#function _create_exif_file() {
#    for file in $(find $@ -type f | grep -E "^.*\.${EXT}$"); do
#        _log "[EXIF] Create EXIF file: " ${LOG_DEBUG}
#        if [ ! -e "${file}.exif" ]; then
#            exiftool -s ${file} > ${file}.exif
#            sed -i "" -e '/^FileName/d' ${file}.exif
#            sed -i "" -e '/^Directory/d' ${file}.exif
#            sed -i "" -e '/^FileType/d' ${file}.exif
#            sed -i "" -e '/^FileSize/d' ${file}.exif
#            sed -i "" -e '/^FileTypeExtension/d' ${file}.exif
#            sed -i "" -e '/^FileModifyDate/d' ${file}.exif
#            sed -i "" -e '/^FileAccessDate/d' ${file}.exif
#            sed -i "" -e '/^FileInodeChangeDate/d' ${file}.exif
#            sed -i "" -e '/^FilePermissions/d' ${file}.exif
#            sed -i "" -e '/^Orientation/d' ${file}.exif
#            sed -i "" -e '/^Compression/d' ${file}.exif
#            echo "create: ${file}.exif"
#        fi
#        _log "${file}.exif\n" ${LOG_DEBUG}
#    done
#}

#function _remove_exiffiles() {
#    rm $(find $@ -type f -name "*.exif");
#}

