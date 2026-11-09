# patches/

Parches de fuentes aplicados por `scripts/prepare-sources.sh`.

**v1: vacío.** Toda la adaptación a PS4 se hace con opciones `-D` en
`configure.sh` (ver `BUILD.md`).

**v2: `alwrapper-ps4-efx-nullcheck.patch`** — `src/audio/ALWrapper.cpp`,
función `init_efx_system()`. mojoAL no tiene EFX: su `alGetProcAddress()`
devuelve NULL para los 9 nombres EFX, y el código original ponía
`efx_available = true` sin comprobar nada, así que el primer efecto de
audio de una quest llamaría a un puntero NULL y crashearía. El parche
solo marca EFX como disponible cuando los 9 punteros se recuperaron;
con EFX apagado, los wrappers de efectos salen por
`is_efx_available()` y la quest suena sin efectos. Los headers EFX
mínimos que hacen compilar esto viven en `mojoal/AL/` (`alext.h`,
`efx.h`, `efx-presets.h`) y se instalan desde `mojoal-cmake/`.
