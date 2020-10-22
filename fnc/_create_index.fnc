
function _create_index() {
    local indexDir=${DIST_DIR}/index
    local tmpDir=${indexDir}/tmp
    local thumbnailDir=${indexDir}/images/thumbnail
    local mediumImgDir=${indexDir}/images/medium
    local movieDir=${indexDir}/movies

#    mkdir -p ${indexDir}/{tmp,L,M,S}
    mkdir -p ${indexDir}/tmp
    mkdir -p ${thumbnailDir}
    mkdir -p ${mediumImgDir}
    mkdir -p ${movieDir}/broken

    [ ! -d ${indexDir}/lib ] && {
        (
            cd ${indexDir}
            git clone https://github.com/sachinchoolur/lightgallery.js lib
        )
    }

    # export HTML
    [ ! -f ${indexDir}/index.html ] && {
        css="<link type=\"text/css\" rel=\"stylesheet\" href=\"lib/dist/css/lightgallery.min.css\" />"
        lg="<script src=\"lib/dist/js/lightgallery.min.js\"></script>"
        vp="<script src=\"lib/demo/js/lg-video.min.js\"></script>"
        {
            echo "<html><body style="margin: 0px"><head>${css}${lg}${vp}</head><body>"
            echo "<!-- hidden video div -->"
            echo "<div id=\"lightgallery\" style=\"display: flex; flex-wrap: wrap\">"
            echo "<!-- image file -->"
            echo "</div>"
            echo "<script>"
            echo "lightGallery(document.getElementById('lightgallery'));"
            echo "</script>"
            echo "</body></html>"

        } > ${indexDir}/index.html
    }

    function _getImgFilename() {
        local file=$1
        local exifdate=$(
            exiftool -time:all -s -S -d %Y%m%d ${file} | \
                grep -v '0000:00:00 00:00:00' | sort | head -n 1
        )
        hash=$(md5sum ${file} | cut -d ' ' -f 1)
        local imgFileName=${exifdate}_${hash}.${file##*.}
        echo ${imgFileName}
    }

    # $1: in file
    # $2: out file
    function _create_thumbnail() {
        local inFile=$1
        local outFile=$2

        # label='2011.03.14'
        local outFilename=$(basename ${outFile})
        label="${outFilename:0:4}.${outFilename:4:2}.${outFilename:6:2}"

        # for movie file
        if [[ ${inFile} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then

            # capture thumbnail to ${tmpDir}
            ffmpeg -i ${inFile} \
                    -ss 0 \
                    -vframes 1 \
                    -f image2 \
                    ${tmpDir}/${outFilename}  > /dev/null 2>&1

            # fuzz photo
            convert "${tmpDir}/${outFilename}" +page -fuzz 10% -trim "${tmpDir}/${outFilename}.fuzz"

        # for picture file
        else
            # fuzz photo
            convert "${inFile}" +page -fuzz 10% -trim "${tmpDir}/${outFilename}.fuzz"
        fi

        # resize photo
        convert -resize 240x240^ "${tmpDir}/${outFilename}.fuzz" "${tmpDir}/${outFilename}.thumb.resize"

        # crop photo
        convert "${tmpDir}/${outFilename}.thumb.resize" -gravity center -crop 240x240+0+0  "${tmpDir}/${outFilename}.thumb.crop"

        # create date img
        convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
            -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" "${tmpDir}/date_image.png"

        # composite photo
        composite -compose over -gravity southeast -geometry +10+10 \
            "${tmpDir}/date_image.png" "${tmpDir}/${outFilename}.thumb.crop" "${thumbnailDir}/${outFilename}"

        # composite play button
        if [[ ${outFilename} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4).jpg$ ]]; then
            composite \
                -compose over \
                -gravity center \
                -geometry +0+0 \
                ${SELF}/images/play-button-60x60.png \
                "${thumbnailDir}/${outFilename}" \
                "${thumbnailDir}/${outFilename}"
        fi
    }

    # $1: in file
    # $2: out file
    function _create_medium_image() {
        #local inFile=$1
        local inFile=${tmpDir}/$(basename $2).fuzz
        convert -resize "1280x720>" "${inFile}" "$2"
    }

    local ext="(JPG|jpg|jpeg|PNG|png|TIFF|TIF|tiff|tif|CR2|NEF|ARW|MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)"
    for file in $(find -E ${PHOTO_DATA_DIR} -type f -regex "^.*\.${ext}$" | sort); do
        [ -d ${file} ] && continue

        # set filename
        local filename=$(_getImgFilename ${file})
        if [[ ${file} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            filename=${filename}.jpg
        fi
        local thumbnailFile="${thumbnailDir}/${filename}"
        local mediumImgFile="${mediumImgDir}/${filename}"

        printf "[$(basename ${file}) => ${filename:0:20}..] "

        #resume
        [ -f "${thumbnailFile}" ] || [ -f "${thumbnailFile}.jpg" ] || \
            [ -f "${mediumImgFile}" ] || [ -f "${mediumImgFile}.jpg" ] && {
                printf "skip\n"
                continue
            }

        # broken check
        if [[ ${file} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            set +e
            ffprobe "${file}" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                printf "file is broken.\n"
                echo ${file##*dist/},${filename} >> ${movieDir}/broken/brokens.txt
                cp ${file} ${movieDir}/broken/${filename%.*}
                continue
            else
                echo ${file##*dist/},${filename} >> ${movieDir}/movies.txt
                cp ${file} ${movieDir}/${filename%.*}
            fi
            set -e
        fi

        _create_thumbnail ${file} ${thumbnailFile}
        printf 'thumbnail'

        _create_medium_image ${file} ${mediumImgFile}
        printf ', medium'

        # html
        if [[ ${file} =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            local movieCount=$(
                find ${movieDir} -type f -maxdepth 1 | \
                    grep -v -e '^.*\.txt$' | wc -l | tr -d ' '
            )
            hiddenTag="<div style=\"display:none;\" id=\"video${movieCount}\">"
            hiddenTag="${hiddenTag}<video class=\"lg-video-object lg-html5\" controls preload=\"none\">"
            hiddenTag="${hiddenTag}<source src=\"${movieDir##*index/}/${filename%.*}\" type=\"video/mp4\">"
            hiddenTag="${hiddenTag}Your browser does not support HTML5 video."
            hiddenTag="${hiddenTag}</video>"
            hiddenTag="${hiddenTag}</div>"
            gsed -i -e "/^<\!\-\- hidden video div \-\->$/i ${hiddenTag}" ${indexDir}/index.html

            imgTag="<a data-poster=\"${mediumImgFile##*index/}\" data-sub-html=\"video caption1\" data-html=\"#video${movieCount}\" style=\"width: 16.667%\">"
            imgTag="${imgTag}<img src=\"${thumbnailFile##*index/}\" style=\"width: 100%\">"
            imgTag="${imgTag}</a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
        else
            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"width: 16.667%\"><img src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
        fi
        printf ', html'

        #clean
        rm ${tmpDir}/*
        printf ', done\n'
    done

#    # generate index files
#    printf 'create montage L ...'
#    montage $(find ${thumbnailDir} -type f -name "*.jpg" | sort) -tile 4x4 -geometry +0+0 ${indexDir}/L/index_l.jpg
#    printf 'done\n'
#
#    printf 'create montage M ...'
#    montage $(find ${thumbnailDir} -type f -name "*.jpg" | sort) -tile 6x6 -geometry +0+0 ${indexDir}/M/index_m.jpg
#    printf 'done\n'
#
#    printf 'create montage S ...'
#    montage $(find ${thumbnailDir} -type f -name "*.jpg" | sort) -tile 8x8 -geometry +0+0 ${indexDir}/S/index_s.jpg
#    printf 'done\n'

    # cleanup
    rm -rf ${tmpDir}
    _log "all done."
}
