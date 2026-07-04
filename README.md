# qtamp-wasm-builder

Reproducible build container for compiling [qtamp](https://github.com/qtamp/qtamp),
the reference player for the [qtWasabi](https://github.com/qtWasabi/qtWasabi)
Modern skin engine, to **WebAssembly**. It powers the live in-browser player
in the hero of [qtamp.org](https://qtamp.org).

## What it is

A Docker image that ships a matched
[Emscripten](https://emscripten.org) + [Qt for WebAssembly](https://doc.qt.io/qt-6/wasm.html)
toolchain. The Qt release and its required Emscripten version are a matched
pair (`ARG QT_VERSION` / `ARG EMSDK_VERSION` in the Dockerfile); Qt for
WebAssembly and the matching host Qt (for moc/rcc and the QML tools) are both
installed via [aqtinstall](https://github.com/miurahr/aqtinstall).

## Usage

```sh
docker build -t qtamp-wasm-builder .

# Mount a qtamp checkout (with its qtWasabi submodule) and build it.
docker run --rm -v /path/to/qtamp:/src qtamp-wasm-builder
# -> /path/to/qtamp/build-wasm/dist/{qtamp.html,.js,.wasm,...}
```

The container fetches the user-supplied Wasabi source tree from the public
archive.org mirror at build time (never redistributed; see the qtamp
licensing notes), then configures with `qt-cmake` and `QTAMP_WASM=ON`.

## License

MIT. See [`LICENSE`](LICENSE). The toolchains it installs (Emscripten, Qt)
carry their own licenses.
