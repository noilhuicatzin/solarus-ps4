#!/usr/bin/env bash
# Prepares the Solarus 2.1.4 sources for the PS4 build.
#
# What it does (run from the solarus-ps4 directory, i.e. this repo's root):
#   1. Clones solarus-games/solarus at tag v2.1.4 (GitLab) into
#      <workspace>/solarus (sibling of solarus-ps4).
#   2. Verifies the PS4-relevant CMake options exist in that version
#      (SOLARUS_GL_ES, SOLARUS_USE_LUAJIT, SOLARUS_BASE_WRITE_DIR,
#      SOLARUS_DEFAULT_QUEST): the whole PS4 adaptation is done with -D
#      options in configure.sh, except ONE source patch (step 3). If a
#      future version drops one of the options, this script fails loudly
#      instead of silently building the wrong thing.
#   3. Applies patches/alwrapper-ps4-efx-nullcheck.patch to the Solarus
#      sources (idempotent): mojoAL has no EFX, so init_efx_system()
#      must only report EFX as available when every function pointer
#      was actually retrieved, or the first audio effect would call a
#      NULL pointer. See the patch header for the full reasoning.
#
# It is idempotent: if <workspace>/solarus already exists it reuses it
# (deletes it first only if --clean is passed). It never downloads game
# data (no Tombwater quest, no Steam files) and never touches Piglet modules.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE="$(cd "$HERE/.." && pwd)"
SOLARUS_TAG="v2.1.4"
SOLARUS_COMMIT="29437e8a98263b1c9c2b742c39894a8eb6a2c200"  # v2.1.4 (2026-09-08)

CLEAN=0
[ "${1:-}" = "--clean" ] && CLEAN=1

if [ "$CLEAN" = "1" ] && [ -d "$WORKSPACE/solarus" ]; then
    echo "== removing existing $WORKSPACE/solarus (--clean)"
    rm -rf "$WORKSPACE/solarus"
fi

if [ ! -d "$WORKSPACE/solarus" ]; then
    echo "== cloning Solarus tag $SOLARUS_TAG (GitLab)"
    git clone --branch "$SOLARUS_TAG" \
        https://gitlab.com/solarus-games/solarus.git "$WORKSPACE/solarus"
else
    echo "== reusing existing $WORKSPACE/solarus"
    git -C "$WORKSPACE/solarus" rev-parse --verify "refs/tags/$SOLARUS_TAG" >/dev/null 2>&1 \
        || { echo "ERROR: existing solarus is not tag $SOLARUS_TAG (use --clean)"; exit 1; }
fi

echo "== solarus HEAD: $(git -C "$WORKSPACE/solarus" rev-parse HEAD)"
echo "   (expected $SOLARUS_COMMIT)"

echo "== checking PS4-relevant CMake options exist in $SOLARUS_TAG"
for opt in SOLARUS_GL_ES SOLARUS_USE_LUAJIT SOLARUS_BASE_WRITE_DIR SOLARUS_DEFAULT_QUEST SOLARUS_WRITE_DIR SOLARUS_TESTS SOLARUS_CLI; do
    if grep -rq "$opt" "$WORKSPACE/solarus/cmake/" ; then
        echo "   OK: $opt"
    else
        echo "ERROR: option $opt not found in solarus $SOLARUS_TAG cmake/ — v1 assumes it exists"
        exit 1
    fi
done

echo "== applying PS4 source patches (idempotent)"
PATCH="$HERE/patches/alwrapper-ps4-efx-nullcheck.patch"
if git -C "$WORKSPACE/solarus" apply --reverse --check "$PATCH" >/dev/null 2>&1; then
    echo "   already applied: alwrapper-ps4-efx-nullcheck.patch"
else
    git -C "$WORKSPACE/solarus" apply "$PATCH"
    echo "   applied: alwrapper-ps4-efx-nullcheck.patch"
fi

echo "== sources ready: $WORKSPACE/solarus (1 PS4 patch applied)"
