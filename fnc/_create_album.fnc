
function _create_album() {
    if ! _is_exist thumbsup; then
        echo "Install thumbsup first." 1>&2
        echo "Run: npm install -g thumbsup" 1>&2
        exit 1
    fi
    thumbsup --input ${PHOTO_DATA_DIR} --output ${DIST_DIR}/album --theme flow \
        --include-raw-photos true \
        --embed-exif true \
        --cleanup true
}

