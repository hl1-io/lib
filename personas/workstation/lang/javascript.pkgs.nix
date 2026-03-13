{ pkgs }:
with pkgs; [
  bun
  nodejs_22
  pnpm_8

  nodePackages_latest.typescript-language-server
  svelte-language-server
  vscode-langservers-extracted
]
