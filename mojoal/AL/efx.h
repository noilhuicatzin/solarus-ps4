/*
 * Minimal AL/efx.h for the Solarus PS4 port.
 *
 * mojoAL (the OpenAL implementation vendored here, from the Switch port)
 * ships no EFX support at all: no efx.h, and its alGetProcAddress()
 * returns NULL for every EFX function name. Solarus 2.1.4's audio code
 * (ALWrapper.h, AudioEffect.cpp, effects/*) uses EFX anyway, so this
 * file declares exactly what Solarus needs and nothing more:
 *   - the 48 AL_ effect/filter constants it references,
 *   - ALC_MAX_AUXILIARY_SENDS,
 *   - the 9 LPAL* function-pointer typedefs used by ALWrapper.cpp.
 *
 * All values are copied verbatim from the canonical OpenAL-Soft efx.h
 * (public domain / Unlicense). The typedefs are the canonical ones
 * with the trailing AL_API_NOEXCEPT17 removed: mojoAL's older al.h
 * does not define that macro, and a plain function-pointer typedef
 * is all Solarus needs (it only stores the pointers and calls them
 * through ALWrapper, guarded by is_efx_available()).
 *
 * Runtime note: these headers only make the code COMPILE. At runtime
 * mojoAL still has no EFX, so ALWrapper::init_efx_system() must stay
 * false when alGetProcAddress() returns NULL -- see the
 * alwrapper-ps4-efx-nullcheck patch applied by prepare-sources.sh.
 * With that patch, quests run with no audio effects instead of
 * crashing on a NULL function pointer.
 */
#ifndef AL_EFX_H
#define AL_EFX_H

#include <AL/al.h>
#include <AL/alc.h>

/* Effect object properties */
#define AL_EFFECT_TYPE                           0x8001

/* Effect types */
#define AL_EFFECT_REVERB                         0x0001
#define AL_EFFECT_CHORUS                         0x0002
#define AL_EFFECT_ECHO                           0x0004
#define AL_EFFECT_FLANGER                        0x0005

/* Reverb effect properties */
#define AL_REVERB_DENSITY                        0x0001
#define AL_REVERB_DIFFUSION                      0x0002
#define AL_REVERB_GAIN                           0x0003
#define AL_REVERB_GAINHF                         0x0004
#define AL_REVERB_DECAY_TIME                     0x0005
#define AL_REVERB_DECAY_HFRATIO                  0x0006
#define AL_REVERB_REFLECTIONS_GAIN               0x0007
#define AL_REVERB_REFLECTIONS_DELAY              0x0008
#define AL_REVERB_LATE_REVERB_GAIN               0x0009
#define AL_REVERB_LATE_REVERB_DELAY              0x000A
#define AL_REVERB_AIR_ABSORPTION_GAINHF          0x000B
#define AL_REVERB_ROOM_ROLLOFF_FACTOR            0x000C
#define AL_REVERB_DECAY_HFLIMIT                  0x000D

/* Chorus effect properties */
#define AL_CHORUS_WAVEFORM                       0x0001
#define AL_CHORUS_PHASE                          0x0002
#define AL_CHORUS_RATE                           0x0003
#define AL_CHORUS_DEPTH                          0x0004
#define AL_CHORUS_FEEDBACK                       0x0005
#define AL_CHORUS_DELAY                          0x0006
#define AL_CHORUS_WAVEFORM_SINUSOID              0

/* Echo effect properties */
#define AL_ECHO_DELAY                            0x0001
#define AL_ECHO_LRDELAY                          0x0002
#define AL_ECHO_DAMPING                          0x0003
#define AL_ECHO_FEEDBACK                         0x0004
#define AL_ECHO_SPREAD                           0x0005

/* Flanger effect properties */
#define AL_FLANGER_WAVEFORM                      0x0001
#define AL_FLANGER_PHASE                         0x0002
#define AL_FLANGER_RATE                          0x0003
#define AL_FLANGER_DEPTH                         0x0004
#define AL_FLANGER_FEEDBACK                      0x0005
#define AL_FLANGER_DELAY                         0x0006
#define AL_FLANGER_WAVEFORM_TRIANGLE             1

/* Auxiliary effect slots */
#define AL_EFFECTSLOT_EFFECT                     0x0001
#define AL_EFFECTSLOT_NULL                       0x0000
#define AL_AUXILIARY_SEND_FILTER                 0x20006
#define AL_DIRECT_FILTER                         0x20005
#define ALC_MAX_AUXILIARY_SENDS                  0x20003

/* Filter object properties */
#define AL_FILTER_TYPE                           0x8001

/* Filter types */
#define AL_FILTER_LOWPASS                        0x0001
#define AL_FILTER_HIGHPASS                       0x0002
#define AL_FILTER_NULL                           0x0000

/* Lowpass filter properties */
#define AL_LOWPASS_GAIN                          0x0001
#define AL_LOWPASS_GAINHF                        0x0002

/* Highpass filter properties */
#define AL_HIGHPASS_GAIN                         0x0001
#define AL_HIGHPASS_GAINLF                       0x0002

/* EFX function-pointer types (canonical signatures, no NOEXCEPT suffix) */
typedef void (AL_APIENTRY *LPALGENEFFECTS)(ALsizei n, ALuint *effects);
typedef void (AL_APIENTRY *LPALDELETEEFFECTS)(ALsizei n, const ALuint *effects);
typedef void (AL_APIENTRY *LPALEFFECTI)(ALuint effect, ALenum param, ALint iValue);
typedef void (AL_APIENTRY *LPALEFFECTF)(ALuint effect, ALenum param, ALfloat flValue);
typedef void (AL_APIENTRY *LPALGENAUXILIARYEFFECTSLOTS)(ALsizei n, ALuint *effectslots);
typedef void (AL_APIENTRY *LPALAUXILIARYEFFECTSLOTI)(ALuint effectslot, ALenum param, ALint iValue);
typedef void (AL_APIENTRY *LPALGENFILTERS)(ALsizei n, ALuint *filters);
typedef void (AL_APIENTRY *LPALFILTERI)(ALuint filter, ALenum param, ALint iValue);
typedef void (AL_APIENTRY *LPALFILTERF)(ALuint filter, ALenum param, ALfloat flValue);

#endif /* AL_EFX_H */
