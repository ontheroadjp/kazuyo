

function _mime2ext() {

    # $1: MIME type
    function _getMimeExt() {
        case $1 in
            'image/bmp' ) echo "bmp" ;;
            'image/fif' ) echo "fif" ;;
            'image/gif' ) echo "gif" ;;
            'image/gif' ) echo "ifm" ;;
            'image/ief' ) echo "ief" ;;
            'image/jpeg' ) echo "jpg" ;;
            'image/png' ) echo "png" ;;
            'image/svg+xml' ) echo "svg" ;;
            'image/tiff' ) echo "tiff" ;;
            'image/vasa' ) echo "mcf" ;;
            'image/vnd.rn-realpix' ) echo "rp" ;;
            'image/vnd.wap.wbmp' ) echo "wbmp" ;;
            'image/x-cmu-raster' ) echo "ras" ;;
            'image/x-freehand' ) echo "fh" ;;
            'image/x-icon' ) echo "ico" ;;
            'image/x-jps' ) echo "jps" ;;
            'image/x-portable-anymap' ) echo "pnm" ;;
            'image/x-portable-bitmap' ) echo "pbm" ;;
            'image/x-portable-graymap' ) echo "pgm" ;;
            'image/x-portable-pixmap' ) echo "ppm" ;;
            'image/x-rgb' ) echo "rgb" ;;
            'image/x-xbitmap' ) echo "xbm" ;;
            'image/x-xpixmap' ) echo "xpm" ;;
            'image/x-xres' ) echo "swx" ;;
            'image/x-xwindowdump' ) echo "xwd" ;;
            'video/mp4' ) echo "mp4" ;;
            'video/3gpp' ) echo "3gp" ;;
            'video/3gpp2' ) echo "3g2" ;;
            'video/mpeg' ) echo "mpe" ;;
            'video/quicktime' ) echo "mov" ;;
            'video/ogg' ) echo "ogg" ;;
            'video/vnd.mpegurl' ) echo "mxu" ;;
            'video/vnd.rn-realvideo' ) echo "rv" ;;
            'video/vnd.vivo' ) echo "viv" ;;
            'video/webm' ) echo "webm" ;;
            'video/x-bamba' ) echo "vba" ;;
            'video/x-mng' ) echo "mng" ;;
            'video/x-ms-asf' ) echo "asf" ;;
            'video/x-ms-wm' ) echo "wm" ;;
            'video/x-ms-wmv' ) echo "wmv" ;;
            'video/x-ms-wmx' ) echo "wmx" ;;
            'video/x-msvideo' ) echo "avi" ;;
            'video/x-qmsys' ) echo "qm" ;;
            'video/x-sgi-movie' ) echo "movie" ;;
            'video/x-tango' ) echo "tgo" ;;
            'video/x-vif' ) echo "vif" ;;
            * ) echo "unknown" ;;
        esac
    }

    [ -f "${REPORT_DIR}/mime2ext.txt" ] && rm ${REPORT_DIR}/mime2ext.txt

    STASH_IFS=${IFS}; IFS=$'\n'
    local isProcess=false
    for line in $(cat ${ORIG_FILES} | cut -d, -f 2,3); do
        file=${line%,*}
        ext=${file##*.}
        mime=${line#*,}

        [ -z ${mime} ] && continue

        mimeExt=$(_getMimeExt "${mime}")
        [ ${mimeExt} = 'unknown' ] && _failed "unknown ext: ${file} ${mime}"

        [ ${mimeExt} != ${ext} ] && {
            fixedFile=${file%.*}.${mimeExt}
#            mv ${BASE_DIR}/${file} ${BASE_DIR}/${fixedFile}
            echo "${file},${mime},${mimeExt},${fixedFile}" >> ${REPORT_DIR}/mime2ext.txt
            isProcess=true
        }
    done
    IFS=${STASH_IFS}

    if ! ${isProcess}; then echo "no file processd" > ${REPORT_DIR}/mime2ext.txt; fi
    _log $(cat ${REPORT_DIR}/mime2ext.txt)
}

