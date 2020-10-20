#!/bin/bash

function _create_index() {
    local indexDir=${DIST_DIR}/index
    local tmpDir=${indexDir}/tmp
    local thumbnailDir=${indexDir}/thumbnail

    [ -d ${indexDir} ] && {
        echo "[index]: err ${indexDir} is already exist."
        exit 1
    }

    mkdir -p ${indexDir}/{tmp,L,M,S} ${thumbnailDir}

    echo '<html><body><div id="album" style="display: flex; flex-wrap: wrap">' > ${indexDir}/index.html

    function _getNewFile() {
        local file=${1}
        local exifdate=$(exiftool -time:all -s -S -d %Y%m%d ${file} | sort | head -n 1)
        #local to=${tmpDir}/${exifdate}.png
        local to=${tmpDir}/${exifdate}.${file##*.}
        if [ ! -f ${to} ]; then
            echo ${to}
        else
            for i in $(seq 9999); do
                seqTo=${to%.*}-${i}.${to##*.}
                [ ! -f ${seqTo} ] && {
                    echo ${seqTo}
                    break
                }
            done
        fi
    }

    for file in $(find -E ${PHOTO_DATA_DIR} -type f -regex "^.*\.${EXT}$" | sort); do
        [ -d ${file} ] && continue

        local newFile=$(_getNewFile ${file})
        cp ${file} ${newFile}
        local filename=$(basename ${newFile})
        file=${newFile}

#        label='2011.03.14'
        label="${filename:0:4}.${filename:4:2}.${filename:6:2}"

        printf "[${filename}] "

        # fuzz photo
        printf 'fuzz'
        convert ${file} +page -fuzz 10% -trim ${tmpDir}/${filename}.fuzz

        # resize photo
        printf ', resize'
        convert -resize 240x240^ ${tmpDir}/${filename}.fuzz ${tmpDir}/${filename}.resize

        # crop photo
        printf ', crop'
        convert ${tmpDir}/${filename}.resize -gravity center -crop 240x240+0+0  ${tmpDir}/${filename}.crop

        # create date img
        printf ", date(${label})"
        convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
            -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" ${tmpDir}/kazuyo_date_image.png

        # composite photo
        printf ', composit'
        composite -compose over -gravity southeast -geometry +10+10 \
            ${tmpDir}/kazuyo_date_image.png ${tmpDir}/${filename}.crop ${thumbnailDir}/${filename}

        # html
        printf ', html'
        echo '<img src="thumbnail/'${filename}'" style="width: 16.6667%">' >> ${indexDir}/index.html

        printf ', done\n'
    done

    echo '</div></body></html>' >> ${indexDir}/index.html

    # generate index files
    printf 'create montage L ...'
    montage $(find ${thumbnailDir} -type f -name "*.jpg" | sort) -tile 4x4 -geometry +0+0 ${indexDir}/L/index_l.jpg
    printf 'done\n'
    printf 'create montage M ...'
    montage $(find ${thumbnailDir} -type f -name "*.jpg" | sort) -tile 6x6 -geometry +0+0 ${indexDir}/M/index_m.jpg
    printf 'done\n'
    printf 'create montage S ...'
    montage $(find ${thumbnailDir} -type f -name "*.jpg" | sort) -tile 8x8 -geometry +0+0 ${indexDir}/S/index_s.jpg
    printf 'done\n'

    # cleanup
    rm -rf ${tmpDir}
    echo "all done."
}
