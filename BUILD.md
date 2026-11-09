# BUILD.md — cómo se construye el port de Solarus para PS4

## Modelo

Este repo sigue el mismo modelo que el port de Ship of Harkinian para PS4
(`noilhuicatzin/shipofharkinian-ps4-9.3.0`): el repo contiene **solo** el
código de build (workflow, scripts, parches, toolchain, wrappers); las
fuentes del motor y las dependencias se descargan en el runner de GitHub
Actions y se compilan con OpenOrbis 0.5.4 + LLVM 18.1.8 en `windows-latest`.
El artefacto es un `.pkg` instalable con GoldHEN.

El toolchain (`cmake/ps4-toolchain.cmake`, `cmake/Platform/PS4.cmake`) y
`compat/include/` se adaptaron del port SoH: mismo layout de OpenOrbis y
LLVM, misma corrección de `struct stat` (`ps4_fixups.h`), misma regla de
link con `ld.lld` + `link.x` + `crt1.o`. La única diferencia es que la raíz
del repo se deriva de la ubicación del propio toolchain en vez de asumir
el checkout como `ps4port`.

## Decisiones técnicas (del estudio, `~/workspace/solarus-estudio/ESTUDIO.md`)

- **Solarus v2.1.4** (tag estable, 2026-09-08, commit
  `29437e8a98263b1c9c2b742c39894a8eb6a2c200`), no la rama dev 2.2.
  `prepare-sources.sh` verifica que las opciones PS4 existan en esa
  versión y falla si falta alguna.
- **`SOLARUS_GL_ES=ON`**: renderizador GLES 2.0 oficial de Solarus, shaders
  `#version 100` = GLSL ES 1.00, el que compila el Shacc de Sony (Piglet).
- **`SOLARUS_USE_LUAJIT=OFF`**: Lua 5.1.5 plano. Un JIT necesita memoria
  ejecutable; en consola es incierto.
- **Sin parches de fuentes en v1**: toda la adaptación PS4 se hace con
  opciones `-D` en `configure.sh` (`SOLARUS_BASE_WRITE_DIR`,
  `SOLARUS_DEFAULT_QUEST`, `SOLARUS_WRITE_DIR`). Si el primer build exige
  un parche, irá a `patches/` con su explicación.
- **SDL 2.0.18 exactos de PacBrew/SDL, rama `ps4`** (commit `bf797a5`):
  driver de vídeo Piglet (EGL/GLES2), audio y joystick de PS4. NO la 2.0.9
  de OpenOrbis/SDL-PS4. Se compila con `-DPS4=ON` y sin SDL2main (el
  `FindSDL2` de Solarus convierte `SDL2::Main` en alias de `SDL2::Core`
  cuando no hay `libSDL2main.a`, así no hay `main()` duplicado).
- **OpenAL → mojoAL vendido** (`mojoal/`, era Switch, API SDL2): el
  mojoAL actual de upstream exige SDL3. Se compila como `libopenal.a` con
  `AL/al.h` + `AL/alc.h`, que es lo que busca el `FindOpenAL` de Solarus.
- **PhysFS 3.2.0, Lua 5.1.5**: no están en PacBrew; se compilan desde
  fuente (Lua con el wrapper `lua-cmake/`, sin defines `LUA_USE_*`: solo
  C ISO, sin popen/dlopen).
- **Rutas en consola**: motor en `/data/solarus/`, quest por defecto en
  `/data/solarus/tombwater/`, saves en `/data/solarus/.solarus/<quest>`.
  `PhysFS_setWriteDir` falla si el directorio no existe: hay que crear
  `/data/solarus/` en la consola antes del primer arranque (ver
  `docs/INSTALL.md`).
- **El `.pkg` lleva solo el motor** (sin datos del juego, que son
  comerciales). La quest de Tombwater se sube por FTP desde la copia de
  Steam propia; la **demo gratuita** es la primera quest de prueba.
- **Módulos Piglet**: los mismos dos `.sprx` que el port de SoH, en el
  mismo lugar (`/data/self/system/common/lib/`). Una vez haya copias
  buenas en la consola, sirven para los dos ports.

## Flujo del workflow

1. Checkout → `build-info.txt` → caché de herramientas → descarga de
   herramientas (CMake 3.28.6, Ninja 1.12.1, LLVM 18.1.8, OpenOrbis 0.5.4).
2. `.NET 8` (para PkgTool.Core).
3. `prepare-sources.sh` → clona Solarus v2.1.4 a `../solarus`.
4. Caché de dependencias → `build-deps.sh` (ver orden en el script).
5. `configure.sh` → `cmake --build build --target solarus-run`.
6. `tests/gl-smoke` → prueba mínima SDL + GLES2.
7. `package.sh` → `out/*.pkg` (motor, `SOLR00001`) y `out-smoke/*.pkg`
   (prueba GL, `SOLR00002`).
8. Artefactos: `solarus-ps4-2.1.4`, `solarus-ps4-gl-smoke`,
   `solarus-ps4-logs` (retención 14 días).

## Riesgos conocidos (a vigilar en el primer build)

1. **SDL_LIBSAMPLERATE**: el bloque PS4 del CMake de SDL 2.0.18 fuerza
   `SDL_LIBSAMPLERATE ON` (no compartida). Por eso `build-deps.sh`
   construye **libsamplerate 0.2.2 antes que SDL**. Si aun así el
   `CheckLibSampleRate` de SDL fallara, el log de configure lo dirá.
2. **SDL2main**: si el link de `solarus-run` falla por `main` duplicado,
   la solución es un parche pequeño a `cli/CMakeLists.txt` quitando el
   enlace a `SDL2::Main`. En v1 se confía en el alias de `FindSDL2`.
3. **C++17 vs libc++ 11** (OpenOrbis): igual que en el port SoH, faltan
   piezas de C++20 (`std::bit_cast`, `std::span`, `std::format`). Solarus
   es C++17, así que no debería aparecer; si aparece, el mismo remedio
   (polyfill guardado con `#ifdef __PS4__`).
4. **PhysFS**: `PHYSFS_setWriteDir` exige que `/data/solarus/` exista
   antes del primer arranque (crear por FTP/Xplorer).
5. **Shaders**: Solarus compila sus shaders GLSL ES 1.00 en arranque
   (Shacc). El primer arranque puede tardar; es normal.
6. **Sin quest en el build**: el primer build solo compila el binario.
   La prueba real en consola necesita la quest (demo de Tombwater) en
   `/data/solarus/tombwater/`.
