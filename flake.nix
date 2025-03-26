{
  description = "Darwin System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.alacritty
          pkgs.beamMinimal27Packages.elixir
          pkgs.circleci-cli
          pkgs.dotenv-linter
          pkgs.fzf
          pkgs.gh
          pkgs.git
          pkgs.gnumake
          pkgs.gnupg
          pkgs.gnused
          pkgs.go_1_22
          pkgs.gobject-introspection
          pkgs.go-migrate
          pkgs.golangci-lint
          pkgs.google-chrome
          pkgs.graphviz
          pkgs.htop
          pkgs.jdk21_headless
          pkgs.jetbrains.goland
          pkgs.jetbrains.pycharm-community
          pkgs.jetbrains.rust-rover
          pkgs.jq
          pkgs.mkalias
          pkgs.ncurses
          pkgs.neovim
          pkgs.obsidian
          pkgs.oh-my-posh
          pkgs.openssl_3
          pkgs.pinentry_mac
          pkgs.postgresql_14
          pkgs.postman
          pkgs.python311
          pkgs.slack
          pkgs.stow
          pkgs.sqlite
          pkgs.the-unarchiver
          pkgs.terraform
          pkgs.tmux
          pkgs.vegeta
          pkgs.wezterm
          pkgs.zed-editor
          pkgs.zoom-us
          pkgs.zoxide
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        casks = [
          "docker"
          "nordvpn"
        ];
        masApps = {
          "AdGuard for Safari" = 1440147259;
          "Kagi for Safari" = 1622835804;
          "Magnet" = 441258766;
          "Mapper for Safari" = 1589391989;
          "Xcode" = 497799835;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#work
    darwinConfigurations."work" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "jdeal";

            # Automatically migrate existing Homebrew installations
            autoMigrate = true;
          };
        }
      ];
    };
  };
}
