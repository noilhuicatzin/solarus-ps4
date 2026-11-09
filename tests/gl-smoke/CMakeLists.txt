# Minimal SDL2 + GLES2 smoke test for PS4. Built with the same PS4
# toolchain as the engine; links the cross-built SDL2 from prefix/.
cmake_minimum_required(VERSION 3.5)
project(gl-smoke C)

find_package(SDL2 2.0.18 REQUIRED)

add_executable(gl-smoke main.c)
target_link_libraries(gl-smoke PRIVATE SDL2::SDL2)
