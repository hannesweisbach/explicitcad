set(APPS "$ENV{DESTDIR}/${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME}.app")
set(LIBS ${QT_PLUGINS})
set(DIRS "")

message(STATUS "PREFIX ${CMAKE_INSTALL_PREFIX}")
include(BundleUtilities)

macro (fixup_bundle_item resolved_embedded_item exepath dirs)
  message ("Making writable: ${resolved_embedded_item}")
  message(STATUS "exe: ${exepath} ${dirs}")
  execute_process (COMMAND chmod +w ${resolved_embedded_item})
  _fixup_bundle_item (${resolved_embedded_item} "${exepath}" "${dirs}")
endmacro()

fixup_bundle("${APPS}" "${LIBS}" "${DIRS}")

