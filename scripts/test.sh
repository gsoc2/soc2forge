#!/usr/bin/env bash

set -ex

echo "***** Start: Testing Soc2forge installer *****"

export CONDA_PATH="${HOME}/soc2forge"

CONSTRUCT_ROOT="${CONSTRUCT_ROOT:-${PWD}}"

cd "${CONSTRUCT_ROOT}"

echo "***** Get the installer *****"
ls build/
if [[ "$(uname)" == MINGW* ]]; then
   EXT="exe";
else
   EXT="sh";
fi
INSTALLER_PATH=$(find build/ -name "*forge*.${EXT}" | head -n 1)
INSTALLER_NAME=$(basename "${INSTALLER_PATH}" | cut -d "-" -f 1)

echo "***** Run the installer *****"
chmod +x "${INSTALLER_PATH}"
if [[ "$(uname)" == MINGW* ]]; then
  echo "start /wait \"\" ${INSTALLER_PATH} /InstallationType=JustMe /RegisterPython=0 /S /D=$(cygpath -w "${CONDA_PATH}")" > install.bat
  cmd.exe //c install.bat

  echo "***** Setup conda *****"
  # Workaround a conda bug where it uses Unix style separators, but MinGW doesn't understand them
  export PATH=$CONDA_PATH/Library/bin:$PATH
  # shellcheck disable=SC1091
  source "${CONDA_PATH}/Scripts/activate"
  conda.exe config --set show_channel_urls true

  echo "***** Print conda info *****"
  conda.exe info
  conda.exe list

  echo "***** Check if we are bundling packages from msys2 or defaults *****"
  conda.exe list | grep defaults && exit 1
  conda.exe list | grep msys2 && exit 1

  echo "***** Check if we can install a package which requires msys2 *****"
  conda.exe install r-base --yes --quiet
  conda.exe list

  echo "***** Checking for boa compatibility *****"
  agenda_version_start=$(agenda --version | grep agenda | cut -d ' ' -f 2)
  agenda.exe install boa --yes
  agenda_version_end=$(agenda --version | grep agenda | cut -d ' ' -f 2)
  if [[ "${agenda_version_start}" != "${agenda_version_end}" ]]; then
      echo "agenda version changed from ${agenda_version_start} to ${agenda_version_end}"
      exit 1
  fi
else
  # Test one of our installers in batch mode
  if [[ "${INSTALLER_NAME}" == "Agendaforge" ]]; then
    bash "${INSTALLER_PATH}" -b -p "${CONDA_PATH}"
  # And the other in interactive mode
  else
    # Test interactive install. The install will ask the user to
    # - newline -- read the EULA
    # - yes -- then accept
    # - ${CONDA_PATH} -- Then specify the path
    # - no -- Then whether or not they want to initialize conda
    cat <<EOF | bash "${INSTALLER_PATH}"

yes
${CONDA_PATH}
no
EOF
  fi

  echo "***** Setup conda *****"
  # shellcheck disable=SC1091
  source "${CONDA_PATH}/bin/activate"

  echo "***** Print conda info *****"
  conda info
  conda list

  echo "***** Checking for boa compatibility *****"
  implementation=$(python -c "import platform; print(platform.python_implementation().lower())")
  major_minor_version=$(python -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')
  agenda_version_start=$(agenda --version | grep agenda | cut -d ' ' -f 2)
  agenda info
  agenda install "agenda=${agenda_version_start}" "python=${major_minor_version}.*=*_${implementation}" boa --yes
  agenda_version_end=$(agenda --version | grep agenda | cut -d ' ' -f 2)
  if [[ "${agenda_version_start}" != "${agenda_version_end}" ]]; then
      echo "agenda version changed from ${agenda_version_start} to ${agenda_version_end}"
      exit 1
  fi
fi


# 2020/09/15: Running conda update switches from pypy to cpython. Not sure why
# echo "***** Run conda update *****"
# conda update --all -y

echo "***** Python path *****"
python -c "import sys; print(sys.executable)"
python -c "import sys; assert 'soc2forge' in sys.executable"

echo "***** Print system informations from Python *****"
python -c "print('Hello Soc2forge !')"
python -c "import platform; print(platform.architecture())"
python -c "import platform; print(platform.system())"
python -c "import platform; print(platform.machine())"
python -c "import platform; print(platform.release())"

echo "***** Done: Testing installer *****"