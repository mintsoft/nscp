MACRO(LOAD_SECTIONS _TARGET_LIST _path _title)
	message(STATUS "Adding all: ${_title}")
	SET(${_TARGET_LIST})
	FILE(GLOB TMP_LIST RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" ${_path})
	FOREACH(_CURRENT_MODULE ${TMP_LIST})
		get_filename_component(CURRENT_MODULE_PATH ${_CURRENT_MODULE} PATH)
		get_filename_component(CURRENT_MODULE_FILENAME ${_CURRENT_MODULE} NAME)
		get_filename_component(CURRENT_MODULE_NAME ${CURRENT_MODULE_PATH} NAME)
		IF("${CURRENT_MODULE_FILENAME}" STREQUAL "CMakeLists.txt")
			message(STATUS " * ${CURRENT_MODULE_NAME}${MODULE_NOTE}")
			ADD_SUBDIRECTORY("${CURRENT_MODULE_PATH}")
		ELSE()
			SET(BUILD_MODULE 0)
			SET(BUILD_MODULE_SKIP_REASON "Skipped")
			SET(MODULE_NOTE "")
			include(${_CURRENT_MODULE})
			IF(BUILD_MODULE)
				IF(MODULE_NOTE)
					SET(MODULE_NOTE " (${MODULE_NOTE})")
				ENDIF(MODULE_NOTE)
				message(STATUS " + ${CURRENT_MODULE_NAME}${MODULE_NOTE}")
				ADD_SUBDIRECTORY("${CURRENT_MODULE_PATH}")
				SET(${_TARGET_LIST} ${${_TARGET_LIST}} ${CURRENT_MODULE_NAME})
			ELSE(BUILD_MODULE)
				message(STATUS " - ${CURRENT_MODULE_NAME}: ${BUILD_MODULE_SKIP_REASON}")
			ENDIF(BUILD_MODULE)
		ENDIF()
	ENDFOREACH(_CURRENT_MODULE ${TMP_LIST})
ENDMACRO(LOAD_SECTIONS)


MACRO(copy_single_file _TARGET_LIST src destDir)
	GET_FILENAME_COMPONENT(TARGET ${src} NAME)
	SET(source_file ${CMAKE_CURRENT_SOURCE_DIR}/${src})
	IF(${destDir} STREQUAL ".")
		SET(target_file ${CMAKE_BINARY_DIR}/${TARGET})
	ELSE(${destDir} STREQUAL ".")
		SET(target_file ${CMAKE_BINARY_DIR}/${destDir}/${TARGET})
	ENDIF(${destDir} STREQUAL ".")
	#MESSAGE(STATUS " - Copying ${source_file} to ${target_file}...")
	ADD_CUSTOM_COMMAND(
		OUTPUT ${target_file}
		COMMAND cmake ARGS -E copy "${source_file}" "${target_file}"
		COMMENT Copying ${source_file} to ${target_file}
		DEPENDS ${source_file}
		)
	SET(${_TARGET_LIST} ${${_TARGET_LIST}} ${target_file})
	INSTALL(FILES ${target_file} DESTINATION ${INSTALL_FILES_BASE}${destDir})
ENDMACRO(copy_single_file)

MACRO(copy_single_file_755 _TARGET_LIST src destDir)
	GET_FILENAME_COMPONENT(TARGET ${src} NAME)
	SET(source_file ${CMAKE_CURRENT_SOURCE_DIR}/${src})
	IF(${destDir} STREQUAL ".")
		SET(target_file ${CMAKE_BINARY_DIR}/${TARGET})
	ELSE(${destDir} STREQUAL ".")
		SET(target_file ${CMAKE_BINARY_DIR}/${destDir}/${TARGET})
	ENDIF(${destDir} STREQUAL ".")
	#MESSAGE(STATUS " - Copying ${source_file} to ${target_file}...")
IF(WIN32)
	ADD_CUSTOM_COMMAND(
		OUTPUT ${target_file}
		COMMAND cmake ARGS -E copy "${source_file}" "${target_file}"
		COMMENT Copying ${source_file} to ${target_file}
		DEPENDS ${source_file}
		)
ELSE(WIN32)
	ADD_CUSTOM_COMMAND(
		OUTPUT ${target_file}
		COMMAND cmake ARGS -E copy "${source_file}" "${target_file}"
		COMMAND chmod ARGS 755 "${target_file}"
		COMMENT Copying ${source_file} to ${target_file}
		DEPENDS ${source_file}
		)
ENDIF(WIN32)
	SET(${_TARGET_LIST} ${${_TARGET_LIST}} ${target_file})
	INSTALL(FILES ${target_file} DESTINATION ${INSTALL_FILES_BASE}${destDir})
ENDMACRO(copy_single_file_755)

MACRO(add_nscp_py_test name script)
	ADD_TEST("${name}"
		nscp 
			unit
			--language python
			--script ${script}
		)
ENDMACRO(add_nscp_py_test)
MACRO(add_nscp_py_test_case name script case)
	ADD_TEST("${name}_${case}"
		nscp 
			unit
			--language python
			--script ${script}
			--case ${case}
		)
ENDMACRO(add_nscp_py_test_case)

MACRO(add_nscp_lua_test name script)
IF (LUA_FOUND)
	ADD_TEST("${name}"
		nscp 
			unit
			--language lua
			--script ${script}.lua
			--log error
		)
ELSE (LUA_FOUND)
	MESSAGE(STATUS "Skipping test ${name} since lua is not available")
ENDIF (LUA_FOUND)
ENDMACRO(add_nscp_lua_test)

MACRO(CREATE_MODULE _SRCS _SOURCE _TARGET)
INCLUDE_DIRECTORIES(${_TARGET})
ADD_CUSTOM_COMMAND(
	OUTPUT ${_TARGET}/module.cpp  ${_TARGET}/module.hpp ${_TARGET}/module.def ${_TARGET}/module.rc
	COMMAND ${PYTHON_EXECUTABLE}
		ARGS
		"${BUILD_PYTHON_FOLDER}/create_plugin_module.py" 
		--source ${_SOURCE}
		--target ${_TARGET}
	COMMENT Generating ${_TARGET}/module.cpp and ${_TARGET}/module.hpp from ${_SOURCE}/module.json
	DEPENDS ${_SOURCE}/module.json
	)
SET(${_SRCS} ${${_SRCS}} ${_TARGET}/module.cpp)
IF(WIN32)
	SET(${_SRCS} ${${_SRCS}} ${_TARGET}/module.hpp)
	SET(${_SRCS} ${${_SRCS}} ${_TARGET}/module.def)
	SET(${_SRCS} ${${_SRCS}} ${_TARGET}/module.rc)
ENDIF(WIN32)
ENDMACRO(CREATE_MODULE)


MACRO(OPENSSL_LINK_FIX _TARGET)
IF(WIN32)
	SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LINK_FLAGS /SAFESEH:NO)
