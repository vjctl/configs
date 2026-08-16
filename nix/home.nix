{ pkgs, ... }:

{
  # Bump only when HM docs say to; this tracks state migrations, not package versions.
  home.stateVersion = "25.11";

  # Disable options.json generation to avoid Nix string-context warning
  manual.manpages.enable = false;
  manual.html.enable = false;
  manual.json.enable = false;

  home.packages = with pkgs; [
    aws-vault
    awscli2
    git
    k9s
    kubectl
    kubectx
    pgcli
    pomerium-cli
    starship
    stern
  ];

  programs.home-manager.enable = true;
}
