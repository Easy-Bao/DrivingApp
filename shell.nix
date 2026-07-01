# Nix development shell configuring Prisma engines and environment paths dynamically.
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [ pkgs.prisma-engines_6 ];

  shellHook = ''
    export PRISMA_SCHEMA_ENGINE_PATH="${pkgs.prisma-engines_6}/bin/schema-engine"
    export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines_6}/lib/libquery_engine.node"
  '';
}
