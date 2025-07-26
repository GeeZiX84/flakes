{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    download-buffer-size = 1048576000;
    connect-timeout = 30;
    timeout = 3000;
  };

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [ super.systemd ];
      });
    })
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "nvidia" ];

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "ru_RU.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  networking = {
    hostName = "nixos-hypr";
    networkmanager.enable = true;
    wireguard.enable = true;
    extraHosts = builtins.readFile /etc/nixos/hosts.txt;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  services.resolved.enable = true;
  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    sway.enable = true;
    zsh.enable = true;
  };

  services.xserver = {
    enable = true;
    displayManager = {
      gdm.enable = false;
      sddm.enable = true;
      # autoLogin.enable = true;
      # autoLogin.user = "geezix";
    };
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
    vim wget curl unzip git gcc meson
    kitty foot
    rofi rofi-wayland wofi
    waybar swww swaylock
    brightnessctl
    pavucontrol pamixer
    pciutils vulkan-tools glxinfo wlroots
    wl-clipboard wayland-protocols wayland-utils
    dunst libnotify
    ungoogled-chromium
    networkmanagerapplet
    busybox scdoc
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xwayland
    systemd
    iptables dnsutils
    wireguard-tools iproute2
  ];

  fonts.fonts = with pkgs; [
    nerd-fonts._0xproto
    meslo-lgs-nf
  ];

  # Добавление WARP (WireGuard) как systemd unit
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
