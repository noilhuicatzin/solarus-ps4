/* Minimal SDL2 + GLES2 smoke test for PS4 (Piglet) — DIAGNOSTIC build.
 *
 * Opens a window with a GLES 2.0 context, clears it to blue for ~3 seconds
 * and prints GL_OK. Writes a step-by-step log to /data/gl-smoke.log
 * (flushed after every line) so an instant crash on console can be
 * pinpointed from the last line in the file — the same approach as the
 * SoH ps4_boot.log. Also loads the Piglet + Shacc modules from the
 * known-good location (/data/self/system/common/lib/, the same two Sony
 * modules SoH uses) instead of SDL's default sandbox path.
 * Packaged as its own .pkg ("Solarus GL Test", SOLR00002) by package.sh.
 */
#include <SDL.h>
#include <GLES2/gl2.h>
#include <stdio.h>

static FILE *diag_log;

static void dlog(const char *msg)
{
    if (diag_log) {
        fprintf(diag_log, "%s\n", msg);
        fflush(diag_log);
    }
    SDL_Log("%s", msg);
}

int main(int argc, char *argv[])
{
    (void)argc;
    (void)argv;

    diag_log = fopen("/data/gl-smoke.log", "w");
    dlog("[diag] gl-smoke start");

    /* Load the Piglet + Shacc modules from the known-good location
     * instead of SDL's default sandbox path, and enable the
     * shader-compiler patch. */
    SDL_SetHint(SDL_HINT_PS4_PIGLET_MODULES_PATH, "/data/self/system/common/lib");
    dlog("[diag] piglet hint set to /data/self/system/common/lib");

    dlog("[diag] SDL_Init(VIDEO)...");
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        char buf[512];
        snprintf(buf, sizeof(buf), "[diag] SDL_Init(VIDEO) failed: %s", SDL_GetError());
        dlog(buf);
        if (diag_log) fclose(diag_log);
        return 1;
    }
    dlog("[diag] SDL_Init(VIDEO) ok");

    dlog("[diag] SDL_InitSubSystem(AUDIO)...");
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) != 0) {
        char buf[512];
        snprintf(buf, sizeof(buf), "[diag] AUDIO failed (continuing without audio): %s", SDL_GetError());
        dlog(buf);
    } else {
        dlog("[diag] AUDIO ok");
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);

    dlog("[diag] SDL_CreateWindow...");
    SDL_Window *win = SDL_CreateWindow("Solarus GL smoke test",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        1280, 720, SDL_WINDOW_OPENGL);
    if (!win) {
        char buf[512];
        snprintf(buf, sizeof(buf), "[diag] SDL_CreateWindow failed: %s", SDL_GetError());
        dlog(buf);
        if (diag_log) fclose(diag_log);
        return 2;
    }
    dlog("[diag] SDL_CreateWindow ok");

    dlog("[diag] SDL_GL_CreateContext...");
    SDL_GLContext ctx = SDL_GL_CreateContext(win);
    if (!ctx) {
        char buf[512];
        snprintf(buf, sizeof(buf), "[diag] SDL_GL_CreateContext failed: %s", SDL_GetError());
        dlog(buf);
        if (diag_log) fclose(diag_log);
        return 3;
    }
    dlog("[diag] SDL_GL_CreateContext ok");

    {
        char buf[512];
        const char *vendor = (const char *)glGetString(GL_VENDOR);
        const char *renderer = (const char *)glGetString(GL_RENDERER);
        const char *version = (const char *)glGetString(GL_VERSION);
        snprintf(buf, sizeof(buf), "[diag] GL vendor=%s renderer=%s version=%s",
            vendor ? vendor : "(null)",
            renderer ? renderer : "(null)",
            version ? version : "(null)");
        dlog(buf);
    }

    glClearColor(0.1f, 0.3f, 0.9f, 1.0f);
    for (int i = 0; i < 180; i++) {
        glClear(GL_COLOR_BUFFER_BIT);
        SDL_GL_SwapWindow(win);
        SDL_Delay(16);
    }

    dlog("[diag] GL_OK");
    SDL_GL_DeleteContext(ctx);
    SDL_DestroyWindow(win);
    SDL_Quit();
    if (diag_log) fclose(diag_log);
    return 0;
}
