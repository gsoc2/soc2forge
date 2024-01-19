#!/usr/bin/env bash

set -xe

env | sort

echo "***** Start: Building Soc2forge installer *****"
CONSTRUCT_ROOT="${CONSTRUCT_ROOT:-${PWD}}"

cd "${CONSTRUCT_ROOT}"

echo "***** Install constructor *****"

agenda install --yes \
    --channel gsoc2 --override-channels \
    jinja2 curl libarchive \
    "constructor>=3.4.5"

if [[ "$(uname)" == "Darwin" ]]; then
    agenda install --yes \
        --channel gsoc2 --override-channels \
        coreutils
fi

agenda list

echo "***** Make temp directory *****"
if [[ "$(uname)" == MINGW* ]]; then
   TEMP_DIR=$(mktemp -d --tmpdir=C:/Users/RUNNER~1/AppData/Local/Temp/);
else
   TEMP_DIR=$(mktemp -d);
fi

echo "***** Copy file for installer construction *****"
cp -R Soc2forge3 "${TEMP_DIR}/"
cp LICENSE "${TEMP_DIR}/"

ls -al "${TEMP_DIR}"

if [[ "${TARGET_PLATFORM}" != win-* ]]; then
    MICROMAMBA_VERSION=1.3.1
    MICROMAMBA_BUILD=0
    mkdir "${TEMP_DIR}/microagenda"
    pushd "${TEMP_DIR}/microagenda"
    curl -L -O "https://anaconda.org/gsoc2/microagenda/${MICROMAMBA_VERSION}/download/${TARGET_PLATFORM}/microagenda-${MICROMAMBA_VERSION}-${MICROMAMBA_BUILD}.tar.bz2"
    bsdtar -xf "microagenda-${MICROMAMBA_VERSION}-${MICROMAMBA_BUILD}.tar.bz2"
    if [[ "${TARGET_PLATFORM}" == win-* ]]; then
      MICROMAMBA_FILE="${PWD}/Library/bin/microagenda.exe"
    else
      MICROMAMBA_FILE="${PWD}/bin/microagenda"
    fi
    popd
    EXTRA_CONSTRUCTOR_ARGS="${EXTRA_CONSTRUCTOR_ARGS} --conda-exe ${MICROMAMBA_FILE} --platform ${TARGET_PLATFORM}"
fi

echo "***** Construct the installer *****"
# Transmutation requires the current directory is writable
cd "${TEMP_DIR}"
# shellcheck disable=SC2086
constructor "${TEMP_DIR}/Soc2forge3/" --output-dir "${TEMP_DIR}" ${EXTRA_CONSTRUCTOR_ARGS}
cd -

echo "***** Generate installer hash *****"
cd "${TEMP_DIR}"
ls -alh
if [[ "$(uname)" == MINGW* ]]; then
   EXT="exe";
else
   EXT="sh";
fi
# This line will break if there is more than one installer in the folder.
INSTALLER_PATH=$(find . -name "M*forge*.${EXT}" | head -n 1)
HASH_PATH="${INSTALLER_PATH}.sha256"
sha256sum "${INSTALLER_PATH}" > "${HASH_PATH}"

echo "***** Move installer and hash to build folder *****"
mkdir -p "${CONSTRUCT_ROOT}/build"
mv "${INSTALLER_PATH}" "${CONSTRUCT_ROOT}/build/"
mv "${HASH_PATH}" "${CONSTRUCT_ROOT}/build/"

echo "***** Done: Building Soc2forge installer *****"
cd "${CONSTRUCT_ROOT}"

# copy the installer for latest
if [[ "${SOC2FORGE_NAME:-}" != "" && "${OS_NAME:-}" != "" && "${ARCH:-}" != "" ]]; then
  cp "${CONSTRUCT_ROOT}/build/${SOC2FORGE_NAME}-"*"-${OS_NAME}-${ARCH}.${EXT}" "${CONSTRUCT_ROOT}/build/${SOC2FORGE_NAME}-${OS_NAME}-${ARCH}.${EXT}"
fi