ENDIF(WIN32)
ENDMACRO(OPENSSL_LINK_FIX)

MACRO(SET_LIBRARY_OUT_FOLDER _TARGET)
	IF(MSVC11 OR MSVC12 OR MSVC13 OR MSVC14 OR APPLE)
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BUILD_TARGET_EXE_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${BUILD_TARGET_EXE_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${BUILD_TARGET_EXE_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BUILD_TARGET_EXE_PATH})
	ENDIF()
ENDMACRO(SET_LIBRARY_OUT_FOLDER)

MACRO(SET_LIBRARY_OUT_FOLDER_MODULE _TARGET)
	IF(MSVC11 OR MSVC12 OR MSVC13 OR MSVC14 OR APPLE)
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${BUILD_TARGET_EXE_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_DEBUG ${BUILD_TARGET_EXE_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${BUILD_TARGET_EXE_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BUILD_TARGET_EXE_PATH})
	ENDIF()
ENDMACRO(SET_LIBRARY_OUT_FOLDER_MODULE)


MACRO(COPY_FILE _SOURCE _TARGET)
IF((${CMAKE_MAJOR_VERSION} EQUAL 2 AND ${CMAKE_MINOR_VERSION} GREATER 6) OR ${CMAKE_MAJOR_VERSION} GREATER 2)
	FILE(COPY ${_SOURCE} DESTINATION ${_TARGET})
ELSE()
	add_custom_command(TARGET copy_${_SOURCE} PRE_BUILD
					   COMMAND ${CMAKE_COMMAND} -E copy_directory ${_SOURCE} ${_TARGET})
ENDIF()
ENDMACRO()

MACRO(NSCP_INSTALL_MODULE _TARGET)
	IF(WIN32)
		SET(_FOLDER "${MODULE_SUBFOLDER}")
		INSTALL(TARGETS ${_TARGET} 
			RUNTIME DESTINATION ${_FOLDER}
			LIBRARY DESTINATION ${_FOLDER}
			ARCHIVE DESTINATION ${_FOLDER}
			)
	ELSEIF(APPLE)
		SET(_FOLDER ${MODULE_SUBFOLDER})
		INSTALL(TARGETS ${_TARGET} LIBRARY DESTINATION ${_FOLDER})
	ELSE()
		SET(_FOLDER ${MODULE_TARGET_FOLDER})
		INSTALL(TARGETS ${_TARGET} LIBRARY DESTINATION ${_FOLDER})
	ENDIF()
	IF(MSVC11 OR MSVC12 OR MSVC13 OR MSVC14 OR APPLE)
		SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${BUILD_TARGET_ROOT_PATH}/${_FOLDER})
		SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_DEBUG ${BUILD_TARGET_ROOT_PATH}/${_FOLDER})
		SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${BUILD_TARGET_ROOT_PATH}/${_FOLDER})
		SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BUILD_TARGET_ROOT_PATH}/${_FOLDER})
	endif()
