#!/usr/bin/env bash
# Cross-builds every third-party dependency of Solarus for PS4 into solarus-ps4/prefix.
#
# Dependency map (see ESTUDIO.md in ~/workspace/solarus-estudio/):
#   - zlib, libpng, freetype: needed by SDL2_ttf / freetype.
#     (libjpeg-turbo NOT built: SDL2_image 2.8.8 uses its bundled STB backend
#     by default, which loads JPG/PNG without libjpeg; Solarus only saves PNG.)
#   - ogg, vorbis: audio decoders used directly by Solarus.
#   - libmodplug: tracker music (Solarus ModPlug dependency).
#   - glm: header-only math library.
#   - SDL 2.0.18 from PacBrew/SDL branch ps4 (NOT upstream SDL and NOT
#     OpenOrbis/SDL-PS4 2.0.9): this is the fork with the PS4 video driver
#     (Piglet GLES 2.0), the PS4 audio driver and the PS4 joystick driver.
#     Its CMakeLists sets SDL_VIDEO_DRIVER_PS4 itself when -DPS4=ON.
#   - SDL2_image, SDL2_ttf: from upstream libsdl-org.
#   - PhysFS 3.2.0: virtual filesystem used to mount quests.
#   - Lua 5.1.5: the quest scripting language (LuaJIT is NOT used on PS4:
#     a JIT needs executable memory, uncertain on console).
#   - mojoAL: tiny OpenAL 1.1 implementation on top of SDL audio, vendored
#     from the Switch port (upstream mojoAL is SDL3-only now; the Switch-era
#     code is SDL2 and proven on a console). This is the stand-in for
#     OpenAL, which does not exist for PS4.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/env.sh"
SRC="$HERE/deps/src"; BLD="$HERE/deps/build"; PREFIX="$HERE/prefix"
TC="$HERE/cmake/ps4-toolchain.cmake"
mkdir -p "$SRC" "$BLD" "$PREFIX"
W() { cygpath -m "$1"; }

fetch() { # name url tag
    if [ ! -d "$SRC/$1" ]; then
        git -c advice.detachedHead=false clone -q --depth 1 --branch "$3" "$2" "$SRC/$1"
    fi
}
fetch_sha() { # name url sha (repos without tags, e.g. libmodplug)
    if [ ! -d "$SRC/$1" ]; then
        git -c advice.detachedHead=false clone -q "$2" "$SRC/$1"
        git -C "$SRC/$1" checkout -q "$3"
    fi
}
build() { # name srcdir [cmake args...]
    local name="$1" src="$2"; shift 2
    if [ -f "$BLD/$name/.done" ]; then echo "== $name (cached)"; return; fi
    echo "== $name"
    cmake -G Ninja -S "$(W "$src")" -B "$(W "$BLD/$name")" -DCMAKE_TOOLCHAIN_FILE="$(W "$TC")" \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$(W "$PREFIX")" -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG" \
        "$@" > "$BLD/$name.configure.log" 2>&1 || { tail -40 "$BLD/$name.configure.log"; exit 1; }
    cmake --build "$(W "$BLD/$name")" > "$BLD/$name.build.log" 2>&1 || { tail -60 "$BLD/$name.build.log"; exit 1; }
    cmake --install "$(W "$BLD/$name")" > "$BLD/$name.install.log" 2>&1 || { tail -40 "$BLD/$name.install.log"; exit 1; }
    touch "$BLD/$name/.done"
}

fetch zlib https://github.com/madler/zlib.git v1.3.1
build zlib "$HERE/zlib-cmake" -DZLIB_SRC="$(W "$SRC/zlib")"

fetch libpng https://github.com/glennrp/libpng.git v1.6.44
build libpng "$SRC/libpng" -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF

# libjpeg-turbo intentionally NOT built (auditoría 2026-11-08): SDL2_image 2.8.8
# defaults to its bundled STB backend (SDL2IMAGE_BACKEND_STB=ON), which loads
# JPG/PNG without libjpeg, and Solarus never calls IMG_SaveJPG (only IMG_SavePNG).
fetch freetype https://github.com/freetype/freetype.git VER-2-13-3
build freetype "$SRC/freetype" -DFT_WITH_ZLIB=ON -DFT_WITH_PNG=ON -DFT_WITH_BZIP2=OFF \
    -DFT_WITH_HARFBUZZ=OFF -DFT_WITH_BROTLI=OFF

fetch ogg https://github.com/xiph/ogg.git v1.3.5
build ogg "$SRC/ogg" -DBUILD_TESTING=OFF -DINSTALL_DOCS=OFF

