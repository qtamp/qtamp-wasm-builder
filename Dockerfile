# qtamp WebAssembly build container.
#
# Ships a matched Emscripten + Qt-for-WebAssembly toolchain so the qtamp
# reference player (and the qtWasabi engine it embeds) builds to wasm
# reproducibly. The Qt version and its required Emscripten version are a
# matched pair; do not bump one without the other (see Qt's per-release
# "Qt for WebAssembly" page for the mapping).
FROM ubuntu:22.04

ARG QT_VERSION=6.8.2
ARG EMSDK_VERSION=3.1.56
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates xz-utils p7zip-full \
      python3 python3-pip python3-venv \
      build-essential cmake ninja-build \
      libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Emscripten SDK, pinned to the version this Qt release was built against.
RUN git clone --depth 1 https://github.com/emscripten-core/emsdk.git /opt/emsdk \
    && cd /opt/emsdk \
    && ./emsdk install ${EMSDK_VERSION} \
    && ./emsdk activate ${EMSDK_VERSION}

# Qt for WebAssembly plus the matching host Qt (needed for moc/rcc/qmltyperegistrar
# and the qmlimportscanner). --autodesktop pulls the host build automatically.
RUN pip3 install --no-cache-dir aqtinstall
RUN aqt install-qt all_os wasm ${QT_VERSION} wasm_singlethread \
      -O /opt/qt -m qtmultimedia qtshadertools --autodesktop

# aqt does not preserve executable bits on every file; restore them for
# the tools both kits need (qt-cmake, moc/rcc/uic, qmlimportscanner).
RUN chmod -R a+rx /opt/qt/${QT_VERSION}/*/bin /opt/qt/${QT_VERSION}/*/libexec

ENV QT_VERSION=${QT_VERSION}
ENV QT_WASM=/opt/qt/${QT_VERSION}/wasm_singlethread
ENV QT_HOST=/opt/qt/${QT_VERSION}/gcc_64
ENV PATH="${QT_WASM}/bin:${QT_HOST}/bin:${PATH}"

WORKDIR /src
COPY build.sh /usr/local/bin/qtamp-wasm-build
RUN chmod +x /usr/local/bin/qtamp-wasm-build

# Default: build whatever is mounted at /src into /src/build-wasm/dist.
ENTRYPOINT ["/usr/local/bin/qtamp-wasm-build"]