ENDMACRO()


MACRO(NSCP_MAKE_LIBRARY _TARGET _SRCS)
	IF(USE_STATIC_RUNTIME)
		ADD_LIBRARY(${_TARGET} STATIC ${_SRCS})
		IF(CMAKE_COMPILER_IS_GNUCXX AND "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64" AND NOT APPLE)
			SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES COMPILE_FLAGS "-fPIC")
		ENDIF(CMAKE_COMPILER_IS_GNUCXX AND "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64" AND NOT APPLE)
		set_target_properties(${_TARGET} PROPERTIES
			VERSION "${NSCP_LIB_VERSION}")
	ELSE(USE_STATIC_RUNTIME)
		ADD_LIBRARY(${_TARGET} SHARED ${_SRCS})
		SET_LIBRARY_OUT_FOLDER(${_TARGET})
		set_target_properties(${_TARGET} PROPERTIES
			VERSION "${NSCP_LIB_VERSION}"
			SOVERSION "${NSCP_LIB_VERSION}")
	ENDIF(USE_STATIC_RUNTIME)
	SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES FOLDER "libraries")

	IF(NOT USE_STATIC_RUNTIME)
		IF(WIN32)
			INSTALL(TARGETS ${_TARGET} 
					RUNTIME DESTINATION .
					LIBRARY DESTINATION .)
		ELSE()
			INSTALL(TARGETS ${_TARGET} 
					LIBRARY DESTINATION ${LIB_TARGET_FOLDER})
		ENDIF()
		IF(MSVC11 OR MSVC12 OR MSVC13 OR MSVC14 OR APPLE)
			SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${BUILD_TARGET_ROOT_PATH})
			SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_DEBUG ${BUILD_TARGET_ROOT_PATH})
			SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELEASE ${BUILD_TARGET_ROOT_PATH})
			SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BUILD_TARGET_ROOT_PATH})
		endif()
	ENDIF(NOT USE_STATIC_RUNTIME)
ENDMACRO()

