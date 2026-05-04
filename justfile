RUST_DIR := "rust_builder"

default:
    @just --list

gen:
    flutter_rust_bridge_codegen generate

watch:
    flutter_rust_bridge_codegen generate --watch

clean:
    flutter clean
    cd {{RUST_DIR}} && cargo clean
    flutter pub get

update:
    flutter pub upgrade
    cd {{RUST_DIR}} && cargo update

watch-flutter:
    dart run build_runner watch --delete-conflicting-outputs
