{
  description = "devops";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        darwinBuildDeps = [
            pkgs.darwin.apple_sdk.frameworks.CoreServices
            pkgs.darwin.apple_sdk.frameworks.Security
          ];
      in rec {
        devShell = with pkgs; mkShell {
          name = "devops";

          buildInputs = [
            toybox
            kafkactl
            kapp
            kn
            ytt
          ] ++ lib.optionals stdenv.isDarwin darwinBuildDeps;

          shellHook = ''
            tmpcfg=/tmp/devops-$(${toybox}/bin/uuidgen)
            mkdir -p $tmpcfg
            cp "${self}/aws-vault.cfg" $tmpcfg
            cp "${self}/kubeconfig.yaml" $tmpcfg
            cp "${self}/docker.json" $tmpcfg
            chmod +w $tmpcfg/*
            export \
              AWS_CONFIG_FILE="$tmpcfg/aws-vault.cfg" \
              KUBECONFIG="$tmpcfg/kubeconfig.yaml" \
              DOCKER_CONFIG="$tmpcfg/docker"

            trap "rm -rf $tmpcfg" EXIT
          '';
        };

      }
    );
}
