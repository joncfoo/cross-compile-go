.PHONY: run-native build bin/*

export CGO_ENABLED=1

run-native:
	go run .

build: \
	bin/demo.windows.amd64 \
	bin/demo.windows.arm64 \
	bin/demo.darwin.amd64 \
	bin/demo.darwin.arm64 \
	bin/demo.linux.amd64 \
	bin/demo.linux.arm64

bin/demo.windows.amd64:
	GOOS=windows GOARCH=amd64 CC="zig cc -target x86_64-windows" \
		go build -o $@ ./

bin/demo.windows.arm64:
	GOOS=windows GOARCH=arm64 CC="zig cc -target aarch64-windows" \
		go build -o $@ ./

bin/demo.darwin.amd64:
	GOOS=darwin GOARCH=amd64 CC="zig cc -target x86_64-macos -F./resources/sdk-macos-12.0/root/System/Library/Frameworks" \
		go build -o $@ -ldflags="-s -w" ./

bin/demo.darwin.arm64:
	GOOS=darwin GOARCH=arm64 CC="zig cc -target aarch64-macos -F./resources/sdk-macos-12.0/root/System/Library/Frameworks" \
		go build -o $@ -ldflags="-s -w" ./

bin/demo.linux.amd64:
	GOOS=linux GOARCH=amd64 CC="zig cc -target x86_64-linux-musl" \
		go build -o $@ ./

bin/demo.linux.arm64:
	GOOS=linux GOARCH=arm64 CC="zig cc -target aarch64-linux-musl" \
		go build -o $@ ./
