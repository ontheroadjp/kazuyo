
function _export_kml() {
    [ -d ${DIST_DIR}/kml ] && rm ${DIST_DIR}/kml
    mkdir -p ${DIST_DIR}/kml
    exiftool -p ${SELF}/lib/kml.fmt -r ${PHOTO_DATA_DIR} > ${DIST_DIR}/kml/kml.xml
}
