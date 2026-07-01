# Nix development shell configuring Prisma engines and environment paths dynamically.
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [ pkgs.prisma-engines ];

  shellHook = ''
    export PRISMA_SCHEMA_ENGINE_PATH="${pkgs.prisma-engines}/bin/schema-engine"
    export PRISMA_QUERY_ENGINE_LIBRARY="$PWD/server/passenger-service/node_modules/@prisma/engines/libquery_engine-linux-nixos.so.node"
  '';
}
