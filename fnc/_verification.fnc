function _count() {
    echo $(cat "$1" | wc -l)
}

function _compaier_line_count() {
    [ $1 -eq $2 ] && echo true || echo false
}

function _verify_result() {
    local ori=$(_count "${ORIG_FILES}")
    local ori_uni=$(_count "${ORIG_FILES_UNIQUE}")
    local ori_dup=$(_count "${ORIG_FILES_DUPLICATE}")
    local ori_bro=$(_count "${ORIG_FILES_BROKEN}")

    local org_status=$(
        _compaier_line_count ${ori} $(( ${ori_uni} + ${ori_dup} + ${ori_bro} ))
    )

    local mime_type_status=$(
        cat "${ORIG_FILES}" | cut -d, -f 3 | sort | uniq -c | sort -r \
        | awk -v ori_count=${ori} \
            '{sum += $1 }
            END{
                if(sum == ori_count){ print "OK" }
                else { print "NG" }
            }'
    )

    local mvResultStatus=$(
     if $(_compaier_line_count $(_count "${MV_RESULT_UNIQUE}") ${ori_uni}) \
        && $(_compaier_line_count $(_count "${MV_RESULT_DUPLICATE}") ${ori_dup}) \
        && $(_compaier_line_count $(_count "${MV_RESULT_BROKEN}") ${ori_bro}); then
        echo "OK"
    else
        echo "NG"
     fi
    )

    local duplicated_hash_status=$(
        cat "${ORIG_FILES}" \
            | awk -F ',' '$10 == "" { print $1 }' \
            | sort \
            | uniq -c \
            | awk '{ if( $1 != 1 ) print $0 }' \
            | awk -v dup_count=${ori_dup} \
                '{ sum += $1 }
                END{
                    if((sum - NR) == dup_count) { print "OK" }
                    else { print "NG", sum, NR, (sum-NR)}
                }'
        )

    local index_status=''
    [ -d "${DIST_DIR}"/index ] && {
        index_status=$(
            local thub_count=$(find "${DIST_DIR}"/index/images/thumbnail -type f | wc -l)
            local med_count=$(find "${DIST_DIR}"/index/images/medium -type f | wc -l)
            local mov_count=$(find "${DIST_DIR}"/index/movies -type f | wc -l)
            [ ${ori_uni} -eq ${thub_count} ] && [ ${ori_uni} -eq ${med_count} ] && {
                echo true
            } || {
                echo false
            }
        )
    }

    echo ${org_status},${mime_type_status},${mvResultStatus},${duplicated_hash_status},${index_status}
}

function _verify_checkup() {
    local st=$(_verify_result)
    [ ${st:0:13} = "true,OK,NG,OK" ] && echo true || echo false
}

function _verify_tidy() {
    local st=$(_verify_result)
    [ ${st:0:13} = "true,OK,OK,OK" ] && echo true || echo false
}

function _show_tidy_result() {
    local st=$(_verify_result)
    local org_status=$(echo ${st} | cut -d, -f 1)
    local mime_type_status=$(echo ${st} | cut -d, -f 2)
    local mvResultStatus=$(echo ${st} | cut -d, -f 3)
    local duplicated_hash_status=$(echo ${st} | cut -d, -f 4)
    local index_status=$(echo ${st} | cut -d, -f 5)

    echo "---------------------------------------------------------------"
    echo "Initialized on $(date)"
    echo "for .$(echo ${EXT} | sed 's/(//g' | sed 's/)//g' | sed 's/|/ \./g')"
    echo " in $2"
    echo "---------------------------------------------------------------"
    echo "[Original (${org_status})]"
    printf "%8d file(s) found.\n" $(_count "${ORIG_FILES}")
    printf "%8d file(s) in unique list.%s\n" $(_count "${ORIG_FILES_UNIQUE}")
    printf "%8d file(s) in duplicate list.\n" $(_count "${ORIG_FILES_DUPLICATE}")
    printf "%8d file(s) in broken list.\n" $(_count "${ORIG_FILES_BROKEN}")
    echo ""
    echo "[MIME Type (${mime_type_status})]"
    printf "%8d %s\n" $(cat "${ORIG_FILES}" | cut -d, -f 3 | sort | uniq -c | sort -r)
    echo ""
    echo "[mv/cp Result (${mvResultStatus})]"
    printf "%8d file(s) in unique list.\n" $(_count "${MV_RESULT_UNIQUE}")
    printf "%8d file(s) in duplicate list.\n" $(_count "${MV_RESULT_DUPLICATE}")
    printf "%8d file(s) in broken list.\n" $(_count "${MV_RESULT_BROKEN}")
    [ $(cat "${ORIG_FILES_DUPLICATE}" | wc -l) -ne 0 ] && {
        echo ""
        echo "[duplicated hash (${duplicated_hash_status})]"
        cat "${ORIG_FILES}" \
            | awk -F ',' '$10 == "" { print $1 }' \
            | sort \
            | uniq -c \
            | awk '{ if( $1 != 1 ) print $0 }' \
            | awk '{ sum+=$1 } END{ printf "%6s=%d, to unique(NR)=%d, to duplicate=%d\n", "all", sum, NR, sum - NR}' \
            | sort -r
        printf '%6s\n\n' "   (one file has moved into unique list and others into duplicate list.)"
        cat "${ORIG_FILES}" \
            | sort \
            | cut -d, -f 1 \
            | uniq -c \
            | awk '{ if( $1 != 1 ) printf "%6d files has %s\n", $1, $2 }' \
            | sort -r
    }
    echo ""
    [ -d "${DIST_DIR}"/index ] && {
        echo "[Index Result (${index_status})]"
        printf "%8d image(s) in thumbnail dir.\n" $(find "${DIST_DIR}"/index/images/thumbnail -type f | wc -l)
        printf "%8d image(s) in medium dir.\n" $(find "${DIST_DIR}"/index/images/medium -type f | wc -l)
        printf "%8d movie(s) in movies dir.\n" $(find "${DIST_DIR}"/index/movies -type f | wc -l)
        echo ""
    }
}
