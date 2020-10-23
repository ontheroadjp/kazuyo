
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
            mkdir ${indexDir}/lib

            # lightgallery.js
            git init
            git config core.sparsecheckout true
            {
                echo "dist"
                echo "demo/js/lg-video.min.js"
            } > .git/info/sparse-checkout
            git remote add origin https://github.com/sachinchoolur/lightgallery.js
            git pull origin master
            mv dist/* lib
            mv demo/js/* lib/js
            rm -rf .git dist demo

            # lazysizes
            git init
            git config core.sparsecheckout true
            echo "lazysizes.min.js" > .git/info/sparse-checkout
            git remote add origin https://github.com/aFarkas/lazysizes
            git pull origin master
            mkdir -p lib/js
            mv lazysizes.min.js lib/js
            rm -rf .git
        )
    }

    # export HTML
    [ ! -f ${indexDir}/index.html ] && {
        css="<link type=\"text/css\" rel=\"stylesheet\" href=\"lib/dist/css/lightgallery.min.css\" />"
        lazy="<script src=\"lib/js/lazysizes/lazysizes.min.js\"></script>"
        lg="<script src=\"lib/js/lightgallery.min.js\"></script>"
        vp="<script src=\"lib/js/lg-video.min.js\"></script>"
        style="<style>.lg-backdrop.in { opacity: 0.85; }</style>"
        {
            echo "<html><body style=\"margin: 0px\"><head>${css}${style}</head><body>"
            echo "<!-- hidden video div -->"
            echo "<div id=\"lightgallery\" style=\"display: flex; flex-wrap: wrap\">"
            echo "<!-- image file -->"
            echo "</div>"
            echo "${lazy}${lg}${vp}"
            echo "<script>"
            echo "lightGallery(document.getElementById('lightgallery'));"
            echo "</script>"
            echo "</body></html>"

        } > ${indexDir}/index.html
    }

    function _getImgFilename() {
        local file="$1"
        local exifdate=$(
            exiftool -time:all -s -S -d %Y%m%d "${file}" | \
                grep -E '^[0-9]{8}$' | \
                grep -v '0000:00:00 00:00:00' | sort | head -n 1
        )
        hash=$(md5sum "${file}" | cut -d ' ' -f 1)
        local imgFileName=${exifdate}_${hash}."${file##*.}"
        echo ${imgFileName}
    }

    # $1: in file
    # $2: out file
    function _create_thumbnail() {
        local inFile="$1"
        local outFile="$2"

        # label='2011.03.14'
        local outFilename=$(basename ${outFile})
        label="${outFilename:0:4}.${outFilename:4:2}.${outFilename:6:2}"

        # for movie file
        if [[ "${inFile}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then

            # capture thumbnail to ${tmpDir}
            ffmpeg -i "${inFile}" \
                    -ss 0 \
                    -vframes 1 \
                    -f image2 \
                    ${workDir}/${outFilename}  > /dev/null 2>&1

            # fuzz photo
            convert "${workDir}/${outFilename}" +page -fuzz 10% -trim "${workDir}/${outFilename}.fuzz"
#            convert "${workDir}/${outFilename}" -define jpeg:size=240x240 +page -fuzz 10% -trim "${workDir}/${outFilename}.fuzz"

        # for picture file
        else
            # fuzz photo
            convert "${inFile}" +page -fuzz 10% -trim "${workDir}/${outFilename}.fuzz"
#            convert "${inFile}" -define jpeg:size=240x240 +page -fuzz 10% -trim "${workDir}/${outFilename}.fuzz"
        fi

        # resize photo
#        convert -resize 240x240^ "${workDir}/${outFilename}.fuzz" "${workDir}/${outFilename}.thumb.resize"
        convert -define jpeg:size=240x240 -resize 240x240^ "${workDir}/${outFilename}.fuzz" "${workDir}/${outFilename}.thumb.resize"

        # crop photo
        convert "${workDir}/${outFilename}.thumb.resize" -gravity center -crop 240x240+0+0  "${workDir}/${outFilename}.thumb.crop"

        # create date(label) img
#        convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
#            -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" "${workDir}/date_image.png"
        [ ! -f "${tmpDir}/${label}.png" ] && {
            printf "(${label})"
            convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
                -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" "${tmpDir}/${label}.png"
        }

        # composite photo
#        composite -compose over -gravity southeast -geometry +10+10 \
#            "${workDir}/date_image.png" "${workDir}/${outFilename}.thumb.crop" "${thumbnailDir}/${outFilename}"
        composite -compose over -gravity southeast -geometry +10+10 \
            "${tmpDir}/${label}.png" "${workDir}/${outFilename}.thumb.crop" "${thumbnailDir}/${outFilename}"

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
#        local inFile=$1
        local inFile=${workDir}/$(basename $2).fuzz
#        convert -resize "1280x720>" "${inFile}" "$2"
        convert -define jpeg:size="1280x720>" -resize "1280x720>" "${inFile}" "$2"
    }

    # work in sub shell
    local ext="(JPG|jpg|jpeg|PNG|png|TIFF|TIF|tiff|tif|CR2|NEF|ARW|MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)"
    find -E ${PHOTO_DATA_DIR} -type f -regex "^.*\.${EXT}$" | sort | \
        while IFS=$'\n' read file; do

        # fix ${file}
        [ ${file:0:1} != '/' ] && file="/${file}"
        [ -d "${file}" ] && continue

        # set filename
        local filename=$(_getImgFilename "${file}")
        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            filename=${filename}.jpg
        fi
        local thumbnailFile="${thumbnailDir}/${filename}"
        local mediumImgFile="${mediumImgDir}/${filename}"

        printf "[$(basename "${file}") => ${filename:0:20}..] "

        #resume
        ([ -f "${thumbnailFile}" ] || [ -f "${thumbnailFile}.jpg" ]) && \
            ([ -f "${mediumImgFile}" ] || [ -f "${mediumImgFile}.jpg" ]) && {
                printf "skip\n"
                continue
            }

        # broken check
        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            set +e
            ffprobe "${file}" > /dev/null 2>&1
            if [ $? -ne 0 ]; then
                printf "file is broken.\n"
                echo "${file##*dist/}",${filename} >> ${movieDir}/broken/brokens.txt
                cp "${file}" "${movieDir}/broken/${filename%.*}"
                continue
            else
                echo "${file##*dist/},${filename}" >> "${movieDir}/movies.txt"
                cp "${file}" "${movieDir}/${filename%.*}"
            fi
            set -e
        fi

        local workDir="${tmpDir}/${filename}"
        mkdir -p "${workDir}"

        _create_thumbnail "${file}" "${thumbnailFile}" "${workDir}"
        printf 'thumbnail'

        _create_medium_image "${file}" "${mediumImgFile}" "${workDir}"
        printf ', medium'

        rm -rf "${workDir}"

        # html
        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
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
#            imgTag="${imgTag}<img src=\"${thumbnailFile##*index/}\" style=\"width: 100%\">"
            imgTag="${imgTag}<img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}\" style=\"width: 100%\">"
            imgTag="${imgTag}</a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
        else
#            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"width: 16.667%\"><img src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"width: 16.667%\"><img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
        fi
        printf ', html'

        #clean
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
