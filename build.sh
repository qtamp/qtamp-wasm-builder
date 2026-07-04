#!/usr/bin/env bash
#
# Build qtamp for WebAssembly inside the qtamp-wasm-builder container.
#
# Expects the qtamp source tree (with its qtWasabi submodule and a fetched
# wasabi-src) mounted at /src. Emits the deployable player to
# /src/build-wasm/dist (qtamp.html + .js + .wasm + assets).
set -euo pipefail

SRC="${SRC:-/src}"
BUILD_DIR="${SRC}/build-wasm"
DIST="${BUILD_DIR}/dist"

# Activate Emscripten.
source /opt/emsdk/emsdk_env.sh

echo "==> Qt wasm: ${QT_WASM}"
echo "==> Qt host: ${QT_HOST}"
echo "==> emcc: $(emcc --version | head -1)"

# The engine needs the user-supplied Wasabi source tree at build time.
if [ ! -d "${SRC}/deps/qtWasabi/wasabi-src/Src/Wasabi" ]; then
    echo "==> fetching Wasabi source (archive.org, WCL v1.0, user-supplied)"
    ( cd "${SRC}/deps/qtWasabi" && ./scripts/fetch-wasabi.sh )
fi

mkdir -p "${BUILD_DIR}"
echo "==> configuring (qt-cmake, wasm toolchain, QTAMP_WASM=ON)"
"${QT_WASM}/bin/qt-cmake" -S "${SRC}" -B "${BUILD_DIR}" -G Ninja \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DQT_HOST_PATH="${QT_HOST}" \
    -DQTAMP_USE_QTWASABI=ON \
    -DQTAMP_WASM=ON

echo "==> building"
cmake --build "${BUILD_DIR}" -j"$(nproc)"

echo "==> shrinking with wasm-opt (keeps the player under the 25 MiB Pages per-file limit)"
/opt/emsdk/upstream/bin/wasm-opt -Oz --all-features \
    "${BUILD_DIR}/qtamp.wasm" -o "${BUILD_DIR}/qtamp.wasm.opt" \
    && mv "${BUILD_DIR}/qtamp.wasm.opt" "${BUILD_DIR}/qtamp.wasm"

echo "==> collecting dist"
rm -rf "${DIST}"; mkdir -p "${DIST}"
# Qt names the output after the target; copy the standard wasm quintet.
for f in qtamp.html qtamp.js qtamp.wasm qtampd.js qtamp.worker.js qtloader.js; do
    [ -f "${BUILD_DIR}/${f}" ] && cp "${BUILD_DIR}/${f}" "${DIST}/"
done
# Qt 6 also emits a *.html we can rename to index.html for hosting.
[ -f "${DIST}/qtamp.html" ] && cp "${DIST}/qtamp.html" "${DIST}/index.html"
echo "==> dist:"; ls -la "${DIST}"
