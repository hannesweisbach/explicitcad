cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

project(ExplicitCAD)

option(IMPLICITCAD_BIN_REQUIRED "Require 'extopenscad' to be found during configuration" ON)
option(IMPLICITCAD_BIN_DIR "Additional path(s) to search for 'extopenscad'" "")
option(BUILD_STANDALONE_BUNDLE "Build standalone .app-bundle on macOS" ${APPLE})

SET(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt5 COMPONENTS Core Gui Widgets OpenGL REQUIRED)
find_package(QScintilla REQUIRED)
find_package(OpenGL REQUIRED)
find_package(Threads REQUIRED)

if (IMPLICITCAD_BIN_REQUIRED)
  find_program(IMPLICITCAD_BIN "extopenscad" HINTS ${IMPLICITCAD_BIN_DIR})
  if(NOT IMPLICITCAD_BIN)
    message(STATUS "extopenscad binary not found")
  else()
    message(STATUS "extopenscad: ${IMPLICITCAD_BIN}")
  endif()
endif()

set(SRCS main.cpp mainwindow.cpp backdrop.cpp glmesh.cpp mesh.cpp loader.cpp canvas.cpp preferences.cpp viewwidget.cpp)
set(RESOURCES explicitcad.qrc gl/gl.qrc)

add_executable(${PROJECT_NAME} MACOSX_BUNDLE ${SRCS} ${RESOURCES})
target_link_libraries(ExplicitCAD Qt5::Core Qt5::Gui Qt5::Widgets Qt5::OpenGL QScintilla::QScintilla OpenGL::GL Threads::Threads)

if (APPLE)
  configure_file(Resources/Info.plist.in ${CMAKE_BINARY_DIR}/Info.plist @ONLY)

  set(BUNDLE_PREFIX "${PROJECT_NAME}.app/Contents")
  set(INSTALL_RUNTIME_DIR "${BUNDLE_PREFIX}/MacOS")
  set(INSTALL_CMAKE_DIR   "${BUNDLE_PREFIX}/Resources")
  set(INSTALL_PLUGINS_DIR "${BUNDLE_PREFIX}/PlugIns")
elseif (WIN32)
  set(INSTALL_RUNTIME_DIR "")
elseif (UNIX)
  set(INSTALL_RUNTIME_DIR "")
endif ()

install(TARGETS ${PROJECT_NAME}
  RUNTIME DESTINATION . COMPONENT Runtime
  BUNDLE DESTINATION . COMPONENT Runtime
  RUNTIME DESTINATION ${INSTALL_RUNTIME_DIR} COMPONENT Runtime
)

if (APPLE AND BUILD_STANDALONE_BUNDLE)
  include(InstallRequiredSystemLibraries)
  macro(install_qt5_plugin _qt_plugin_name _qt_plugins_var _prefix)
    get_target_property(_qt_plugin_path "${_qt_plugin_name}" LOCATION)
    if(EXISTS "${_qt_plugin_path}")
        get_filename_component(_qt_plugin_file "${_qt_plugin_path}" NAME)
        get_filename_component(_qt_plugin_type "${_qt_plugin_path}" PATH)
        get_filename_component(_qt_plugin_type "${_qt_plugin_type}" NAME)
        set(_qt_plugin_dest "${_prefix}/${_qt_plugin_type}")
        #install(FILES "${_qt_plugin_path}" DESTINATION "${_qt_plugin_dest}")
        file(COPY "${_qt_plugin_path}" DESTINATION "${_qt_plugin_dest}")
        set(${_qt_plugins_var}
            "${${_qt_plugins_var}};\$ENV{DESTDIR}${CMAKE_BINARY_DIR}/${_qt_plugin_dest}/${_qt_plugin_file}")
    else()
        message(FATAL_ERROR "QT plugin ${_qt_plugin_name} not found")
    endif()
  endmacro()

  install_qt5_plugin("Qt5::QCocoaIntegrationPlugin" QT_PLUGINS ${INSTALL_PLUGINS_DIR})

  message(STATUS "QtPlugins: ${QT_PLUGINS}")

  configure_file(cmake/FixupBundle.cmake.in ${CMAKE_BINARY_DIR}/FixupBundle.cmake @ONLY)
  add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD COMMAND ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/FixupBundle.cmake)

  if (IMPLICITCAD_BIN)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy ${IMPLICITCAD_BIN} ${INSTALL_RUNTIME_DIR}/)
  endif (IMPLICITCAD_BIN)

# file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/qt.conf" "[Paths]\nPlugins = ${_qt_plugin_dir}\n")
# install(FILES "${CMAKE_CURRENT_BINARY_DIR}/qt.conf" DESTINATION "${INSTALL_CMAKE_DIR}")

endif (APPLE AND BUILD_STANDALONE_BUNDLE)

set(CPACK_GENERATOR    "Bundle")
set(CPACK_BUNDLE_NAME  "${PROJECT_NAME}")
set(CPACK_BUNDLE_PLIST "${CMAKE_BINARY_DIR}/Info.plist")
set(CPACK_BUNDLE_ICON  "${CMAKE_CURRENT_SOURCE_DIR}/Resources/${PROJJECT_NAME}.icns")
#set(CPACK_PACKAGE_INSTALL_DIRECTORY "CMake ${CMake_VERSION_MAJOR}.${CMake_VERSION_MINOR}")

include(CPack)