fetch vorbis https://github.com/xiph/vorbis.git v1.3.7
build vorbis "$SRC/vorbis" -DBUILD_TESTING=OFF

# libmodplug has no tags/releases: pinned by commit (HEAD as of 2026-11-08).
fetch_sha libmodplug https://github.com/Konstanty/libmodplug.git 6b3937da975eff2627fa8f73fa093b7769c1bff5
build libmodplug "$SRC/libmodplug"

fetch glm https://github.com/g-truc/glm.git 1.0.1
build glm "$SRC/glm" -DGLM_BUILD_TESTS=OFF -DGLM_BUILD_INSTALL=ON

# libsamplerate: SDL's PS4 block forces SDL_LIBSAMPLERATE ON (not shared),
# so it must exist before SDL is configured. Built first, statically.
fetch libsamplerate https://github.com/libsndfile/libsamplerate.git 0.2.2
build libsamplerate "$SRC/libsamplerate" -DLIBSAMPLERATE_EXAMPLES=OFF -DLIBSAMPLERATE_INSTALL=ON -DBUILD_TESTING=OFF

# SDL 2.0.18, PacBrew fork, ps4 branch: the PS4 video/audio/joystick drivers
# live here. -DPS4=ON activates them (SDL's own openorbis.cmake toolchain
# sets the same variable; our ps4-toolchain.cmake sets CMAKE_SYSTEM_NAME PS4
# and Platform/PS4.cmake sets PS4=1 as well).
# SDL2main is disabled on purpose (like the SoH build): Solarus links
# SDL2::Main, but its FindSDL2 module turns SDL2::Main into an alias of
# SDL2::Core when no SDL2main library exists, so the CLI links cleanly and
# there is no duplicate main() (SDL's dummy main would clash with
# Solarus's own main on PS4, where SDL_MAIN_NEEDED is not defined).
fetch SDL https://github.com/PacBrew/SDL.git ps4

# PS4 patch: skip the FreeBSD sysctl code in SDL_sysfilesystem.c — the
# OpenOrbis sysroot has no <sys/sysctl.h> (run #4 failed here). Idempotent:
# safe whether SDL was freshly cloned or restored from the deps cache.
PATCH="$HERE/patches/sdl-ps4-sysctl.patch"
if ! git -C "$SRC/SDL" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    git -C "$SRC/SDL" apply "$PATCH"
fi

# PS4 patch: force the PS4 drivers (run #23 root cause). Our toolchain sets
# CMAKE_SYSTEM_NAME PS4 and the PS4 platform file sets UNIX=1, so SDL's
# platform chain takes the UNIX branch and skips the elseif (PS4) block —
# the build ends up with ONLY the dummy video driver ("No available video
# device" / "PS4 not available" on console). This patch adds a guarded
# if (PS4 AND NOT SDL_VIDEO_DRIVER_PS4) block after the chain that
# replicates the elseif (PS4) setup (audio/filesystem/joystick/video
# drivers, EGL/ES2, Sce libs, -D__PS4__). Idempotent like the one above.
PATCH="$HERE/patches/sdl-ps4-force-drivers.patch"
if ! git -C "$SRC/SDL" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    git -C "$SRC/SDL" apply "$PATCH"
fi

# PS4 patch: C89 declarations (run #24 root cause). SDL's own CMakeLists
# adds -Werror=declaration-after-statement unconditionally (NOT gated on
# SDL_WERROR), and the PacBrew PS4 video driver declares variables after
# statements in 9 places (SDL_ps4video.c x8, SDL_ps4piglet.c x1) — code
# that never compiled before because the PS4 drivers were never built.
# This patch moves those declarations to the top of their blocks (with an
# assignment split where the initializer calls a function), changing no
# logic. Verified locally: 0 -Wdeclaration-after-statement warnings in
# all 7 PS4 driver .c files after applying. Idempotent like the ones above.
PATCH="$HERE/patches/sdl-ps4-c89-declarations.patch"
if ! git -C "$SRC/SDL" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    git -C "$SRC/SDL" apply "$PATCH"
fi

