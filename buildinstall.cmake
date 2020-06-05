# create build and install targets, using sources_l, linking to linklibs_l (external) and linktargets_l (internal), setting properties_l as properties
# type is "EXECUTABLE" for an executable program, or "SHARED" for a shared library
# install is "ON" or "INSTALL" to generate install target, "OFF" or the regexp "NO.*" to skip install.
# the arguments ending in _l names of variables holding a list, the other are strings
function(defBI sources_l type linklibs_l linktargets_l properties_l install name)
foreach(varn IN ITEMS sources;linklibs;linktargets;properties)
    set(${varn} ${${${varn}_l}})
  endforeach(varn)
  if("${name}" STREQUAL " ")
    # get a name for the current target, based on the current directory
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" progname_tmp ${CMAKE_CURRENT_SOURCE_DIR})
    string(REPLACE "/" "_" progname ${progname_tmp})
  else()
    set(progname ${name})
  endif()

  if("$ENV{PREFIX}" STREQUAL "")
    set(prefix "/usr")
  else()
    set(prefix "$ENV{PREFIX}")
  endif()
  message("set prefix to ${prefix}")

  if("${type}" STREQUAL "EXECUTABLE")
    message("adding program \"${progname}\"")
    add_executable(${progname} ${sources})
    set(type_v "RUNTIME")
    set(destination_v "${prefix}/local/bin/${project}")
    set(destinationh_v "/dev/null")
  elseif(${type} STREQUAL "SHARED")
    message("adding library \"${progname}\"")
    add_library(${progname} SHARED ${sources})
    set(type_v "LIBRARY")
    set(destination_v "${prefix}/local/lib/${project}")
    set(destinationh_v "${prefix}/local/include/${project}")
  else()
    message("Target \"${progname}\" won't build anything")
    return()
  endif()

  # set includes
  foreach(loopvar IN LISTS incdir)
    target_include_directories(${progname} PUBLIC ${loopvar})
  endforeach(loopvar)

  # set properties
  foreach(loopvar IN LISTS properties)
    set_property(TARGET ${progname} PROPERTY ${loopvar})
  endforeach(loopvar)

  message("Examine exernal libs: ${linklibs}")
  # set linking to extenal libraries
  foreach(loopvar IN LISTS linklibs)
    string(REPLACE "_" "/" linklibs_d ${loopvar})
    if(${loopvar} STREQUAL " ")
      break()
    endif()
    message("Looking for ${loopvar}")
    find_library(libloc${loopvar} ${loopvar} PATHS "${CMAKE_BINARY_DIR}/${linklibs_d}")
    target_link_libraries(${progname} ${libloc${loopvar}})
  endforeach(loopvar)

  message("Examine link targets: ${linktargets}")
  # set links to targets in the same project
  foreach(loopvar IN LISTS linktargets)
    string(REPLACE "_" "/" linklibs_d ${loopvar})
    if(${loopvar} STREQUAL " ")
      break()
    endif()
    message("Linking to ${loopvar}")
    target_link_libraries(${progname} ${loopvar})
  endforeach(loopvar)

  # generate install info
  if(${install} MATCHES "NO.*" OR ${install} STREQUAL "OFF")
    message("Target \"${progname}\" won't install anything")
  elseif(${install} STREQUAL "ON" OR ${install} STREQUAL "INSTALL")
    message("Installing target \"${progname}\" in ${destination_v} and ${destinationh_v}")
    install(TARGETS ${progname} ${type_v} DESTINATION ${destination_v})
    install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} DESTINATION ${destination_v} FILES_MATCHING PATTERN "*.h*") 
  else()
    message("Cannot parse \"INSTALL\" argument. Target \"${progname}\" won't install anything")
  endif()
endfunction(defBI)
