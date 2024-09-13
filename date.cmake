# date.cmake
# Copyright 2023 Scott Bailey
# MIT License - please see `https://opensource.org/license/mit/` for more information.
#
# is_leap_year(<year> <output>)
#   output is set to True or False
#
# tt_year(<time_t> <output>
#   Date MUST be in the form of a time_t.
#   output is simply the final 2 digits of the year
#
# tt_doy(<date> <output>)
#   date MUST be in the form of a time_t
#   output is set to the zero padded 3 digit days into the year
#
# expand_date(<time_t> <out year> <out day>)
#   date MUST be in the form of a time_t
#   out year is in the form YY
#   out day is in the form DDD
#
# year2(<year> output>)
#   Convert 4 digit year into a 2 digit string.
#
# doy3(<doy> output>)
#   Convert doy into a 3 digit string.


function(is_leap_year year_ tf_)
  math(EXPR a "${year_}%400")
  math(EXPR b "${year_}%100")
  math(EXPR c "${year_}%4")
  if(a EQUAL "0")
    set(${tf_} True PARENT_SCOPE)
  elseif(b EQUAL "0")
    set(${tf_} False PARENT_SCOPE)
  elseif(c EQUAL "0")
    set(${tf_} True PARENT_SCOPE)
  else()
    set(${tf_} False PARENT_SCOPE)
  endif()
endfunction()


function(tt_year tt_ year_)
  # start at y2k (946684800)
  math(EXPR tt_ "${tt_}-946684800")
  set(y 2000)
  # exit variable
  set(result 0)
  while(NOT result)
    # Determine the seconds in this year.
    is_leap_year(${y} ly_)
    if(ly_)
      set(val 31622400)
    else()
      set(val 31536000)
    endif()
    # Decide if we continue...
    if(tt_ GREATER val)
      # Continuing, increment the year and decrement the seconds.
      math(EXPR y "${y}+1")
      math(EXPR tt_ "${tt_}-${val}")
    else()
      # We are done, set the exit condition.
      set(result ${tt_})
    endif()
  endwhile()
  set(${year_} "${y}" PARENT_SCOPE)
endfunction()


function(tt_doy tt_ doy_)
  # start at y2k (946684800)
  math(EXPR tt_ "${tt_}-946684800")
  set(y 2000)
  # exit variable
  set(result 0)
  while(NOT result)
    # Determine the seconds in this year.
    is_leap_year(${y} ly_)
    if(ly_)
      set(val 31622400)
    else()
      set(val 31536000)
    endif()
    # Decide if we continue...
    if(tt_ GREATER val)
      # Continuing, increment the year and decrement the seconds.
      math(EXPR y "${y}+1")
      math(EXPR tt_ "${tt_}-${val}")
    else()
      # We are done, set the exit condition.
      set(result ${tt_})
    endif()
  endwhile()

  math(EXPR doy "${tt_}/86400+1")

  set(${doy_} "${doy}" PARENT_SCOPE)
endfunction()


function(expand_date tt_ year_ doy_)
  tt_year(${tt_} y)
  tt_doy(${tt_} d)
  set(${year_} "${y}" PARENT_SCOPE)
  set(${doy_} "${d}" PARENT_SCOPE)
endfunction()


function(year2 year_ year2_)
  string(SUBSTRING "${year_}" 2 2 y2)
  set(${year2_} "${y2}" PARENT_SCOPE)
endfunction()


function(doy3 doy_ doy3_)
  set(doy "${doy_}")

  string(LENGTH "${doy}" len)
  if("${len}" EQUAL "1")
    string(PREPEND doy "00")
  elseif("${len}" EQUAL "2")
    string(PREPEND doy "0")
  endif()

  set(${doy3_} "${doy}" PARENT_SCOPE)
endfunction()
