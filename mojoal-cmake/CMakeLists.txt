# CMake wrapper to build mojoAL (vendored in ../mojoal, from the Switch
# port) as a static libopenal.a for PS4.
#
# mojoAL upstream ships a CMakeLists.txt, but it requires SDL3; the
# Switch-era code vendored here is SDL2 and proven on a console, so it is
# built with this wrapper instead. Produces libopenal.a + AL/al.h + AL/alc.h,
# which is what Solarus's FindOpenAL module looks for.
cmake_minimum_required(VERSION 3.5)
project(mojoal C)

set(MOJOAL_SRC "" CACHE PATH "Vendored mojoAL source directory")
set(SDL2_INCLUDE_DIR "" CACHE PATH "SDL2 include directory")
set(SDL2_LIBRARY "" CACHE FILEPATH "SDL2 static library")
if(NOT MOJOAL_SRC OR NOT SDL2_INCLUDE_DIR OR NOT SDL2_LIBRARY)
    message(FATAL_ERROR "MOJOAL_SRC, SDL2_INCLUDE_DIR and SDL2_LIBRARY are required")
endif()

add_library(openal STATIC "${MOJOAL_SRC}/mojoal.c")
# mojoal.c includes "al.h"/"alc.h" (in AL/) and "SDL.h" (in SDL2/).
target_include_directories(openal PUBLIC
    "${MOJOAL_SRC}/AL"
    "${SDL2_INCLUDE_DIR}")
target_link_libraries(openal PUBLIC "${SDL2_LIBRARY}")

install(TARGETS openal ARCHIVE DESTINATION lib)
install(FILES "${MOJOAL_SRC}/AL/al.h" "${MOJOAL_SRC}/AL/alc.h" DESTINATION include/AL)
