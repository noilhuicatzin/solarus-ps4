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
