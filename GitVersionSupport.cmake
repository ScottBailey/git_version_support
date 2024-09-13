# GitVersionSupport.cmake
# Copyright 2023 Scott Bailey
# MIT License - please see `https://opensource.org/license/mit/` for more information.


find_package(Git QUIET)

# Git version info for a given path.
function(GitVersionInfo
    # Input:
    path_           # Path to perform evaluation on.
    # Output
    url_            # Remote URL.
    branch_         # Branch.
    tag_            # Tag, if applicable, empty string otherwise.
    hash_           # Full hash.
    short_          # Short hash.
    commit_time_    # Commit date as unix time - not to be confused with author date.
    clean_          # True indicates this is a clean repo. In future, it should also indicate that the repo is NOT ahead of origin.
    dirty_reason_   # This is set to a reason when clean_ is False, otherwise it's an empty string.
  )

  if(NOT Git_FOUND)
    string(TIMESTAMP temp_date "%s" UTC)
    set(${url_}          "file://${path_}" PARENT_SCOPE)
    set(${branch_}       "N/A" PARENT_SCOPE)
    set(${tag_}          "N/A" PARENT_SCOPE)
    set(${hash_}         "N/A" PARENT_SCOPE)
    set(${short_}        "N/A" PARENT_SCOPE)
    set(${commit_time_}  ${TIMESTAMP} PARENT_SCOPE)
    set(${clean_}        False PARENT_SCOPE)
    set(${dirty_reason_} "${path_} is not a git repository." PARENT_SCOPE)
    return()
  endif()


  # URL
  execute_process(COMMAND ${GIT_EXECUTABLE} config --get remote.origin.url
    WORKING_DIRECTORY ${path_}
    OUTPUT_VARIABLE output_
    ERROR_QUIET
  )
  string(STRIP "${output_}" output_)
  set(${url_} ${output_} PARENT_SCOPE)

  # Branch
  execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --abbrev-ref HEAD
    WORKING_DIRECTORY ${path_}
    OUTPUT_VARIABLE output_
    ERROR_QUIET
  )
  string(STRIP "${output_}" output_)
  set(${branch_} ${output_} PARENT_SCOPE)

  # Tag
  execute_process(COMMAND ${GIT_EXECUTABLE} describe --exact-match --tags
    WORKING_DIRECTORY ${path_}
    OUTPUT_VARIABLE output_
    RESULT_VARIABLE result_
    ERROR_QUIET
  )
  string(STRIP "${output_}" output_)
  if(result_ EQUAL 0)
    set(${tag_} ${output_} PARENT_SCOPE)
  else()
    set(${tag_} "N/A" PARENT_SCOPE)
  endif()

  # Full Hash
  execute_process(COMMAND ${GIT_EXECUTABLE} log -n1 --format=%H
    WORKING_DIRECTORY ${path_}
    OUTPUT_VARIABLE output_
    ERROR_QUIET
  )
  string(STRIP "${output_}" output_)
  set(${hash_} ${output_} PARENT_SCOPE)

  # Short Hash
  execute_process(COMMAND ${GIT_EXECUTABLE} log -n1 --format=%h
    WORKING_DIRECTORY ${path_}
    OUTPUT_VARIABLE output_
    ERROR_QUIET
  )
  string(STRIP "${output_}" output_)
  set(${short_} ${output_} PARENT_SCOPE)

  # Commit Date
  execute_process(COMMAND ${GIT_EXECUTABLE} log -n1 --format=%ct
    WORKING_DIRECTORY ${path_}
    OUTPUT_VARIABLE output_
    ERROR_QUIET
  )
  string(STRIP "${output_}" output_)
  set(${commit_time_} "${output_}" PARENT_SCOPE)

  # Test for cleanliness
  execute_process(COMMAND ${GIT_EXECUTABLE} diff --quiet --exit-code
    WORKING_DIRECTORY ${path_}
    RESULT_VARIABLE result_modified_
    ERROR_QUIET
  )
  execute_process(COMMAND ${GIT_EXECUTABLE} diff --staged --quiet --exit-code
    WORKING_DIRECTORY ${path_}
    RESULT_VARIABLE result_staged_
    ERROR_QUIET
  )
  if(NOT (result_modified_ EQUAL 0))
    set(${clean_} False PARENT_SCOPE)
    set(${dirty_reason_} "Modified files." PARENT_SCOPE)
  elseif(NOT (result_staged_ EQUAL 0))
    set(${clean_} False PARENT_SCOPE)
    set(${dirty_reason_} "Staged files." PARENT_SCOPE)
  else()
    set(${clean_} True PARENT_SCOPE)
    set(${dirty_reason_} "" PARENT_SCOPE)
  endif()

endfunction()
