DESCRIPTION = "Lemonbeat Python library"
LICENSE = "CLOSED"

inherit python3-dir

SRC_URI += " \
    git://stash.dss.husqvarnagroup.com/scm/sg/lemonbeat-python.git;protocol=https \
"

PR = "r0"

SRCREV = "aea59ad0b95b97aa97403381842ac33b1e4d56a1"

S = "${WORKDIR}/git"

RDEPENDS_${PN} += " \
    lsdl-serializer-lib \
    python3-core \
    python3-fcntl \
    python3-threading \
    python3-xml \
"

do_install() {
    install -d ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat
    install -m 0755 ${S}/lemonbeat/configuration.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/defines.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/device_description.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/device.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/firmware.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/gateway.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/__init__.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/lsdl_serializer.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/message.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/partner.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
    install -m 0755 ${S}/lemonbeat/types.py ${D}${PYTHON_SITEPACKAGES_DIR}/lemonbeat/
}

FILES_${PN} += " \
    ${PYTHON_SITEPACKAGES_DIR}/lemonbeat/* \
"