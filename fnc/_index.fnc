
function _index() {
    local indexDir=${DIST_DIR}/index
    local tmpDir=${indexDir}/tmp
    local indexHTML=${indexDir}/index.html
    local imagesDir=${indexDir}/images
    local moviesDir=${indexDir}/movies
#    local thumbnailDir=${indexDir}/images/thumbnail
#    local mediumImgDir=${indexDir}/images/medium

    [ -d ${indexDir} ] && {
        rm -rf ${imagesDir} ${moviesDir} ${tmpDir} ${indexHTML}
    }

    mkdir -p ${imagesDir}
    mkdir -p ${moviesDir}
#    mkdir -p ${thumbnailDir}
#    mkdir -p ${mediumImgDir}

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
            mv lazysizes.min.js lib/js
            rm -rf .git
        )
    }

    # export HTML
    [ ! -f ${indexDir}/index.html ] && {
        css="<link type=\"text/css\" rel=\"stylesheet\" href=\"lib/css/lightgallery.min.css\" />"
        lazy="<script src=\"lib/js/lazysizes.min.js\"></script>"
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

        } > ${indexHTML}
    }

    mkdir -p ${tmpDir}/data
    STASH_IFS=${IFS}; IFS=$'\n'
    for line in $(cat ${ORIG_FILES_UNIQUE} | cut -d, -f 1,2,5); do
        local hash=${line%%,*}
        local file=$(echo ${line} | cut -d, -f 2)
        local dateTime=${line##*,}
        local filename=${dateTime:0:8}_${hash}.${file##*.}
        printf "[$(basename "${file}") => ${filename:0:20}..] "

        # label='2011.03.14'
        label="${dateTime:0:4}.${dateTime:4:2}.${dateTime:6:2}"

        # create date(label) img
        [ ! -f "${tmpDir}/${label}.png" ] && {
            convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
                -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" "${tmpDir}/${label}.png"
            printf "(${label})"
        }

        # copy image/video file
        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            ffmpeg -i "${BASE_DIR}/${file}" -ss 0 -vframes 1 -f image2 \
                    "${tmpDir}/data/${filename}.jpg"  > /dev/null 2>&1
            cp "${BASE_DIR}/${file}" "${moviesDir}/${filename}"
        else
            cp "${BASE_DIR}/${file}" "${tmpDir}/data/${filename}"
        fi
        printf ', copy'

        # html
        local thumbnailFile="${imagesDir}/thumbnail/${filename}"
        local mediumImgFile="${imagesDir}/medium/${filename}"

        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
            local movieCount=$(
                find ${moviesDir} -type f -maxdepth 1 | \
                    grep -v -e '^.*\.txt$' | wc -l | tr -d ' '
            )
            hiddenTag="<div style=\"display:none;\" id=\"video${movieCount}\">"
            hiddenTag="${hiddenTag}<video class=\"lg-video-object lg-html5\" controls preload=\"none\">"
            hiddenTag="${hiddenTag}<source src=\"${moviesDir##*index/}/${filename}\" type=\"video/mp4\">"
            hiddenTag="${hiddenTag}Your browser does not support HTML5 video."
            hiddenTag="${hiddenTag}</video>"
            hiddenTag="${hiddenTag}</div>"
            gsed -i -e "/^<\!\-\- hidden video div \-\->$/i ${hiddenTag}" ${indexDir}/index.html

            imgTag="<a data-poster=\"${mediumImgFile##*index/}.jpg\" data-sub-html=\"video caption1\" data-html=\"#video${movieCount}\" style=\"width: 16.667%\">"
            imgTag="${imgTag}<img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}.jpg\" style=\"width: 100%\">"
            imgTag="${imgTag}</a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
        else
            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"width: 16.667%\"><img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
        fi
        printf ', html'
        printf ', done\n'
    done
    IFS=${STASH_IFS}

    printf 'mogrify fuzz ...'
    mogrify +page -fuzz 10% -trim "${tmpDir}/data/*"
    cp -r ${tmpDir}/data ${tmpDir}/thumbnail
    printf 'done\n'

    # thumbnail
    printf 'thumbnail: mogrify resize ...'
    mogrify -define jpeg:size=240x240 -resize 240x240^ "${tmpDir}/thumbnail/*"
    printf 'done\n'
    printf 'thumbnail: mogrify crop ...'
    mogrify -gravity center -crop 240x240+0+0 "${tmpDir}/thumbnail/*"
    printf 'done\n'
#    convert -compose over -gravity southeast -geometry +10+10
#             "${tmpDir}/data/*" "${tmpDir}/${label}.png" "${thumbnailDir}"
    mv "${tmpDir}/thumbnail" "${imagesDir}/thumbnail"

    # medium
    printf 'medium: mogrify resize ...'
    mogrify -define jpeg:size=1280x720 -resize 1280x720> "${tmpDir}/data/*"
    printf 'done\n'
    mv "${tmpDir}/data" "${imagesDir}/medium"

    # cleanup
    rm -rf ${tmpDir}

#    function _getImgFilename() {
#        local file="$1"
#        local exifdate=$(
#            exiftool -time:all -s -S -d %Y%m%d "${file}" | \
#                grep -E '^[0-9]{8}$' | \
#                grep -v '0000:00:00 00:00:00' | sort | head -n 1
#        )
#        hash=$(md5sum "${file}" | cut -d ' ' -f 1)
#        local imgFileName=${exifdate}_${hash}."${file##*.}"
#        echo ${imgFileName}
#    }
#
#    # $1: in file
#    # $2: out file
#    function _create_thumbnail() {
#        local inFile="$1"
#        local outFile="$2"
#
#        # label='2011.03.14'
#        local outFilename=$(basename ${outFile})
#        label="${outFilename:0:4}.${outFilename:4:2}.${outFilename:6:2}"
#
#        # create date(label) img
#        [ ! -f "${tmpDir}/${label}.png" ] && {
#            printf "(${label})"
#            convert -size 100x100 -gravity center -font 'Bookman-Demi' -fill '#fff' -trim \
#                -background 'rgba(0,0,0,0,0)' -pointsize 12 label:"${label}" "${tmpDir}/${label}.png"
#        }
#
#        # for movie file
#        if [[ "${inFile}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
#
#            # capture thumbnail to ${tmpDir}
#            ffmpeg -i "${inFile}" -ss 0 -vframes 1 -f image2 \
#                    ${workDir}/${outFilename}  > /dev/null 2>&1
#
#            # fuzz, resize, crop, composit
#            convert "${workDir}/${outFilename}" +page -fuzz 10% -trim - | \
#                convert - -define jpeg:size=240x240 -resize 240x240^ - | \
#                convert - -gravity center -crop 240x240+0+0 - | \
#                composite - -compose over -gravity southeast -geometry +10+10 \
#                    "${tmpDir}/${label}.png" -
#                composite - -compose over -gravity center -geometry +0+0 \
#                    ${SELF}/images/play-button-60x60.png \
#                    "${thumbnailDir}/${outFilename}"
#
#        # for picture file
#        else
#            # fuzz, resize, crop, composit
#            convert "${inFile}" +page -fuzz 10% -trim - | \
#                convert - -define jpeg:size=240x240 -resize 240x240^ - | \
#                convert - -gravity center -crop 240x240+0+0 - | \
#                composite - -compose over -gravity southeast -geometry +10+10 \
#                    "${tmpDir}/${label}.png" "${thumbnailDir}/${outFilename}"
#        fi
#
#    }
#
#    # $1: in file
#    # $2: out file
#    function _create_medium_image() {
#        convert "${1}" +page -fuzz 10% -trim - | \
#            convert - -define jpeg:size="1280x720>" \
#                    -resize "1280x720>" "$2"
#    }

#    # work in sub shell
#    find -E ${DATA_DIR} -type f -regex "^.*\.${EXT}$" | sort | \
#        while IFS=$'\n' read file; do
#
#        # fix ${file}
#        [ ${file:0:1} != '/' ] && file="/${file}"
#        [ -d "${file}" ] && continue
#
#        # set filename
#        local filename=$(_getImgFilename "${file}")
#        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
#            filename=${filename}.jpg
#        fi
#        local thumbnailFile="${thumbnailDir}/${filename}"
#        local mediumImgFile="${mediumImgDir}/${filename}"
#
#        printf "[$(basename "${file}") => ${filename:0:20}..] "
#
#        #resume
#        ([ -f "${thumbnailFile}" ] || [ -f "${thumbnailFile}.jpg" ]) && \
#            ([ -f "${mediumImgFile}" ] || [ -f "${mediumImgFile}.jpg" ]) && {
#                printf "skip\n"
#                continue
#            }
#
#        # broken check
#        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
#            set +e
#            ffprobe "${file}" > /dev/null 2>&1
#            if [ $? -ne 0 ]; then
#                printf "file is broken.\n"
#                echo "${file##*dist/}",${filename} >> ${moviesDir}/broken/brokens.txt
#                cp "${file}" "${moviesDir}/broken/${filename%.*}"
#                continue
#            else
#                echo "${file##*dist/},${filename}" >> "${moviesDir}/movies.txt"
#                cp "${file}" "${moviesDir}/${filename%.*}"
#            fi
#            set -e
#        fi
#
#        local workDir="${tmpDir}/${filename}"
#        mkdir -p "${workDir}"
#
#        _create_thumbnail "${file}" "${thumbnailFile}" "${workDir}"
#        printf 'thumbnail'
#
#        _create_medium_image "${file}" "${mediumImgFile}" "${workDir}"
#        printf ', medium'
#
#        rm -rf "${workDir}"
#
#        # html
#        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then
#            local movieCount=$(
#                find ${moviesDir} -type f -maxdepth 1 | \
#                    grep -v -e '^.*\.txt$' | wc -l | tr -d ' '
#            )
#            hiddenTag="<div style=\"display:none;\" id=\"video${movieCount}\">"
#            hiddenTag="${hiddenTag}<video class=\"lg-video-object lg-html5\" controls preload=\"none\">"
#            hiddenTag="${hiddenTag}<source src=\"${moviesDir##*index/}/${filename%.*}\" type=\"video/mp4\">"
#            hiddenTag="${hiddenTag}Your browser does not support HTML5 video."
#            hiddenTag="${hiddenTag}</video>"
#            hiddenTag="${hiddenTag}</div>"
#            gsed -i -e "/^<\!\-\- hidden video div \-\->$/i ${hiddenTag}" ${indexDir}/index.html
#
#            imgTag="<a data-poster=\"${mediumImgFile##*index/}\" data-sub-html=\"video caption1\" data-html=\"#video${movieCount}\" style=\"width: 16.667%\">"
##            imgTag="${imgTag}<img src=\"${thumbnailFile##*index/}\" style=\"width: 100%\">"
#            imgTag="${imgTag}<img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}\" style=\"width: 100%\">"
#            imgTag="${imgTag}</a>"
#            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
#        else
##            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"width: 16.667%\"><img src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
#            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"width: 16.667%\"><img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
#            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" ${indexDir}/index.html
#        fi
#        printf ', html'
#        printf ', done\n'
#    done

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
}
