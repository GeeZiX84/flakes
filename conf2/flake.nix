{
  description = "NixOS config with Hyprland, WARP from notmalware, Waybar fix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    nixosConfigurations.nixos-hypr = nixpkgs.lib.nixosSystem {
      system = system;
      modules = [
        ./modules/networking.nix
        ./hardware-configuration.nix

        # базовый конфиг, добавим нужное сюда
        {
          imports = [ home-manager.nixosModules.home-manager ];

          nixpkgs.config.allowUnfree = true;

          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          boot.kernelModules = [ "nvidia" ];

          time.timeZone = "Europe/Moscow";

          i18n.defaultLocale = "ru_RU.UTF-8";

          console.font = "Lat2-Terminus16";
          console.useXkbConfig = true;

          networking.hostName = "nixos-hypr";
          networking.networkmanager.enable = true;
          networking.extraHosts = builtins.readFile ./hosts.txt;

          services.openssh.enable = true;
          services.openssh.settings.PermitRootLogin = "no";
          services.openssh.settings.PasswordAuthentication = true;

          services.resolved.enable = true;
          services.dbus.enable = true;

          xdg.portal.enable = true;
          xdg.portal.wlr.enable = true;
          xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

          programs.hyprland = {
            enable = true;
            xwayland.enable = true;
          };

          programs.sway.enable = true;
          programs.zsh.enable = true;

          services.xserver = {
            enable = true;
            displayManager.gdm.enable = false;
            displayManager.sddm.enable = true;
            layout = "us,ru";
            xkbOptions = "grp:alt_shift_toggle";
            videoDrivers = [ "nvidia" ];
          };

          hardware.opengl.enable = true;
          hardware.nvidia = {
            open = true;
            modesetting.enable = true;
            package = config.boot.kernelPackages.nvidiaPackages.stable;
            prime = {
              offload.enable = true;
              sync.enable = false;
              intelBusId = "PCI:0:2:0";
              nvidiaBusId = "PCI:1:0:0";
            };
          };

          services.pipewire = {
            enable = true;
            alsa.enable = true;
            pulse.enable = true;
            jack.enable = true;
          };
          hardware.pulseaudio.enable = false;
          security.rtkit.enable = true;

          users.users.geezix = {
            isNormalUser = true;
            description = "geezix";
            shell = pkgs.zsh;
            extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
          };

          environment.sessionVariables = {
            NIXOS_OZONE_WL = "1";
          };

          environment.systemPackages = with pkgs; [
            vim wget curl unzip git neovim gcc meson kitty foot rofi rofi-wayland wofi
            waybar swww swaylock brightnessctl pavucontrol pamixer pciutils vulkan-tools glxinfo
            wlroots wl-clipboard wayland-protocols wayland-utils dunst libnotify brave firefox
            ungoogled-chromium networkmanagerapplet busybox scdoc xdg-desktop-portal-gtk
            xdg-desktop-portal-hyprland xwayland systemd iptables dnsutils wireguard-tools iproute2
          ];

          fonts.fonts = with pkgs; [
            nerd-fonts._0xproto meslo-lgs-nf
          ];

          nixpkgs.overlays = [
            (self: super: {
              waybar = super.waybar.overrideAttrs (old: {
                buildInputs = (old.buildInputs or []) ++ [ super.systemd ];
              });
            })
          ];

          # WARP WireGuard systemd service
          systemd.services.wg-warp = {
            description = "WARP WireGuard Tunnel";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up wg-warp";
              ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down wg-warp";
            };
          };

          system.stateVersion = "25.05";
        }

        # Home Manager для geezix
        home-manager.nixosModules.home-manager
      ];

      # Home Manager user config
      specialArgs = {
        inherit home-manager;
      };
    };

    homeConfigurations.geezix = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      system = system;
      username = "geezix";
      homeDirectory = "/home/geezix";

      modules = [
        {
          programs.zsh.enable = true;

          # Можно добавить конфиг rofi, kitty, swaylock и др. здесь
        }
      ];
    };
  };
}
