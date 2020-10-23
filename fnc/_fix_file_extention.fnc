

function _fix_file_extention() {
    cat ${REPORT_DIR}/original.txt | cut -d ',' -f 2 | sort | uniq -c | sort -r

#    find -E ${PHOTO_DATA_DIR} -type f -regex "^.*\.${EXT}$" | sort | \
#        while IFS=$'\n' read file; do
#
#    done

    # $1: MIME type
    function _getCorrectFileExtention() {
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

    cat ${REPORT_DIR}/original.txt | sort | while read line; do
        file=$(echo ${line} | cut -d ',' -f 3)
        ext=${file##*.}
        mime=$(echo ${line} | cut -d ',' -f 2)
        correctExt=$(_getCorrectFileExtention ${mime})
        [ ${correctExt} = 'unknown' ] && _failed 'unknown ext: ${mime}'
        [ ${correctExt} != ${ext} ] && {
            echo "$(basename ${file}) - ${ext} - ${correctExt}"
        }
    done
}

