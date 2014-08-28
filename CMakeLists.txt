cmake_minimum_required(VERSION 2.6)
project(blaCk)
set(blaCk_VERSION_MAJOR 0)
set(blaCk_VERSION_MINOR 1)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

find_package(m4)
include(m4gen)

# enable compiler warnings
if(CMAKE_COMPILER_IS_GNUCC)
	set(CMAKE_C_FLAGS ${CMAKE_C_FLAGS} "-Wall")
endif()

# check type sizes
include(CheckTypeSize)
set(CMAKE_EXTRA_INCLUDE_FILES stddef.h)
check_type_size("size_t" SIZEOF_SIZE_T)
check_type_size("ssize_t" SIZEOF_SSIZE_T)
set(CMAKE_EXTRA_INCLUDE_FILES)

# configure files
configure_file("${PROJECT_SOURCE_DIR}/src/config.h.in"
	"${PROJECT_BINARY_DIR}/src/config.h")
configure_file("${PROJECT_SOURCE_DIR}/include/blaCk/config.h.in"
	"${PROJECT_BINARY_DIR}/include/blaCk/config.h")

# add include directories
include_directories("${PROJECT_BINARY_DIR}/include"
	"${PROJECT_SOURCE_DIR}/include"
	"${PROJECT_SOURCE_DIR}/src"
	"${PROJECT_BINARY_DIR}/src")

# hash maps
option(DISABLE_HASH_MAPS "Do not build hash maps" OFF)
if(NOT DISABLE_HASH_MAPS)
	m4gen_src_header(2 "void *:p;char *:s;uint32_t:i;uint64_t:l"
		src/hash_map.c.m4 include/blaCk/hash_map.h.m4 srcs headers)
	add_library(blaCk-hash "src/primes.c" ${srcs})
	install(FILES ${headers} DESTINATION include/blaCk/)
	install(TARGETS blaCk-hash
		LIBRARY DESTINATION lib
		ARCHIVE DESTINATION lib)
endif()

install(FILES "${PROJECT_BINARY_DIR}/include/blaCk/config.h"
	"${PROJECT_SOURCE_DIR}/include/blaCk/compiler.h"
	DESTINATION include/blaCk/)
