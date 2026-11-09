# Instalar y probar Solarus en la PS4

## Requisitos previos

- PS4 liberada con GoldHEN (FW 12.50), con FTP activado (puerto 2121).
- Los dos módulos Piglet de Sony en `/data/self/system/common/lib/`:
  `libScePigletv2VSH.sprx` (744,208 bytes) y `libSceShaccVSH.sprx`
  (10,394,272 bytes). Son **los mismos** que usa el port de Ship of
  Harkinian: si ya tienes copias buenas para SoH, sirven para Solarus.
  **No se distribuyen aquí**: se extraen de la propia consola (RetroArch
  PS4 R4, ver la guía del port SoH). Subirlos por FTP **en modo binario**.
- La quest de Tombwater (de tu propia copia de Steam, o su **demo
  gratuita** para la primera prueba). Los datos del juego son comerciales:
  no se descargan ni se comparten desde este repo.

## Instalación

1. Instala el `.pkg` del artefacto `solarus-ps4-2.1.4` con el Package
   Installer de GoldHEN (o cópialo a `/data/pkg/` y luego instálalo).
2. Crea la carpeta `/data/solarus/` en la consola (por FTP o con
   PS4-Xplorer). **Sin esta carpeta el motor no arranca**: PhysFS exige
   que el directorio de escritura exista.
3. Sube la quest a `/data/solarus/tombwater/` (por FTP en modo binario).
   La quest es una carpeta con `data/` dentro (el formato de Solarus).
4. Arranca Solarus desde el menú de la PS4.

## Orden de pruebas

1. **Prueba GL** (opcional pero recomendada): instala primero el `.pkg`
   de `solarus-ps4-gl-smoke` ("Solarus GL Test"). Si ves una pantalla
   azul ~3 segundos, el camino SDL → Piglet funciona y los módulos
   Piglet cargan bien.
2. **Motor sin quest**: si arrancas Solarus sin quest en
   `/data/solarus/tombwater/`, debería mostrar un error de quest no
   encontrada (eso ya confirma que el motor arranca).
3. **Demo de Tombwater**: con la quest en su sitio, el juego debería
   arrancar. El primer arranque puede tardar (compilación de shaders).

## Si algo falla

- Vuelve al menú al instante (CE-34878-0): casi siempre son los módulos
  Piglet. Revisa que los dos `.sprx` tengan el tamaño exacto y estén en
  `/data/self/system/common/lib/`, subidos en modo binario.
- "Quest not found" / error de quest: la carpeta
  `/data/solarus/tombwater/` no está o no contiene `data/` con el
  formato de Solarus.
- Pantalla negra tras arrancar la quest: puede ser la compilación de
  shaders; espera un minuto antes de cerrar.

## Desinstalación

Borra el juego desde el menú de la PS4. Los datos quedan en
`/data/solarus/` (saves en `/data/solarus/.solarus/`).
