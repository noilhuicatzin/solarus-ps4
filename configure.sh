#!/usr/bin/env bash
# Configures the Solarus PS4 build in solarus-ps4/build.
#
# PS4 adaptation, all via -D options (no source patch needed in v1):
#   SOLARUS_GL_ES=ON          official GLES 2.0 renderer (GLSL ES 1.00, the
#                             language Sony's Shacc compiles for Piglet)
#   SOLARUS_USE_LUAJIT=OFF    plain Lua 5.1 (no JIT on console)
#   SOLARUS_TESTS=OFF         no unit tests on console
#   SOLARUS_CLI=ON            build solarus-run (the quest runner; the Qt
#                             launcher is not part of the engine build)
#   SOLARUS_BASE_WRITE_DIR=/data/solarus
#                             saves + quest data live here instead of
#                             SDL_GetPrefPath (PhysFS_setWriteDir requires
#                             the directory to already exist: create it on
#                             the console before the first run, see docs/INSTALL.md)
#   SOLARUS_WRITE_DIR=.solarus
#                             saves go to /data/solarus/.solarus/<quest>
#   SOLARUS_DEFAULT_QUEST=/data/solarus/tombwater
#                             quest launched when no path is given (the
#                             Tombwater quest data comes from Lux's own
#                             Steam copy, uploaded by FTP; the free demo
#                             works as the first test quest)
#
# The find modules are pointed at prefix/ explicitly: the PS4 toolchain
# sets CMAKE_FIND_ROOT_PATH to prefix + toolchain, but the explicit cache
# values below make the result deterministic on the Windows runner.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/env.sh"
W() { cygpath -m "$1"; }
P="$HERE/prefix"
# MSYS2 (Git Bash) convierte las rutas /data/... de los -D en rutas
# Windows (C:/Program Files/Git/data/...), y el motor las graba así.
# Sin esto, el .pkg busca la quest y su carpeta de saves en una ruta de
# Windows que no existe en la PS4 y muere en open_quest. Las rutas reales
# ya van por cygpath -m (W), así que desactivar la conversión es seguro.
export MSYS_NO_PATHCONV=1
cmake -G Ninja -S "$(W "$HERE/../solarus")" -B "$(W "$HERE/build")" \
    -DCMAKE_TOOLCHAIN_FILE="$(W "$HERE/cmake/ps4-toolchain.cmake")" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_CXX_SCAN_FOR_MODULES=OFF \
    -DSOLARUS_GL_ES=ON \
    -DSOLARUS_USE_LUAJIT=OFF \
    -DSOLARUS_TESTS=OFF \
    -DSOLARUS_CLI=ON \
    -DSOLARUS_BASE_WRITE_DIR=/data/solarus \
    -DSOLARUS_WRITE_DIR=.solarus \
    -DSOLARUS_DEFAULT_QUEST=/data/solarus/tombwater \
    -DSDL2_INCLUDE_DIR="$(W "$P/include/SDL2")" \
    -DSDL2_LIBRARY="$(W "$P/lib/libSDL2.a")" \
    -DSDL2_IMAGE_INCLUDE_DIR="$(W "$P/include/SDL2")" \
    -DSDL2_IMAGE_LIBRARY="$(W "$P/lib/libSDL2_image.a")" \
    -DSDL2_TTF_INCLUDE_DIR="$(W "$P/include/SDL2")" \
    -DSDL2_TTF_LIBRARY="$(W "$P/lib/libSDL2_ttf.a")" \
    -DOPENAL_INCLUDE_DIR="$(W "$P/include")" \
    -DOPENAL_LIBRARY="$(W "$P/lib/libopenal.a")" \
    -DPHYSFS_INCLUDE_DIR="$(W "$P/include")" \
    -DPHYSFS_LIBRARY="$(W "$P/lib/libphysfs.a")" \
    -DLUA_INCLUDE_DIR="$(W "$P/include")" \
    -DLUA_LIBRARY="$(W "$P/lib/liblua.a")" \
    -DLUA_MATH_LIBRARY="$(W "$OO_PS4_TOOLCHAIN/lib/libm.a")" \
    -DMODPLUG_INCLUDE_DIR="$(W "$P/include")" \
    -DMODPLUG_LIBRARY="$(W "$P/lib/libmodplug.a")" \
    -DGLM_INCLUDE_DIR="$(W "$P/include")" \
    -DVORBIS_INCLUDE_DIR="$(W "$P/include")" \
    -DVORBIS_LIBRARY="$(W "$P/lib/libvorbis.a")" \
    -DVORBISFILE_INCLUDE_DIR="$(W "$P/include")" \
    -DVORBISFILE_LIBRARY="$(W "$P/lib/libvorbisfile.a")" \
    -DOGG_INCLUDE_DIR="$(W "$P/include")" \
    -DOGG_LIBRARY="$(W "$P/lib/libogg.a")" \
    "$@"