MACRO(NSCP_MAKE_EXE _TARGET _SRCS _FOLDER)
	ADD_EXECUTABLE(${_TARGET} ${_SRCS})
		IF(WIN32)
			INSTALL(TARGETS ${_TARGET} 
					RUNTIME DESTINATION .)
			sign_file(${_TARGET} "${BUILD_TARGET_ROOT_PATH}/${_TARGET}.exe")
		ELSE()
			INSTALL(TARGETS ${_TARGET} 
					RUNTIME DESTINATION ${_FOLDER})
		ENDIF()
	IF(MSVC11 OR MSVC12 OR MSVC13 OR MSVC14 OR APPLE)
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BUILD_TARGET_ROOT_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${BUILD_TARGET_ROOT_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${BUILD_TARGET_ROOT_PATH})
		SET_TARGET_PROPERTIES(${_TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO ${BUILD_TARGET_ROOT_PATH})
	ENDIF()
ENDMACRO()

MACRO(NSCP_MAKE_EXE_SBIN _TARGET _SRCS)
	NSCP_MAKE_EXE(${_TARGET} "${_SRCS}" ${SBIN_TARGET_FOLDER})
ENDMACRO()
MACRO(NSCP_MAKE_EXE_BIN _TARGET _SRCS)
	NSCP_MAKE_EXE(${_TARGET} "${_SRCS}" ${BIN_TARGET_FOLDER})
ENDMACRO()

MACRO(NSCP_FORCE_INCLUDE _TARGET _SRC)
	IF(WIN32)
		string(REPLACE "/" "\\" WINSRC "${_SRC}")
		SET_TARGET_PROPERTIES(${TARGET} PROPERTIES COMPILE_FLAGS "/FI\"${WINSRC}\"")
	ELSE(WIN32)
		IF(USE_STATIC_RUNTIME AND CMAKE_COMPILER_IS_GNUCXX AND "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64" AND NOT APPLE)
			SET_TARGET_PROPERTIES(${TARGET} PROPERTIES COMPILE_FLAGS "-fPIC -include \"${_SRC}\"")
		ELSE()
			SET_TARGET_PROPERTIES(${TARGET} PROPERTIES COMPILE_FLAGS "-include \"${_SRC}\"")
		ENDIF()
	ENDIF(WIN32) 
ENDMACRO()

MACRO(SETUP_BREAKPAD _SRC)
	IF(BREAKPAD_FOUND)
		IF(WIN32)
			SET(${_SRC} ${${_SRC}} ${NSCP_INCLUDEDIR}/breakpad/exception_handler_win32.cpp)
			SET(${_SRC} ${${_SRC}} ${NSCP_INCLUDEDIR}/breakpad/exception_handler_win32.hpp)
			SET(${_SRC} ${${_SRC}} ${NSCP_INCLUDEDIR}/ServiceCmd.cpp)
			SET(${_SRC} ${${_SRC}} ${NSCP_INCLUDEDIR}/ServiceCmd.h)
		ENDIF(WIN32)
		ADD_DEFINITIONS(-DUSE_BREAKPAD)
		INCLUDE_DIRECTORIES(${BREAKPAD_INCLUDE_DIR})
		SET(EXTRA_LIBS ${EXTRA_LIBS} ${BREAKPAD_COMMON_LIBRARY} ${BREAKPAD_LIBRARY})
	ENDIF(BREAKPAD_FOUND)
ENDMACRO()





macro(sign_file PROJNAME _FILENAME)
    if (WIN32)
        if (EXISTS ${SIGN_CERTIFICATE})
            message("-- ${_FILENAME} will be signed with ${SIGN_CERTIFICATE}")
            GET_FILENAME_COMPONENT(WINSDK_DIR "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Microsoft SDKs\\Windows;CurrentInstallFolder]" REALPATH CACHE)
            GET_FILENAME_COMPONENT(WINKIT_DIR "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots;KitsRoot]" REALPATH CACHE)
            find_program(SIGNTOOL signtool
                PATHS
                ${WINKIT_DIR}/bin/x64
                ${WINSDK_DIR}/bin
                )
            if (SIGNTOOL)
                set(_STCMD signtool sign /f "${SIGN_CERTIFICATE}")
                if (NOT "${SIGN_PASSFILE}" STREQUAL "")
                    file(STRINGS "${SIGN_PASSFILE}" PASSPHRASE LIMIT_COUNT 1)
                    set(_STCMD ${_STCMD} /p ${PASSPHRASE})
                endif()
                if (NOT "${SIGN_TIMESTAMP_URL}" STREQUAL "")
                    set(_STCMD ${_STCMD} /t "${SIGN_TIMESTAMP_URL}")
                endif()
                set(_STCMD ${_STCMD} "${_FILENAME}")
                ADD_CUSTOM_COMMAND(
                    TARGET ${PROJNAME}
                    POST_BUILD
                    COMMAND ${_STCMD}
                    )
                message(STATUS "Successfully added signtool step to sign ${_FILENAME}")
            else()
                message("!! Could not find signtool! Code signing disabled ${SIGNTOOL}")
            endif()
            set(PASSPHRASE "")
        else()
            message(STATUS "No signtool certificate found; assuming development machine (${SIGN_CERTIFICATE})")
        endif()

    endif()
endmacro(sign_file)

MACRO(find_redist _TARGET_VAR)
	get_filename_component(_VS_BIN_FOLDER ${CMAKE_LINKER} PATH)
	get_filename_component(_VS_ROOT_FOLDER ${_VS_BIN_FOLDER} PATH)
	if(MSVC14)
		set(_VC_VERSION "140")
	elseif (MSVC12)
		set(_VC_VERSION "120")
	elseif (MSVC11)
		set(_VC_VERSION "110")
	elseif (MSVC10)
		set(_VC_VERSION "100")
	elseif (MSVC90)
		set(_VC_VERSION "90")
	elseif (MSVC80)
		set(_VC_VERSION "80")
	endif()
	if(CMAKE_CL_64)
		SET(_VC_ARCH x64)
	else(CMAKE_CL_64)
		SET(_VC_ARCH x86)
	endif(CMAKE_CL_64)
	set(_redit_folder "${_VS_ROOT_FOLDER}/redist/${_VC_ARCH}/Microsoft.VC${_VC_VERSION}.CRT")
	file(GLOB ${_TARGET_VAR} "${_redit_folder}/*.dll")
endmacro(find_redist)


