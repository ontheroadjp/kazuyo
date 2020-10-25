
function _index() {
    local indexDir="${DIST_DIR}"/index
    local tmpDir="${indexDir}"/tmp
    local indexHTML="${indexDir}"/index.html
    local imagesDir="${indexDir}"/images
    local moviesDir="${indexDir}"/movies
#    local thumbnailDir="${indexDir}"/images/thumbnail
#    local mediumImgDir="${indexDir}"/images/medium

    [ -d "${indexDir}" ] && {
        rm -rf "${imagesDir}" "${moviesDir}" "${tmpDir}" "${indexHTML}"
    }

    mkdir -p "${imagesDir}"
    mkdir -p "${moviesDir}"
#    mkdir -p "${thumbnailDir}"
#    mkdir -p "${mediumImgDir}"


    [ ! -d "${indexDir}"/lib ] && {
        (
            cd "${indexDir}"
            mkdir "${indexDir}"/lib

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
    [ ! -f "${indexDir}"/index.html ] && {
        css="<link type=\"text/css\" rel=\"stylesheet\" href=\"lib/css/lightgallery.min.css\" />"
        lazy="<script src=\"lib/js/lazysizes.min.js\"></script>"
        lg="<script src=\"lib/js/lightgallery.min.js\"></script>"
        vp="<script src=\"lib/js/lg-video.min.js\"></script>"
        style="<style>.lg-backdrop.in { opacity: 0.85; }</style>"
        {
            echo "<html><body style=\"margin: 0px\"><head>${css}${style}</head><body>"
            echo "<!-- hidden video div -->"
#            echo "<div id=\"lightgallery\" style=\"display: flex; flex-wrap: wrap\">"
            echo "<!-- image file -->"
            echo "</div>"
            echo "${lazy}${lg}${vp}"
            echo "<script>"
            echo "<!-- script -->"
#            echo "lightGallery(document.getElementById('lightgallery'));"
            echo "</script>"
            echo "</body></html>"
        } > "${indexHTML}"
    }

    # for copy
#    mkdir -p "${tmpDir}"/data
    mkdir -p "${tmpDir}"/{video,picture}
    local hasVideo=false

    # for HTML tags
    local garellyCount=1
    local garellyTag=''
    local prevDate=0

    STASH_IFS=${IFS}; IFS=$'\n'
    for line in $( cat "${ORIG_FILES_UNIQUE}" \
                    | sort -k 5 -t ',' | cut -d, -f 1,2,5 \
                ); do

        local hash=${line%%,*}
        local file=$(echo ${line} | cut -d, -f 2)
        local dateTime=${line##*,}
        local filename=${dateTime:0:8}_${hash}.${file##*.}
        printf "[${file##*/} => ${filename:0:20}..] "

        # for HTML tags
        local thumbnailFile="${imagesDir}"/thumbnail/"${filename}"
        local mediumImgFile="${imagesDir}"/medium/"${filename}"

        # HTML (Header)
        [ "${prevDate}" -ne ${dateTime:0:6} ] && {
            [ ${prevDate} -ne 0 ] && garellyTag="</div>"

            # Date header
            style="padding:10px; background:#f5f5f5;"
            style="${style}position:sticky; top:0; z-index:${garellyCount};"
            value="${dateTime:0:4}年${dateTime:4:2}月"
            garellyTag="${garellyTag}<div style=\"${style} \">${value}</div>"

            # img div
            id="lightgallery${garellyCount}"
            style="display: flex; flex-wrap: wrap"
            garellyTag="${garellyTag}<div id=\"${id}\" style=\"${style}\">"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${garellyTag}" \
                "${indexDir}"/index.html

            # Javascript
            scriptTag="lightGallery(document.getElementById(\"${id}\"));"
            id="lightgallery${garellyCount}"
            gsed -i -e "/^<\!\-\- script \-\->$/i ${scriptTag}" \
                "${indexDir}"/index.html

            prevDate=${dateTime:0:6}
            garellyCount=$(( ++garellyCount ))
        }

        # video
        if [[ "${file}" =~ ^.*\.(MOV|mov|AVI|avi|MPG|mpg|mpeg|mp4)$ ]]; then

            hasVideo=true

            # copy
#            ffmpeg -i "${BASE_DIR}/${file}" -ss 0 -vframes 1 -f image2 \
#                    "${tmpDir}/video/${filename}.jpg" > /dev/null 2>&1
            ffmpeg -i "${BASE_DIR}"/"${file}" -vf  "thumbnail" -frames:v 1 \
                    "${tmpDir}"/video/"${filename}".jpg > /dev/null 2>&1
            cp "${BASE_DIR}"/"${file}" "${moviesDir}"/"${filename}"

            # HTML tags
            local movieCount=$(
                find "${moviesDir}" -type f -maxdepth 1 | \
                    grep -v -e '^.*\.txt$' | wc -l | tr -d ' '
            )

            hiddenTag="<div style=\"display:none;\" id=\"video${movieCount}\">"
            hiddenTag="${hiddenTag}<video class=\"lg-video-object lg-html5\" controls preload=\"none\">"
            hiddenTag="${hiddenTag}<source src=\"${moviesDir##*index/}/${filename}\" type=\"video/mp4\">"
            hiddenTag="${hiddenTag}Your browser does not support HTML5 video."
            hiddenTag="${hiddenTag}</video>"
            hiddenTag="${hiddenTag}</div>"
            gsed -i -e "/^<\!\-\- hidden video div \-\->$/i ${hiddenTag}" "${indexDir}"/index.html

            imgTag="<a data-poster=\"${mediumImgFile##*index/}.jpg\" data-sub-html=\"video caption1\" data-html=\"#video${movieCount}\" style=\"margin: 1px; width: 14.0%\">"
            imgTag="${imgTag}<img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}.jpg\" style=\"width: 100%\">"
            imgTag="${imgTag}</a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" "${indexDir}"/index.html

        # Picture
        else
            # copy
            cp "${BASE_DIR}"/"${file}" "${tmpDir}"/picture/"${filename}"

            # HTML tags
            imgTag="<a href=\"${mediumImgFile##*index/}\" style=\"margin: 1px; width: 14.0%\"><img class=\"lazyload\" data-src=\"${thumbnailFile##*index/}\" style=\"width: 100%\"></a>"
            gsed -i -e "/^<\!\-\- image file \-\->$/i ${imgTag}" "${indexDir}"/index.html
        fi

        printf 'copy, html, done\n'
    done
    IFS=${STASH_IFS}

    # fuzz
    printf 'mogrify fuzz ...'
            mogrify +page -fuzz 10% -trim "${tmpDir}/picture/*"
            if ${hasVideo}; then
                mogrify -page +0+0 -fuzz 10% -trim "${tmpDir}/video/*"
            fi
    printf 'done\n'

            cp -r "${tmpDir}/picture" "${tmpDir}/thumbnail-picture"
            if ${hasVideo}; then
                cp -r "${tmpDir}/video" "${tmpDir}/thumbnail-video"
            fi

    # thumbnail
    printf 'thumbnail: mogrify resize and crop ...'
            mogrify -define jpeg:size=240x240 -resize 240x240^ \
                    -gravity center -crop 240x240+0+0 "${tmpDir}/thumbnail-picture/*"
            if ${hasVideo}; then
                mogrify -define jpeg:size=240x240 -resize 240x240^ \
                        -gravity center -crop 240x240+0+0 "${tmpDir}/thumbnail-video/*"
            fi
    printf 'done\n'

    printf 'thumbnail: mogrify date-label ...'
            # label='2011.03.14'
            label="${dateTime:0:4}.${dateTime:4:2}.${dateTime:6:2}"
            mogrify -gravity southeast -pointsize 22 -fill '#fff' \
                -annotate +10+10 ${label} "${tmpDir}/thumbnail-picture/*"
            if ${hasVideo}; then
                mogrify -gravity southeast -pointsize 22 -fill '#fff' \
                    -annotate +10+10 ${label} "${tmpDir}/thumbnail-video/*"
            fi
    printf 'done\n'

    if ${hasVideo}; then
        printf 'thumbnail: mogrify play-btn ...'
            mogrify -gravity center -pointsize 62 -fill '#fff' \
                -font "Font Awesome 5 Free-400" \
                -annotate +0+0 "" "${tmpDir}/thumbnail-video/*"
        printf 'done\n'
    fi

            mv "${tmpDir}"/thumbnail-picture "${imagesDir}"/thumbnail
            if ${hasVideo}; then
                mv "${tmpDir}"/thumbnail-video/* "${imagesDir}"/thumbnail
            fi

    # medium
    printf 'medium: mogrify resize ...'
            mogrify -define jpeg:size=1280x720 -resize 1280x720> "${tmpDir}/picture/*"
            if ${hasVideo}; then
                mogrify -define jpeg:size=1280x720 -resize 1280x720> "${tmpDir}/video/*"
            fi
    printf 'done\n'

            mv "${tmpDir}"/picture "${imagesDir}"/medium
            if ${hasVideo}; then
                mv "${tmpDir}"/video/* "${imagesDir}"/medium
            fi

    # cleanup
    rm -rf ${tmpDir}
}
