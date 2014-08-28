cmake_minimum_required(VERSION 2.6)
project(crank)
set(crank_VERSION_MAJOR 0)
set(crank_VERSION_MINOR 1)

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
configure_file("${PROJECT_SOURCE_DIR}/include/crank/config.h.in"
	"${PROJECT_BINARY_DIR}/include/crank/config.h")

# add include directories
include_directories("${PROJECT_BINARY_DIR}/include"
	"${PROJECT_SOURCE_DIR}/include"
	"${PROJECT_SOURCE_DIR}/src"
	"${PROJECT_BINARY_DIR}/src")

# hash maps
option(DISABLE_HASH_MAPS "Do not build hash maps" OFF)
if(NOT DISABLE_HASH_MAPS)
	m4gen_src_header(2 "void *:p;char *:s;uint32_t:i;uint64_t:l"
		src/hash_map.c.m4 include/crank/hash_map.h.m4 srcs headers)
	add_library(crank-hash "src/primes.c" ${srcs})
	install(FILES ${headers} DESTINATION include/crank/)
	install(TARGETS crank-hash
		LIBRARY DESTINATION lib
		ARCHIVE DESTINATION lib)
endif()

install(FILES "${PROJECT_BINARY_DIR}/include/crank/config.h"
	"${PROJECT_SOURCE_DIR}/include/crank/compiler.h"
	DESTINATION include/crank/)
