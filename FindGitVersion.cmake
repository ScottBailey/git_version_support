# FindGitVersion.cmake
# Copyright 2023 Scott Bailey
# MIT License - please see `https://opensource.org/license/mit/` for more information.
#
# This file contains the following functions:
#   generate_version_file(path_to_git_repo, pound_define_prefix, output_file, target [, targets...])
#   generate_version_install_config(target git_project_path)    # Depends on CPACK_PACKAGE_VERSION_MAJOR for setting major version.

cmake_minimum_required(VERSION 3.20)

find_package(Git QUIET)
if( NOT Git_FOUND)
  if(BUILD_CUSTOMER_RELEASE)
    message(FATAL_ERROR "Customer Release builds (BUILD_CUSTOMER_RELEASE 1) require git.")
  else()
    message(AUTHOR_WARNING "This build is being generated WITHOUT git.")
  endif()
endif()

find_file(support_script GitVersionScript.cmake
  HINTS ${CMAKE_CURRENT_LIST_DIR}
  DOC   "Support script for generating Git version information."
)
if(NOT support_script)
  message(FATAL_ERROR "Failed to find GitVersionScript.cmake in ${CMAKE_CURRENT_LIST_DIR}.")
endif()


function(generate_version_file
    path_     # Path to the git repo.
    name_     # Name to use as a prefix for the `#define`s
    file_     # Generated version file.
    # Dependent files should follow.
  )

  # This is a fictious file we will add to our target.
  set(pretend_file "${file_}.gen_versions_file")

  # Create a single target for all the generated version files:
#  cmake_path(GET file_ FILENAME filename)
#  set(GIT_VERSION_TARGET "${path_}/${filename}")
#  set(GIT_VERSION_TARGET "${path_}/${filename}" PARENT_SCOPE)
#  if(TARGET ${GIT_VERSION_TARGET})
#    # do nothing
#  else()
#    add_custom_target(${GIT_VERSION_TARGET} ALL
#      DEPENDS ${pretend_file}  # Ficticious target.
#    )
#  endif()

  add_custom_command(
    OUTPUT
      ${pretend_file}  # Ficticious dependency to force execution.
      ${file_}         # Actual output target!
    COMMENT "Generating ${file_}"
    COMMAND ${CMAKE_COMMAND}
      -DVERSION_PATH=${path_}
      -DVERSION_NAME=${name_}
      -DVERSION_FILE=${file_}
      -P ${support_script}
  )

  # Add an empty file.
  file(WRITE ${file_} "")
  set_property(SOURCE ${file_} PROPERTY GENERATED TRUE)


  # Add dependant files:
   # we test for size(${ARGN}) == 0 and error out.
  if( NOT ARGN )
    message(FATAL_ERROR "Version file ${file_} requires at least one dependant file.")
  endif()

  # Break the path into parent path and filename
  cmake_path(GET file_  PARENT_PATH parent_path_)
  cmake_path(GET file_  FILENAME filename_)

  # Show a status message ONLY once.
  set(message_var VERSION_SUPPORT_${file_}_MESSAGED)
  set(${message_var} 1 CACHE BOOL "internal")
  if( ${${message_var}} )
    set( message_user 1)
    set( ${message_var} 0 CACHE INTERNAL "internal" FORCE)
  else()
    set( message_user 0)
  endif()
  if( message_user )
    message(STATUS "Automatic version info:")
    message(STATUS "  file: ${filename_}")
    message(STATUS "  adding include directory: ${parent_path_}")
  endif()

  if( message_user )
    message(STATUS "  dependant files:")
  endif()
  foreach( src_ ${ARGN} )
    if(NOT EXISTS ${src_})
      set( ${message_var} 1 CACHE INTERNAL "internal" FORCE)
      message(FATAL_ERROR "generate_version_file():  dependor can't be found: `${src_}`, you may need to add the full path.")
    endif()
    set_property(SOURCE ${src_} APPEND PROPERTY OBJECT_DEPENDS ${file_} )

    # Set INCLUDE_DIRECTORIES property on a per file basis:
    get_property( compile_flags_ SOURCE ${src_} PROPERTY COMPILE_FLAGS)
    if(MSVC)
      set( compile_flags_ "${compile_flags_} /I\"${parent_path_}\"")
    else()
      set( compile_flags_ "${compile_flags_} -I\"${parent_path_}\"")
    endif()
    set_property(SOURCE ${src_} PROPERTY COMPILE_FLAGS ${compile_flags_} )

    if( message_user )
      message(STATUS "    ${src_}")
    endif()
  endforeach()

endfunction() # generate_version_file



find_file(install_support_script GitVersionInstallScript.cmake
  HINTS ${CMAKE_CURRENT_LIST_DIR}
  DOC   "Support script for generating Git version install information."
)
if(NOT install_support_script)
  message(FATAL_ERROR "Failed to find GitVersionInstallScript.cmake in ${CMAKE_CURRENT_LIST_DIR}.")
endif()


set(FindGitVersion_cmake_dir "${CMAKE_CURRENT_LIST_DIR}")
set(FindGitVersion_cmake_dir "${CMAKE_CURRENT_LIST_DIR}" PARENT_SCOPE)


function(generate_version_install_config
    target          # A target for dependancy
    project_root    # The project_root for determining git info
  )

  set(file_name version_install_config.cmake)
  set(config_file_in "${FindGitVersion_cmake_dir}/${file_name}.in")
  set(config_file_out "${CMAKE_BINARY_DIR}/${file_name}")

  add_custom_target(build_version_install_config_target ALL
    # generate the version config at build time so we get the correct version numbers every time
    COMMAND ${CMAKE_COMMAND}
      -DMAJOR_VERSION="${CPACK_PACKAGE_VERSION_MAJOR}"
      -DCONFIG_FILE_IN="${config_file_in}"
      -DCONFIG_FILE_OUT="${config_file_out}"
      -DPROJECT_DIR="${project_root}"
      -DPACKAGE_NAME="${CPACK_PACKAGE_NAME}"
      -DBUILD_CUSTOMER_RELEASE=${BUILD_CUSTOMER_RELEASE}
    -P "${install_support_script}"
    )

  add_dependencies(build_version_install_config_target ${target})
  set(CPACK_PROJECT_CONFIG_FILE "${config_file_out}")
  set(CPACK_PROJECT_CONFIG_FILE "${config_file_out}" PARENT_SCOPE)

endfunction() # generate_version_install_config
