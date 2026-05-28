{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      perSystem = { system, config, pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.esphome
              inputs.agenix.packages.${system}.default
              pkgs.clang-tools # daje clangd
              pkgs.gcc
              pkgs.gnumake
              pkgs.python3
            ];
            inputsFrom = [
              config.treefmt.build.devShell
            ];

            # Decrypt secrets.yaml.age once per shell into a tmpfs file,
            # then symlink $PWD/secrets.yaml -> that path so esphome's
            # native `!secret` resolution finds it. Plaintext stays on
            # tmpfs; the symlink in $PWD is gitignored.
            shellHook = ''
              _tmpfs_secrets="''${XDG_RUNTIME_DIR:-/tmp}/boneio-secrets.yaml"
              _repo_secrets="$PWD/secrets.yaml"
              _age_identity="''${AGE_IDENTITY:-$HOME/.ssh/id_ed25519}"
              if [ -e "$_repo_secrets" ] && [ ! -L "$_repo_secrets" ]; then
                echo "boneio-esp-1: $_repo_secrets exists and is not a symlink — refusing to overwrite" >&2
              elif [ ! -r "$_age_identity" ] || [ ! -f "$PWD/secrets.yaml.age" ]; then
                echo "boneio-esp-1: skipping secret decryption ($_age_identity or secrets.yaml.age missing)" >&2
              elif (umask 077 && ${pkgs.age}/bin/age -d -i "$_age_identity" "$PWD/secrets.yaml.age" > "$_tmpfs_secrets"); then
                ln -sf "$_tmpfs_secrets" "$_repo_secrets"
                # Skip the cleanup trap under direnv: it would replace direnv's
                # own EXIT trap (which runs `direnv dump`), losing PATH and all
                # other devshell exports — and it would fire immediately when
                # the .envrc subshell exits, removing the freshly-created symlink.
                if [ -z "''${DIRENV_IN_ENVRC:-}" ]; then
                  trap "rm -f '$_repo_secrets' '$_tmpfs_secrets'" EXIT
                fi
              else
                echo "boneio-esp-1: failed to decrypt secrets.yaml.age" >&2
                rm -f "$_tmpfs_secrets"
              fi
              unset _tmpfs_secrets _repo_secrets _age_identity
            '';
          };

          treefmt.config = {
            projectRootFile = "flake.nix";

            programs = {
              nixpkgs-fmt.enable = true;
              # yamlls uses prettier under the hood but it might change https://github.com/redhat-developer/yaml-language-server/issues/933
              prettier.enable = true;
            };
          };
        };
    };
}

