/*
 * Minimal AL/alext.h for the Solarus PS4 port.
 *
 * mojoAL (the OpenAL implementation vendored here, from the Switch port)
 * ships only al.h and alc.h. Solarus 2.1.4's ALWrapper.h also includes
 * <AL/alext.h>, and the only token it needs from it is ALC_CONNECTED
 * (used by Sound.cpp's device-reconnect check).
 *
 * Value copied verbatim from the canonical OpenAL-Soft alext.h
 * (public domain / Unlicense), which defines:
 *   #define ALC_CONNECTED  0x313
 * Everything else in the canonical alext.h is NOT used by Solarus and
 * is deliberately left out, so this file stays compatible with mojoAL's
 * older al.h (the full canonical headers use macros mojoAL lacks).
 */
#ifndef AL_ALEXT_H
#define AL_ALEXT_H

#include <AL/al.h>
#include <AL/alc.h>

#define ALC_CONNECTED                            0x313

#endif /* AL_ALEXT_H */
