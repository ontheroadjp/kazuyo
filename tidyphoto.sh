#!/bin/bash

SELF=$(cd $(dirname $0); pwd);
DIFF_RESULT_DIR="${SELF}/diff_result";

DUPLICATE_SUFFIX="duplicate";
#DIFF_RESULT_FILENAME="duplicate_in_$(basename $(pwd)).txt";

function _remove_duplicate_suffix() {
    for file in $(find . -type f | grep ${DUPLICATE_SUFFIX}$); do
        mv "${file}" ${file%.*};
    done
}

function _param_check() {
    if [ $# != 1 ]; then
        echo "must be one parameter.";
        exit 1;
    fi

    if [ ! -e $@ ]; then
        echo "$@ does not exist."
        exit 1;
    fi
}

function _create_exif_file() {
    #extentions="(JPG|jpg|jpeg|PNG|png|TIFF|TIF|tiff|tif|CR2|NEF|ARW|MOV|mov)"
    extentions="(JPG|jpg|jpeg|TIF|TIFF|tiff|tif|CR2|NEF|ARW|MOV|mov)"
    for image_file in $(find $@ -type f | grep -E "^.*\.${extentions}$"); do
        if [ ! -e "${image_file}.exif" ]; then
            exiftool -s ${image_file} > ${image_file}.exif
            sed -i "" -e '/^FileName/d' ${image_file}.exif
            sed -i "" -e '/^Directory/d' ${image_file}.exif
            sed -i "" -e '/^FileType/d' ${image_file}.exif
            sed -i "" -e '/^FileSize/d' ${image_file}.exif
            sed -i "" -e '/^FileTypeExtension/d' ${image_file}.exif
            sed -i "" -e '/^FileModifyDate/d' ${image_file}.exif
            sed -i "" -e '/^FileAccessDate/d' ${image_file}.exif
            sed -i "" -e '/^FileInodeChangeDate/d' ${image_file}.exif
            sed -i "" -e '/^FilePermissions/d' ${image_file}.exif
            sed -i "" -e '/^Orientation/d' ${image_file}.exif
            sed -i "" -e '/^Compression/d' ${image_file}.exif
            echo "create: ${image_file}.exif"
        fi
    done
}

function _diff() {
    echo "---------------------------------------"
    echo "compare: $(basename $1)"
    echo "---------------------------------------"
    for exif_file in $(find $(dirname $1) -type f | grep ".exif$"); do
        if [ "$1" = "${exif_file}" ]; then
            echo "continue."
            continue;
        fi

        echo "with: $(basename ${exif_file})"
        if diff -sq "$1" ${exif_file} > /dev/null 2>&1; then
            _duplicater "$1" ${exif_file}
        fi
    done
}

function _duplicater() {
    echo "duplicate(exif)!"
    echo "$(basename $1) is the same as $(basename ${exif_file})" \
        >> $(dirname ${exif_file})/duplicate_$(basename $(dirname ${exif_file})).txt;
    mv "$1" "$1.${DUPLICATE_SUFFIX}"
    mv "${1%.*}" "${1%.*}.${DUPLICATE_SUFFIX}"
    #_diff_file_size "$1" "${exif_file}"
}

function _diff_file_size() {
    echo "${1%.*}";
    echo "${2%.*}";
    size_a=$(wc -c < ${1%.*}); echo "size_a: $size_a";
    size_b=$(wc -c < ${2%.*}); echo "size_b: $size_b";
    if [ ${size_a} != ${size_b} ]; then
        echo "(file size only)"
        mv $2 $2.file_size
    fi
}

function _replace_filename_space_to_underbar() {
    for file in $(find $@ -type f -name "* *"); do
        mv ${file} $(echo ${file} | sed -e 's/ /_/g');
    done
}

function _remove_duplicate_suffix() {
    for file in $(find . -type f -name "*.${DUPLICATE_SUFFIX}"); do
        mv ${file} ${file%.*}
    done
}

function _prepare() {
    #mkdir -p ${DIFF_RESULT_DIR}/duplicate_images;
    #: > ${DIFF_RESULT_DIR}/${DIFF_RESULT_FILENAME};

    _replace_filename_space_to_underbar $@;
    _create_exif_file $@;
}

function _clean() {
    rm $(find $@ -type f -name "*.exif");
}

function _main() {
    _param_check $@ && {
        _prepare $@;
        if [ -d $@ ]; then
            for item in $(find $@ -type f | grep ".exif"); do
                _diff ${item};
            done
        else
            _diff $@;
        fi
        #_clean $@;
    }
}

_main $@

exit 0;

# 20150529 png is the duplicated
# 20150529_23-21-35.PNG
# 20150529_23-22-03.PNG
