# patches/

Parches de fuentes aplicados por `scripts/prepare-sources.sh`.

**v1: vacío.** Toda la adaptación a PS4 se hace con opciones `-D` en
`configure.sh` (ver `BUILD.md`).

**v2: `alwrapper-ps4-efx-nullcheck.patch`** — `src/audio/ALWrapper.cpp` e
`include/solarus/audio/ALWrapper.h`. mojoAL no tiene EFX: su
`alGetProcAddress()` devuelve NULL para los 9 nombres EFX. La v2.1.4
llama a esos punteros sin comprobar nada, así que el primer efecto de
audio de una quest llamaría a un puntero NULL y crashearía. El parche
trasplanta a la 2.1.4 el mecanismo que upstream añadió después (el
flag `efx_available` + `is_efx_available()` + los early-returns en los
8 métodos EFX de ALWrapper), con una diferencia: en vez de poner el
flag a `true` sin más, solo se activa cuando los 9 punteros existen
de verdad (la adaptación para mojoAL). Con EFX apagado, la quest suena
sin efectos. Los headers EFX mínimos que hacen compilar esto viven en
`mojoal/AL/` (`alext.h`, `efx.h`, `efx-presets.h`) y se instalan desde
`mojoal-cmake/`. OJO: el parche se verificó contra el tag v2.1.4 real
(commit 29437e8a); la primera versión del parche se escribió por error
contra un clon más nuevo del engine (que ya trae los guards) y no
aplicaba — el run #10 lo evidenció.

**v3: `solarus-ps4-link-deps.patch`** — `cmake/AddSolarusLibrary.cmake`.
SDL2 y SDL2_ttf se enlazan como archivos estáticos sueltos (ver
`configure.sh`: `-DSDL2_LIBRARY` / `-DSDL2_TTF_LIBRARY` son rutas a un
solo `.a`), así que sus propias dependencias no se propagan al enlace.
SDL2_ttf necesita FreeType y el driver de audio PS4 de SDL2 necesita
libsamplerate; sin ellas el enlace falla con símbolos indefinidos
`FT_*` / `src_*` (run #14: los 234 objetos compilaron, el enlace se
cayó en `[234/234]`). El parche añade `libfreetype.a` y
`libsamplerate.a` al final de la lista PUBLIC del target `solarus`
(rutas derivadas de `SDL2_LIBRARY`, que el find module ya resolvió),
para que queden después de `libSDL2_ttf.a` y `libSDL2.a` en la línea
de enlace, que es lo que exige el enlace estático. Solo aplica en
PS4 (`CMAKE_SYSTEM_NAME STREQUAL "PS4"`).
