if (NOT CLANG_TIDY)
    if (DEFINED ENV{CLANG_TIDY})
        set (CLANG_TIDY_TMP $ENV{CLANG_TIDY})
    else (NOT DEFINED ENV{CLANG_TIDY})
        set (CLANG_TIDY_TMP clang-tidy)
    endif (DEFINED ENV{CLANG_TIDY})

    # is clang-tidy available?
    execute_process (COMMAND ${CLANG_TIDY_TMP} --version
            RESULT_VARIABLE CLANG_TIDY_RESULT
            OUTPUT_VARIABLE CLANG_TIDY_VERSION)
    if (${CLANG_TIDY_RESULT} EQUAL 0)
        string (REGEX MATCH "version [0-9]" CLANG_TIDY_VERSION ${CLANG_TIDY_VERSION})
        message (STATUS "Found clang-tidy " ${CLANG_TIDY_VERSION})
        set (CLANG_TIDY ${CLANG_TIDY_TMP} CACHE STRING "clang-tidy executable name")
    endif (${CLANG_TIDY_RESULT} EQUAL 0)
endif (NOT CLANG_TIDY)

if (DEFINED CLANG_TIDY)
    file (GLOB_RECURSE ALL_CC_FILES *.cc)
    set (CLANG_TIDY_CHECKS "'*,-fuchsia-*,-hicpp-signed-bitwise,-google-build-using-namespace,-android*,-cppcoreguidelines-pro-bounds-pointer-arithmetic,-google-runtime-references,-readability-avoid-const-params-in-decls,-llvm-header-guard'")
    foreach (tidy_target ${ALL_CC_FILES})
        # get_filename_component(<var> <FileName> <mode>)
        # --Sets <var> to a component of <FileName>, where <mode> is one of:
        # `NAME`: File name without directory
        # `DIRECTORY`: Directory without file name
        get_filename_component (basename ${tidy_target} NAME)
        get_filename_component (dirname ${tidy_target} DIRECTORY)
        get_filename_component (basedir ${dirname} NAME)
        set (tidy_target_name "${basedir}__${basename}")
        set (tidy_command ${CLANG_TIDY} -checks=${CLANG_TIDY_CHECKS} -header-filter=.* -p=${PROJECT_BINARY_DIR} ${tidy_target})
        add_custom_target (tidy_quiet_${tidy_target_name} ${tidy_command} 2>/dev/null)
        add_custom_target (tidy_${tidy_target_name} ${tidy_command})
        # list(APPEND <list> [<element> ...]) --Appends elements to the list.
        list (APPEND ALL_TIDY_TARGETS tidy_quiet_${tidy_target_name})
        list (APPEND ALL_TIDY_VERBOSE_TARGETS tidy_${tidy_target_name})
    endforeach (tidy_target)
    # add_custom_target(Name [ALL] [command1 [args1...]]
    #                  [DEPENDS depend depend depend ... ]
    #                  [COMMENT comment])
    # `DEPENDS`: Reference files and outputs of custom commands.
    add_custom_target (tidy DEPENDS ${ALL_TIDY_TARGETS})
    add_custom_target (tidy_verbose DEPENDS ${ALL_TIDY_VERBOSE_TARGETS})
endif (DEFINED CLANG_TIDY)
