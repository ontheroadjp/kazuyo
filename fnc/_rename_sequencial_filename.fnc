function _rename_sequential_filename() {
    local current_dir=''
    local digits=6
    local prefix="kazuyo_"

    STASH_IFS=${IFS}; IFS=$'\n'
    for file in $(find -E ${BASE_DIR} -type f -regex "^.*\.${EXT}$" | sort); do
        if [ "$(dirname ${file})" != "${current_dir}" ]; then
            current_dir=$(dirname ${file})
            counter=1
        fi
        renban=$(printf "%0${digits}d\n" "${counter}")
        renban_file="$(dirname ${file})/${prefix}${renban}.${file##*.}"

        [ ${file} = ${renban_file} ] && continue
        [ -f ${renban_file} ] && {
            echo "stopped."
            echo "already exist: ${renban_file}"
            exit 1
        }

        echo "[mv] $(basename ${file}) ==> $(basename ${renban_file})"
        mv -n "${file}" "${renban_file}"
        ((counter++))
    done
    IFS=${STASH_IFS}
}
