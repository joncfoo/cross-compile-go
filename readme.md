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
> make
go run .
2023/06/03 15:16:05 sqlite version: 3.42.0

> make build
GOOS=windows GOARCH=amd64 CC="zig cc -target x86_64-windows" \
		go build -o bin/demo.windows.amd64 ./
GOOS=windows GOARCH=arm64 CC="zig cc -target aarch64-windows" \
		go build -o bin/demo.windows.arm64 ./
GOOS=darwin GOARCH=amd64 CC="zig cc -target x86_64-macos -F./resources/sdk-macos-12.0/root/System/Library/Frameworks" \
		go build -o bin/demo.darwin.amd64 -ldflags="-s -w" ./
warning: unsupported linker arg: -no_pie
GOOS=darwin GOARCH=arm64 CC="zig cc -target aarch64-macos -F./resources/sdk-macos-12.0/root/System/Library/Frameworks" \
		go build -o bin/demo.darwin.arm64 -ldflags="-s -w" ./
GOOS=linux GOARCH=amd64 CC="zig cc -target x86_64-linux-musl" \
		go build -o bin/demo.linux.amd64 ./
GOOS=linux GOARCH=arm64 CC="zig cc -target aarch64-linux-musl" \
		go build -o bin/demo.linux.arm64 ./

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
bin/demo.linux.amd64:   ELF 64-bit LSB executable, x86-64, version 1 (SYSV), static-pie linked, Go BuildID=P5a6UwCSQIJgaPqjyWkr/39wTGQRqh1WrihL7R3QD/GxN2OqNYpjYMH5ovTVlj/GkHa-s4_yopB88O4KO9T, with debug_info, not stripped
bin/demo.linux.arm64:   ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), static-pie linked, Go BuildID=y1yKGLsR5RtMIcGpeEXF/zqr56jGA9-4KxXFNZzPZ/RC6eqTq8k-09QMpq1NDc/ExeJsdCIc3fPZeZI5X8C, with debug_info, not stripped
bin/demo.windows.amd64: PE32+ executable (console) x86-64, for MS Windows
bin/demo.windows.arm64: PE32+ executable (console) Aarch64, for MS Windows

# I'm using macOS here (M1/aarch64)
> otool -L bin/demo.darwin.*
bin/demo.darwin.amd64:
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1292.100.5)
bin/demo.darwin.arm64:
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1292.100.5)
	/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation (compatibility version 150.0.0, current version 1853.0.0)

# Running in linux with Alpine (aarch64)
> podman run --rm -it -w /app -v "$PWD":/app alpine
/app # ldd bin/demo.linux.amd64
	/lib/ld-musl-aarch64.so.1 (0xffff95a18000)
/app # ldd bin/demo.linux.arm64
	/lib/ld-musl-aarch64.so.1 (0xffffb7b09000)
/app # ./bin/demo.linux.arm64
2023/06/03 21:28:50 sqlite version: 3.42.0

# Running in linux with Debian (aarch64)
> podman run --rm -it -w /app -v "$PWD":/app debian
root@d8d73ca7a3d3:/app# ldd bin/demo.linux.a*
bin/demo.linux.amd64:
	not a dynamic executable
bin/demo.linux.arm64:
	statically linked
```

# Exercise for the reader

Get this working with [goreleaser](https://goreleaser.com/).

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

Prior art for using Zig as a cross-compiler goes to [Loris Cro](https://github.com/kristoff-it)'s
[article](https://zig.news/kristoff/building-sqlite-with-cgo-for-every-os-4cic).

Check the details in the article for why we omit debug info for the macOS binaries.
