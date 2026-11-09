/* Minimal SDL2 + GLES2 smoke test for PS4 (Piglet).
 *
 * Opens a window with a GLES 2.0 context, clears it to blue for ~3 seconds
 * and prints GL_OK. If this runs on console, the SDL -> Piglet path that
 * the Solarus renderer needs is proven, before the engine itself is built.
 * Packaged as its own .pkg ("Solarus GL Test", SOLR00002) by package.sh.
 */
#include <SDL.h>
#include <GLES2/gl2.h>
#include <stdio.h>

int main(int argc, char *argv[])
{
    (void)argc;
    (void)argv;

    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) != 0) {
        SDL_Log("SDL_Init failed: %s", SDL_GetError());
        return 1;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);

    SDL_Window *win = SDL_CreateWindow("Solarus GL smoke test",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        1280, 720, SDL_WINDOW_OPENGL);
    if (!win) {
        SDL_Log("SDL_CreateWindow failed: %s", SDL_GetError());
        return 2;
    }

    SDL_GLContext ctx = SDL_GL_CreateContext(win);
    if (!ctx) {
        SDL_Log("SDL_GL_CreateContext failed: %s", SDL_GetError());
        return 3;
    }
    SDL_Log("GL context OK: vendor=%s renderer=%s version=%s",
        glGetString(GL_VENDOR), glGetString(GL_RENDERER), glGetString(GL_VERSION));

    glClearColor(0.1f, 0.3f, 0.9f, 1.0f);
    for (int i = 0; i < 180; i++) {
        glClear(GL_COLOR_BUFFER_BIT);
        SDL_GL_SwapWindow(win);
        SDL_Delay(16);
    }

    SDL_Log("GL_OK");
    SDL_GL_DeleteContext(ctx);
    SDL_DestroyWindow(win);
    SDL_Quit();
    return 0;
}
