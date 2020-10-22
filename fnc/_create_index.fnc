
function _create_index() {
    local indexDir=${DIST_DIR}/index
    local tmpDir=${indexDir}/tmp
    local thumbnailDir=${indexDir}/thumbnail

#    [ -d ${indexDir} ] && {
#        _failed "index dir is already exist."
#    }

    mkdir -p ${indexDir}/{tmp,L,M,S} ${thumbnailDir}

    [ ! -f ${indexDir}/index.html ] && {
        echo '<html><body><div id="album" style="display: flex; flex-wrap: wrap">' > ${indexDir}/index.html
    }

    function _getNewFilename() {
        local file=$1
        local exifdate=$(
                    exiftool -time:all -s -S -d %Y%m%d ${file} | \
                        grep -v '0000:00:00 00:00:00' | \
                        sort | \
                        head -n 1
                )
        hash=$(md5sum ${file} | cut -d ' ' -f 1)
        local to="${thumbnailDir}/${exifdate}_${hash}.${file##*.}"
        echo ${to}
#        if [ ! -f "${to}" ] && [ ! -f "${to}.jpg" ]; then
#            echo ${to}
#        else
#            for i in $(seq 9999); do
#                seqTo="${to%.*}-${i}.${to##*.}"
#                if [ ! -f "${seqTo}" ] && [ ! -f "${seqTo}.jpg" ]; then
#                    echo ${seqTo}
#                    break
#                fi
#            done
#        fi
    }

    local ext="(JPG|jpg|jpeg|PNG|png|TIFF|TIF|tiff|tif|CR2|NEF|ARW|MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)"
    for file in $(find -E ${PHOTO_DATA_DIR} -type f -regex "^.*\.${ext}$" | sort); do
        [ -d ${file} ] && continue

        printf "[$(basename ${file}) => "

        # new filename
        # photo file: ${tmpDir}/yyyymmdd.ext
        # movie file: ${tmpDir}/yyyy.mmdd.ext.jpg

        # ${newFile} = ${thumbnailDir}/${exifdate}_${hash}.${file##*.}
        local newFile="$(_getNewFilename ${file})"

        [ -f "${newFile}" ] || [ -f "${newFile}.jpg" ] && {
            printf "skip]\n"
            continue
        }

        # for movie file
        if [[ ${file} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then

            newFile=${newFile}.jpg

            # broken check
            set +e
            ffprobe "${file}" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                printf "$(basename ${file})] file is broken.\n"
                echo ${file},$(basename ${newFile}) >> ${indexDir}/broken.txt
                continue
            fi
            set -e

            # capture thumbnail to ${tmpDir}
            ffmpeg -i ${file} \
                    -ss 0 \
                    -vframes 1 \
                    -f image2 \
                    -s 480x480 \
                    ${newFile}  > /dev/null 2>&1

        # for picture file
        else
            cp "${file}" "${newFile}"
        fi

        local filename=$(basename "${newFile}")
        file="${newFile}"

        # label='2011.03.14'
        label="${filename:0:4}.${filename:4:2}.${filename:6:2}"

        printf "${filename}] "

        # fuzz photo
        printf 'fuzz'
        convert "${file}" +page -fuzz 10% -trim "${tmpDir}/${filename}.fuzz"

        # resize photo
        printf ', resize'
        convert -resize 240x240^ "${tmpDir}/${filename}.fuzz" "${tmpDir}/${filename}.resize"

        # crop photo
        printf ', crop'
        convert "${tmpDir}/${filename}.resize" -gravity center -crop 240x240+0+0  "${tmpDir}/${filename}.crop"

        # create date img
        printf ", ${label}"
        convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
            -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" "${tmpDir}/date_image.png"

        # composite photo
        printf ', composit'
        composite -compose over -gravity southeast -geometry +10+10 \
            "${tmpDir}/date_image.png" "${tmpDir}/${filename}.crop" "${thumbnailDir}/${filename}"

        # composite play button
        if [[ ${filename} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4).jpg$ ]]; then
            composite \
                -compose over \
                -gravity center \
                -geometry +0+0 \
                ${SELF}/images/play-button-60x60.png \
                "${thumbnailDir}/${filename}" \
                "${thumbnailDir}/${filename}"
        fi

        # html
        printf ', html'
        echo '<img src="thumbnail/'${filename}'" style="width: 16.6667%">' >> ${indexDir}/index.html

        #clean
        rm ${tmpDir}/*
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
    _log "all done."
}
