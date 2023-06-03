# Cross-compiling Go with Zig

This project demonstrates how to use [`zig`](https://ziglang.org/)
as a cross-compiler to build statically linked `go` binaries when using `CGO`
(e.g. [sqlite3](https://github.com/mattn/go-sqlite3)).

The binaries we build work on Linux, macOS, and Windows on both `x86_64` (`amd64`)
and `aarch64` (`arm64`) architectures.

[main.go](./main.go) runs a simple select statement obtaining the version
of sqlite we link with.

[Makefile](./Makefile) shows how to build binaries for the various platforms.

# Build instructions

1. Install [`zig`](https://ziglang.org/) and ensure the `zig` binary is in
   visible `PATH`.

2. Run `git submodule init && git submodule update`.
   This fetches https://github.com/hexops/sdk-macos-12.0 which contains the
   macOS SDK whose headers we need when cross-compiling for macOS. This is
   useful if you want to build macOS binaries from other platforms (e.g. Linux).

   If you are building on macOS then you don't need this.

3. Run `make build`.  The first time this is invoked will be slow.
   Subsequent runs are **much** faster.

# What to expect

```shell
> zig version
0.11.0-dev.3348+3faf376b0


> go version
go version go1.20.4 darwin/arm64

> make
go run .
2023/06/03 15:16:05 sqlite version: 3.42.0


> make build
# lots of output and some warnings

> exa -l bin/
.rwxr-xr-x 3.9M jonathan  3 Jun 15:15 demo.darwin.amd64
.rwxr-xr-x 3.7M jonathan  3 Jun 15:15 demo.darwin.arm64
.rwxr-xr-x  13M jonathan  3 Jun 15:15 demo.linux.amd64
.rwxr-xr-x  13M jonathan  3 Jun 15:15 demo.linux.arm64
.rwxr-xr-x 7.5M jonathan  3 Jun 15:15 demo.windows.amd64
.rwxr-xr-x 7.3M jonathan  3 Jun 15:15 demo.windows.arm64


> file bin/*
bin/demo.darwin.amd64:  Mach-O 64-bit executable x86_64
bin/demo.darwin.arm64:  Mach-O 64-bit executable arm64
bin/demo.linux.amd64:   ELF 64-bit LSB executable, x86-64, version 1 (SYSV), static-pie linked, Go BuildID=zt5fjDLBfRocGoyJXVhH/oAFtc7JEapmKJeZkspEG/4yP4WXg5-ZZ1e4I-eU4y/2_uUjRkYn0pEsK3Eo4u5, with debug_info, not stripped
bin/demo.linux.arm64:   ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), static-pie linked, Go BuildID=bjkr2DjkVwy-qM6drUcW/_cJqPYZUdrMTXzhyeZBA/Ojl7Mr8VPNV8XdZkZH_N/VsyO3eN8-DBs5RFcwkRw, with debug_info, not stripped
bin/demo.windows.amd64: PE32+ executable (console) x86-64, for MS Windows
bin/demo.windows.arm64: PE32+ executable (console) Aarch64, for MS Windows


# macOS M1/aarch64 (arm64)
> otool -L bin/demo.darwin.*
bin/demo.darwin.amd64:
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1292.100.5)
bin/demo.darwin.arm64:
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1292.100.5)
	/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation (compatibility version 150.0.0, current version 1853.0.0)
> ./bin/demo.darwin.arm64
2023/06/03 16:07:28 sqlite version: 3.42.0


# Alpine aarch64 (arm64)
> podman run --rm -it -w /app -v "$PWD":/app alpine
/app # uname -mo
aarch64 Linux
/app # ldd bin/demo.linux.amd64
	/lib/ld-musl-aarch64.so.1 (0xffff80588000)
/app # ldd bin/demo.linux.arm64
	/lib/ld-musl-aarch64.so.1 (0xffff80979000)
/app # ./bin/demo.linux.arm64
2023/06/03 22:08:06 sqlite version: 3.42.0


# Debian aarch64 (arm64)
> podman run --rm -it -w /app -v "$PWD":/app debian ./bin/demo.linux.arm64
2023/06/03 22:09:30 sqlite version: 3.42.0


# Debian x86_64 (amd64)
> podman run --rm -it -w /app -v "$PWD":/app amd64/debian ./bin/demo.linux.amd64
WARNING: image platform (linux/amd64) does not match the expected platform (linux/arm64)
2023/06/03 22:09:48 sqlite version: 3.42.0
```

# Exercise for the reader

1. Run the binaries on windows
2. Get cross-platform builds going with [goreleaser](https://goreleaser.com/).

<details>
<summary>Sneak peek:</summary>

```yaml
builds:
  - env:
      - CGO_ENABLED=1
      - >-
        {{- if eq .Os "linux" }}
          {{- if eq .Arch "amd64" }}CC=zig cc -target x86_64-linux-musl{{- end }}
          {{- if eq .Arch "arm64" }}CC=zig cc -target aarch64-linux-musl{{- end }}
        {{- else if eq .Os "windows" }}
          {{- if eq .Arch "amd64" }}CC=zig cc -target x86_64-windows{{- end }}
          {{- if eq .Arch "arm64" }}CC=zig cc -target aarch64-windows{{- end }}
        {{- else if eq .Os "darwin" }}
          {{- if eq .Arch "amd64" }}CC=zig cc -target x86_64-macos -F./resources/sdk-macos-12.0/root/System/Library/Frameworks{{- end }}
          {{- if eq .Arch "arm64" }}CC=zig cc -target aarch64-macos -F./resources/sdk-macos-12.0/root/System/Library/Frameworks{{- end }}
        {{- end }}
    goos:
      - linux
      - windows
      - darwin
    goarch:
      - arm64
      - amd64
```
</details>

# Thanks 

* Prior art for using Zig as a cross-compiler: [Loris Cro](https://github.com/kristoff-it)'s
[article](https://zig.news/kristoff/building-sqlite-with-cgo-for-every-os-4cic).
  Check the details in the article for why we omit debug info for the macOS binaries.
* Addition of `-buildmode=pie` for macOS targets: https://github.com/ziglang/zig/issues/15439
* Linking against macOS SDK: https://github.com/ziglang/zig/issues/1349
