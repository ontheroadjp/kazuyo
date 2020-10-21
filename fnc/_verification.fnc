function _count() {
    echo $(cat $1 | wc -l)
}

function _compaier_line_count() {
    [ $1 -eq $2 ] && echo "OK" || echo "NG"
}

function _verify_result() {
    local ori_uni=$(_count ${ORIG_FILES_UNIQUE})
    local ori_dup=$(_count ${ORIG_FILES_DUPLICATE})

    local org_status=$( _compaier_line_count \
        $(_count ${ORIG_FILES}) $(( ${ori_uni} + ${ori_dup} )))

    local hash_file_status=$( _compaier_line_count \
        $(_count ${HASH_FILES_UNIQUE}) ${ori_uni})

    local exif_date_status=$( _compaier_line_count \
        $(_count ${EXIF_DATE_UNIQUE}) ${ori_uni})
    [ ${exif_date_status} = "OK" ] && {
        exif_date_status=$(_compaier_line_count $(_count ${EXIF_DATE_DUPLICATE}) 0)
    }

    local mv_list_status=$( _compaier_line_count \
        $(_count ${MV_LIST_UNIQUE}) ${ori_uni})
    [ ${mv_list_status} = "OK" ] && {
        mv_list_status=$(_compaier_line_count $(_count ${MV_LIST_DUPLICATE}) ${ori_dup})
    }

    echo "${org_status},${hash_file_status},${exif_date_status},${mv_list_status}"
}

function _verify_checkup() {
    local st=$(_verify_result)
    [ ${st:0:8} = "OK,OK,OK" ] && echo 0 || echo 1
}

function _verify_tidy() {
    local st=$(_verify_result)
    [ ${st} = "OK,OK,OK,OK" ] && echo 0 || echo 1
}

function _show_tidy_result() {
    local st=$(_verify_result)
    local org_status=$(echo ${st} | cut -d ',' -f 1)
    local hash_file_status=$(echo ${st} | cut -d ',' -f 2)
    local exif_date_status=$(echo ${st} | cut -d ',' -f 3)
    local mv_list_status=$(echo ${st} | cut -d ',' -f 4)

    echo "---------------------------------------------------------------"
    echo "Initialized on $(date)"
    echo "for .$(echo ${EXT} | sed 's/(//g' | sed 's/)//g' | sed 's/|/ \./g')"
    echo " in $2"
    echo "---------------------------------------------------------------"
    echo "[Original (${org_status})]"
    printf "%8d files found.\n" $(_count ${ORIG_FILES})
    printf "%8d files in unique list.%s\n" $(_count ${ORIG_FILES_UNIQUE})
    printf "%8d files in duplicate list.\n" $(_count ${ORIG_FILES_DUPLICATE})
    echo ""
    echo "[Hash File (${hash_file_status})]"
    printf "%8d files in unique list.\n" $(_count ${HASH_FILES_UNIQUE})
    echo ""
    echo "[Exif Date (${exif_date_status})]"
    printf "%8d files found.\n" $(_count ${EXIF_DATE})
    printf "%8d files in unique list.\n" $(_count ${EXIF_DATE_UNIQUE})
    printf "%8d files in duplicate list.\n" $(_count ${EXIF_DATE_DUPLICATE})
    echo ""
    echo "[mv List (${mv_list_status})]"
    printf "%8d files in unique list.\n" $(_count ${MV_LIST_UNIQUE})
    printf "%8d files in duplicate list.\n" $(_count ${MV_LIST_DUPLICATE})
    [ $(cat ${ORIG_FILES_DUPLICATE} | wc -l) -ne 0 ] && {
        echo ""
        echo "[duplicated hash]"
        cat ${ORIG_FILES} \
            | sort \
            | cut -d ',' -f 1 \
            | uniq -c \
            | awk '{ if( $1 != 1 ) printf "%6d files has %s\n", $1, $2 }'
        echo " (one file has moved into unique list and others into duplicate list.)"
    }
}