build SDL "$SRC/SDL" -DPS4=ON -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF -DSDL2_DISABLE_SDL2MAIN=ON -DSDL2_DISABLE_INSTALL=OFF -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_OPENGL=OFF -DSDL_OPENGLES=OFF -DSDL_VULKAN=OFF -DSDL_KMSDRM=OFF -DSDL_RPI=OFF -DSDL_ALSA=OFF -DSDL_PULSEAUDIO=OFF -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF -DSDL_SNDIO=OFF -DSDL_OSS=OFF -DSDL_ESD=OFF -DSDL_ARTS=OFF -DSDL_NAS=OFF -DSDL_FUSIONSOUND=OFF -DSDL_DBUS=OFF -DSDL_IBUS=OFF -DSDL_FCITX=OFF -DSDL_LIBUDEV=OFF -DSDL_HIDAPI_LIBUSB=OFF -DSDL_RPATH=OFF -DSDL_DUMMYVIDEO=ON -DSDL_DUMMYAUDIO=ON -DSDL_DISKAUDIO=OFF -DSDL_OFFSCREEN=OFF -DSDL_LOADSO=OFF -DSDL_DIRECTFB=OFF -DSDL_SYSTEM_ICONV=OFF -DSDL_LIBICONV=OFF -DSDL_CCACHE=OFF -DSDL_FILESYSTEM=ON -DSDL_VIRTUAL_JOYSTICK=ON -DSDL_HIDAPI=ON -DSDL_HIDAPI_JOYSTICK=OFF -DSDL_WERROR=OFF

fetch SDL_image https://github.com/libsdl-org/SDL_image.git release-2.8.8
build SDL_image "$SRC/SDL_image" -DSDL2IMAGE_VENDORED=OFF -DSDL2IMAGE_SAMPLES=OFF \
    -DSDL2IMAGE_PNG=ON -DSDL2IMAGE_JPG=ON -DSDL2IMAGE_TIF=OFF -DSDL2IMAGE_WEBP=OFF \
    -DSDL2IMAGE_AVIF=OFF -DSDL2IMAGE_JXL=OFF

fetch SDL_ttf https://github.com/libsdl-org/SDL_ttf.git release-2.24.0
build SDL_ttf "$SRC/SDL_ttf" -DSDL2TTF_VENDORED=OFF -DSDL2TTF_SAMPLES=OFF -DSDL2TTF_HARFBUZZ=OFF

fetch physfs https://github.com/icculus/physfs.git release-3.2.0

# PS4 patch: PhysFS takes its FreeBSD branch (target x86_64-pc-freebsd12-elf)
# and includes <sys/ucred.h> + <sys/sysctl.h>, neither in the OpenOrbis
# sysroot; CD-ROM detection is irrelevant on PS4. Idempotent like the SDL
# patch above: safe with freshly cloned or cached deps.
PATCH="$HERE/patches/physfs-ps4-nocdrom.patch"
if ! git -C "$SRC/physfs" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    git -C "$SRC/physfs" apply "$PATCH"
fi

build physfs "$SRC/physfs" -DPHYSFS_BUILD_TEST=OFF -DPHYSFS_BUILD_STATIC=ON -DPHYSFS_BUILD_SHARED=OFF

# Lua 5.1.5 (tarball, no git repo): built with the lua-cmake wrapper below.
# lua.org is flaky from the runners (run #13: curl exit 28, could not even
# connect), so retry hard and fall back to the Debian mirror, which carries
# the same pristine upstream tarball (lua5.1_5.1.5.orig.tar.gz extracts to
# lua-5.1.5/ with the same src/ and etc/ layout).
if [ ! -f "$SRC/lua-5.1.5.tar.gz" ]; then
    curl -fL --retry 8 --retry-delay 15 --retry-all-errors -o "$SRC/lua-5.1.5.tar.gz" https://www.lua.org/ftp/lua-5.1.5.tar.gz \
    || curl -fL --retry 3 --retry-delay 10 -o "$SRC/lua-5.1.5.tar.gz" https://deb.debian.org/debian/pool/main/l/lua5.1/lua5.1_5.1.5.orig.tar.gz
fi
if [ ! -d "$SRC/lua-5.1.5" ]; then
    tar -xzf "$SRC/lua-5.1.5.tar.gz" -C "$SRC"
fi
build lua "$HERE/lua-cmake" -DLUA_SRC="$(W "$SRC/lua-5.1.5")"

# mojoAL (vendored in this repo under mojoal/, from the Switch port): built as
# libopenal.a, the stand-in OpenAL for PS4. Needs the SDL2 headers/libs.
build mojoal "$HERE/mojoal-cmake" -DMOJOAL_SRC="$(W "$HERE/mojoal")" \
    -DSDL2_INCLUDE_DIR="$(W "$PREFIX/include/SDL2")" -DSDL2_LIBRARY="$(W "$PREFIX/lib/libSDL2.a")"

echo "ALL DEPS OK"
