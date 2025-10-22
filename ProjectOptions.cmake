include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(FLTK_Example_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(FLTK_Example_setup_options)
  option(FLTK_Example_ENABLE_HARDENING "Enable hardening" ON)
  option(FLTK_Example_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    FLTK_Example_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    FLTK_Example_ENABLE_HARDENING
    OFF)

  FLTK_Example_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR FLTK_Example_PACKAGING_MAINTAINER_MODE)
    option(FLTK_Example_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(FLTK_Example_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(FLTK_Example_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(FLTK_Example_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(FLTK_Example_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(FLTK_Example_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(FLTK_Example_ENABLE_PCH "Enable precompiled headers" OFF)
    option(FLTK_Example_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(FLTK_Example_ENABLE_IPO "Enable IPO/LTO" ON)
    option(FLTK_Example_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(FLTK_Example_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(FLTK_Example_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(FLTK_Example_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(FLTK_Example_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(FLTK_Example_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(FLTK_Example_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(FLTK_Example_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(FLTK_Example_ENABLE_PCH "Enable precompiled headers" OFF)
    option(FLTK_Example_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      FLTK_Example_ENABLE_IPO
      FLTK_Example_WARNINGS_AS_ERRORS
      FLTK_Example_ENABLE_USER_LINKER
      FLTK_Example_ENABLE_SANITIZER_ADDRESS
      FLTK_Example_ENABLE_SANITIZER_LEAK
      FLTK_Example_ENABLE_SANITIZER_UNDEFINED
      FLTK_Example_ENABLE_SANITIZER_THREAD
      FLTK_Example_ENABLE_SANITIZER_MEMORY
      FLTK_Example_ENABLE_UNITY_BUILD
      FLTK_Example_ENABLE_CLANG_TIDY
      FLTK_Example_ENABLE_CPPCHECK
      FLTK_Example_ENABLE_COVERAGE
      FLTK_Example_ENABLE_PCH
      FLTK_Example_ENABLE_CACHE)
  endif()

  FLTK_Example_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (FLTK_Example_ENABLE_SANITIZER_ADDRESS OR FLTK_Example_ENABLE_SANITIZER_THREAD OR FLTK_Example_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(FLTK_Example_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(FLTK_Example_global_options)
  if(FLTK_Example_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    FLTK_Example_enable_ipo()
  endif()

  FLTK_Example_supports_sanitizers()

  if(FLTK_Example_ENABLE_HARDENING AND FLTK_Example_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR FLTK_Example_ENABLE_SANITIZER_UNDEFINED
       OR FLTK_Example_ENABLE_SANITIZER_ADDRESS
       OR FLTK_Example_ENABLE_SANITIZER_THREAD
       OR FLTK_Example_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${FLTK_Example_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${FLTK_Example_ENABLE_SANITIZER_UNDEFINED}")
    FLTK_Example_enable_hardening(FLTK_Example_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(FLTK_Example_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(FLTK_Example_warnings INTERFACE)
  add_library(FLTK_Example_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  FLTK_Example_set_project_warnings(
    FLTK_Example_warnings
    ${FLTK_Example_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(FLTK_Example_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    FLTK_Example_configure_linker(FLTK_Example_options)
  endif()

  include(cmake/Sanitizers.cmake)
  FLTK_Example_enable_sanitizers(
    FLTK_Example_options
    ${FLTK_Example_ENABLE_SANITIZER_ADDRESS}
    ${FLTK_Example_ENABLE_SANITIZER_LEAK}
    ${FLTK_Example_ENABLE_SANITIZER_UNDEFINED}
    ${FLTK_Example_ENABLE_SANITIZER_THREAD}
    ${FLTK_Example_ENABLE_SANITIZER_MEMORY})

  set_target_properties(FLTK_Example_options PROPERTIES UNITY_BUILD ${FLTK_Example_ENABLE_UNITY_BUILD})

  if(FLTK_Example_ENABLE_PCH)
    target_precompile_headers(
      FLTK_Example_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(FLTK_Example_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    FLTK_Example_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(FLTK_Example_ENABLE_CLANG_TIDY)
    FLTK_Example_enable_clang_tidy(FLTK_Example_options ${FLTK_Example_WARNINGS_AS_ERRORS})
  endif()

  if(FLTK_Example_ENABLE_CPPCHECK)
    FLTK_Example_enable_cppcheck(${FLTK_Example_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(FLTK_Example_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    FLTK_Example_enable_coverage(FLTK_Example_options)
  endif()

  if(FLTK_Example_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(FLTK_Example_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(FLTK_Example_ENABLE_HARDENING AND NOT FLTK_Example_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR FLTK_Example_ENABLE_SANITIZER_UNDEFINED
       OR FLTK_Example_ENABLE_SANITIZER_ADDRESS
       OR FLTK_Example_ENABLE_SANITIZER_THREAD
       OR FLTK_Example_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    FLTK_Example_enable_hardening(FLTK_Example_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
