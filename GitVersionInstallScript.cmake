# GitVersionInstallScript.cmake
# Copyright 2023 Scott Bailey
# MIT License - please see `https://opensource.org/license/mit/` for more information.
#
# Inputs:
#   -DMAJOR_VERSION="${CPACK_PACKAGE_VERSION_MAJOR}"
#   -DCONFIG_FILE_IN="${config_file_in}"
#   -DCONFIG_FILE_OUT="${config_file_out}"
#   -DPROJECT_DIR="${project_root}"
#   -DPACKAGE_NAME="${CPACK_PACKAGE_NAME}"
#   -DBUILD_CUSTOMER_RELEASE=${BUILD_CUSTOMER_RELEASE}


include("${CMAKE_CURRENT_LIST_DIR}/GitVersionSupport.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/date.cmake")

# get the data
GitVersionInfo( "${PROJECT_DIR}" url branch tag full_hash short_hash commit_time clean dirty_reason)


expand_date(${commit_time} year doy)
year2("${year}" year2)
doy3("${doy}" doy3)


set(GENERATED_OPTION_MAJOR "${MAJOR_VERSION}")
set(GENERATED_OPTION_MINOR "${year2}")
set(GENERATED_OPTION_PATCH "${doy3}")
set(GENERATED_OPTION_HASH  "${short_hash}")

set(GENERATED_OPTION_PACKAGE_NAME ${PACKAGE_NAME})
set(GENERATED_OPTION_VEXTRA "")
if(NOT BUILD_CUSTOMER_RELEASE)
  string(APPEND GENERATED_OPTION_VEXTRA "-engineering-only")
endif()
if(NOT clean)
  string(APPEND GENERATED_OPTION_VEXTRA "-dirty")
endif()

configure_file(${CONFIG_FILE_IN} ${CONFIG_FILE_OUT} @ONLY)
