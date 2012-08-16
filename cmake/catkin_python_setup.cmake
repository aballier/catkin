# optionally give relative path to setup.py file
function(catkin_python_setup)
  if(ARGN)
    message(FATAL_ERROR "catkin_python_setup() called with unused arguments: ${ARGN}")
  endif()

  assert(PROJECT_NAME)

  # mark that catkin_python_setup() was called in order to disable installation of gen/py stuff in generate_messages()
  set(${PROJECT_NAME}_CATKIN_PYTHON_SETUP TRUE PARENT_SCOPE)
  if(${PROJECT_NAME}_GENERATE_MESSAGES)
    message(FATAL_ERROR "generate_messages() must be called after catkin_python_setup() in project '${PROJECT_NAME}'")
  endif()

  if(${ARGC} GREATER 1)
    message(FATAL_ERROR "catkin_python_setup() takes only one optional argument, update project '${PROJECT_NAME}'")
  endif()
  set(path_to_setup_py "")
  if(${ARGC} EQUAL 1)
    set(path_to_setup_py "${ARGN}/")
  endif()
  set(setup_py_file "${path_to_setup_py}setup.py")
  if(NOT("${path_to_setup_py}" STREQUAL ""))
    string(REPLACE "." "_" path_to_setup_py ${path_to_setup_py})
  endif()

  if(NOT EXISTS ${${PROJECT_NAME}_SOURCE_DIR}/${setup_py_file})
    message(FATAL_ERROR "catkin_python_setup() called without '${setup_py_file}' in project '${PROJECT_NAME}'")
  endif()

  if(EXISTS ${${PROJECT_NAME}_SOURCE_DIR}/${setup_py_file})
    assert(PYTHON_INSTALL_DIR)
    set(INSTALL_CMD_WORKING_DIRECTORY ${${PROJECT_NAME}_SOURCE_DIR})
    if(NOT MSVC)
      set(INSTALL_SCRIPT
        ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/python_distutils_install.sh)
      configure_file(${catkin_EXTRAS_DIR}/templates/python_distutils_install.sh.in
        ${INSTALL_SCRIPT}
        @ONLY)
    else()
      # need to convert install prefix to native path for python setuptools --prefix (its fussy about \'s)
      file(TO_NATIVE_PATH ${CMAKE_INSTALL_PREFIX} PYTHON_INSTALL_PREFIX)
      set(INSTALL_SCRIPT
        ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/python_distutils_install.bat)
      configure_file(${catkin_EXTRAS_DIR}/templates/python_distutils_install.bat.in
        ${INSTALL_SCRIPT}
        @ONLY)
    endif()

    # run generated python script
    configure_file(${catkin_EXTRAS_DIR}/templates/safe_execute_install.cmake.in
      ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/safe_execute_install.cmake)
    install(SCRIPT ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/safe_execute_install.cmake)

    stamp(${${PROJECT_NAME}_SOURCE_DIR}/${setup_py_file})

    assert(CATKIN_ENV)
    assert(PYTHON_EXECUTABLE)
    set(cmd
      ${CATKIN_ENV} ${PYTHON_EXECUTABLE}
      ${catkin_EXTRAS_DIR}/interrogate_setup_dot_py.py
      ${PROJECT_NAME}
      ${${PROJECT_NAME}_SOURCE_DIR}/${setup_py_file}
      ${${PROJECT_NAME}_BINARY_DIR}/${path_to_setup_py}setup_py_interrogation.cmake
      )

    debug_message(10 "catkin_python_setup() in project '{PROJECT_NAME}' executes:  ${cmd}")
    safe_execute_process(COMMAND ${cmd})
    include(${${PROJECT_NAME}_BINARY_DIR}/${path_to_setup_py}setup_py_interrogation.cmake)

    # generate relaying __init__.py for each python package
    if(${PROJECT_NAME}_PACKAGES)
      list(LENGTH ${PROJECT_NAME}_PACKAGES pkgs_count)
      math(EXPR pkgs_range "${pkgs_count} - 1")
      foreach(index RANGE ${pkgs_range})
        list(GET ${PROJECT_NAME}_PACKAGES ${index} pkg)
        list(GET ${PROJECT_NAME}_PACKAGE_DIRS ${index} pkg_dir)
        get_filename_component(name ${pkg_dir} NAME)
        if(NOT ("${pkg}" STREQUAL "${name}"))
          message(FATAL_ERROR "The package name '${pkg}' differs from the basename of the path '${pkg_dir}' in project '${PROJECT_NAME}'")
        endif()
        get_filename_component(path ${pkg_dir} PATH)
        set(PACKAGE_PYTHONPATH ${CMAKE_CURRENT_SOURCE_DIR}/${path})
        configure_file(${catkin_EXTRAS_DIR}/templates/__init__.py.in
          ${catkin_BUILD_PREFIX}/${PYTHON_INSTALL_DIR}/${pkg}/__init__.py
          @ONLY)
      endforeach()
    endif()

    # generate relay-script for each python script
    foreach(script ${${PROJECT_NAME}_SCRIPTS})
      get_filename_component(name ${script} NAME)
      if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${script})
        message(FATAL_ERROR "The script '${name}' as listed in '${setup_py_file}' of '${PROJECT_NAME}' doesn't exist")
      endif()
      set(PYTHON_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/${script})
      configure_file(${catkin_EXTRAS_DIR}/templates/script.py.in
        ${catkin_BUILD_PREFIX}/bin/${name}
        @ONLY)
    endforeach()
  endif()
endfunction()

stamp(${catkin_EXTRAS_DIR}/interrogate_setup_dot_py.py)
