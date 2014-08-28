message(STATUS "Finding m4 macro processor")
find_program(m4 m4 DOC "m4 macro processor")
if(NOT m4)
	message(FATAL_ERROR "Could not find m4 macro processor")
else()
	message(STATUS "Finding m4 macro processor - done")
endif()

