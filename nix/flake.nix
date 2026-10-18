{
  description = "Nixify Mac with nix-darwin and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    pi.url = "github:earendil-works/pi/v1.3.0";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, pi }:
  let
    sudoUser = builtins.getEnv "SUDO_USER";
    username =
      if sudoUser != "" then sudoUser else builtins.getEnv "USER";
    hostname = builtins.getEnv "NIX_DARWIN_HOSTNAME";
    system = "aarch64-darwin";
  in
  {
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system;
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ pi.overlays.default ];
          nixpkgs.config.allowUnfree = true;
          nix.settings.experimental-features = "nix-command flakes";
          nix.enable = false;

          # Enable TouchID for sudo in Terminal
          security.pam.services.sudo_local.touchIdAuth = true;

          # Enable zsh system-wide
          programs.zsh.enable = true;

          users.users.${username}.home = "/Users/${username}";
          users.users.root.home = "/var/root";
          system.primaryUser = username;
          system.stateVersion = 5;

          # Fonts
          fonts.packages = with pkgs; [
            nerd-fonts.ubuntu-mono
          ];

          # Homebrew
          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              upgrade = true;
              cleanup = "zap";
            };

            taps = [];

            brews = [
              "herdr"
            ];

            casks = [
              "1password"
              "docker-desktop"
              "google-chrome"
              "grammarly-desktop"
              "thaw"
              "microsoft-outlook"
              "microsoft-teams"
              "notunes"
              "rectangle"
              "slack"
              "zed"
            ];
          };
        })

        # HOME MANAGER (CLI Tools & Shell)
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${username} = { pkgs, ... }: {
            home.stateVersion = "26.11";
            home.sessionVariables = {
              HOMEBREW_NO_AUTO_UPDATE = "1";
              HOMEBREW_NO_ENV_HINTS = "1";
            };
            manual.manpages.enable = false;
            manual.html.enable = false;
            manual.json.enable = false;

            # # Dotfile Symlinks
            # xdg.configFile = {
            #   "herdr/config.toml".source = ./sources/herdr/config.toml;
            #   "starship.toml".source = ./sources/starship/starship.toml;
            # };

            # Nix Packages
            home.packages = with pkgs; [
              awscli2
              azure-cli
              docker-credential-helpers
              eksctl
              gnupg
              imagemagick
              jq
              k9s
              kubecolor
              kubectl
              kubernetes-helm
              nodejs_22
              pgcli
              pkgs.pi
              pomerium-cli
              uv
              watch
              wget
              yq-go
            ];

            # Git
            programs.git = {
              enable = true;
              lfs.enable = true;
              settings = {
                include.path = "~/.config/git/config.local";
                http = {
                  sslCAInfo = "/etc/ssl/certs/ca-certificates.crt";
                  sslBackend = "openssl";
                };
                core = {
                  hooksPath = "~/.config/git/hooks";
                  excludesfile = "~/.config/git/ignore";
                };
                fetch.prune = true;
                credential.gitHubAccountFiltering = false;
                commit.gpgsign = true;
                init.defaultBranch = "main";
                push.autoSetupRemote = true;
              };
            };

            # GitHub CLI
            programs.gh = {
              enable = true;
            };

            # Zsh
            programs.zsh = {
              enable = true;
              enableCompletion = true;
              autosuggestion.enable = true;
              syntaxHighlighting.enable = true;
              shellAliases = {
                k = "kubecolor";
                kubectl = "kubecolor";
                tg = "terragrunt";
                tf = "terraform";
                dev = "cd $HOME/devel";
                refresh = "source $HOME/.zshrc";
                rc = "code -e \"$HOME/.zshrc.local\"";
              };
              initContent = ''
                eval "$(/opt/homebrew/bin/brew shellenv zsh)"
                eval "$(herdr completion zsh)"
                alias code=zed
                if [[ -f "$HOME/.zshrc.local" ]]; then
                  source "$HOME/.zshrc.local"
                fi
              '';
            };

            # Starship
            programs.starship = {
              enable = true;
              enableZshIntegration = true;
            };

            # Direnv
            programs.direnv = {
              enable = true;
              enableZshIntegration = true;
              nix-direnv.enable = true;
            };
          };
        }
      ];
    };
  };
}
