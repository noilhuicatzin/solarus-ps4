# CMake wrapper to build Lua 5.1.5 (which ships no CMakeLists.txt) as a
# static library for PS4.
#
#   cmake -DLUA_SRC=<path to extracted lua-5.1.5> ...
#
# Only the library sources are compiled (lua.c, luac.c and print.c are the
# standalone interpreter/compiler and are excluded). No LUA_USE_* defines:
# plain ISO C only, so no popen/dlopen, which do not exist on PS4.
cmake_minimum_required(VERSION 3.5)
project(lua51 C)

set(LUA_SRC "" CACHE PATH "Lua 5.1.5 source directory (extracted tarball)")
if(NOT LUA_SRC)
    message(FATAL_ERROR "LUA_SRC is required")
endif()

file(GLOB LUA_LIB_SOURCES "${LUA_SRC}/src/*.c")
list(REMOVE_ITEM LUA_LIB_SOURCES
    "${LUA_SRC}/src/lua.c"
    "${LUA_SRC}/src/luac.c"
    "${LUA_SRC}/src/print.c")

add_library(lua STATIC ${LUA_LIB_SOURCES})
target_include_directories(lua PUBLIC "${LUA_SRC}/src")

install(TARGETS lua ARCHIVE DESTINATION lib)
# NOTE: the pattern must cover *.hpp too, but that alone is not enough:
# Lua 5.1.5 ships lua.hpp (the C++ wrapper header Solarus's LuaTools.h
# includes) in etc/, NOT in src/ — so no src/ pattern can ever pick it up.
# Distro Lua packages install it from etc/ into the include dir; do the
# same here explicitly. (FindLua still passes without it: it only looks
# for lua.h, which is why the missing header only showed up at compile.)
install(DIRECTORY "${LUA_SRC}/src/" DESTINATION include FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
install(FILES "${LUA_SRC}/etc/lua.hpp" DESTINATION include)
