{ config, pkgs, lib, modulesPath, hyprland, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.download-buffer-size = 1048576000;
  nix.settings.connect-timeout = 30;
  nix.settings.timeout = 3000;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.overrideAttrs (oldAttrs: {
        buildInputs = (oldAttrs.buildInputs or []) ++ [ super.systemd ];
      });
    })
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "nvidia" ];

  networking.hostName = "nixos-hypr";
  networking.networkmanager.enable = true;
  networking.extraHosts = builtins.readFile ../../etc/hosts.txt;
  networking.wireguard.enable = true;

  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "ru_RU.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.xserver = {
    enable = true;
    layout = "us,ru";
    xkbOptions = "grp:alt_shift_toggle";
    videoDrivers = [ "nvidia" ];
    displayManager.sddm.enable = true;
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

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprland.packages.${pkgs.system}.hyprland;
  };

  programs.sway.enable = true;
  programs.zsh.enable = true;

  users.users.geezix = {
    isNormalUser = true;
    description = "geezix";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    initialPassword = "geezpass";
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    vim wget curl unzip hyprland swww
    xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xwayland
    pavucontrol pamixer brightnessctl pciutils vulkan-tools glxinfo
    wireguard-tools iproute2 swaylock waybar rofi systemd iptables
    dnsutils gcc meson wayland-protocols wayland-utils wl-clipboard wlroots
     firefox ungoogled-chromium busybox scdoc mpv dunst libnotify git
    kitty foot networkmanagerapplet neovim vscode rofi-wayland wofi
  ];

  fonts.fonts = with pkgs; [ nerd-fonts._0xproto meslo-lgs-nf ];

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
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

  # Optional autologin setup
  # services.displayManager.autoLogin.enable = true;
  # services.displayManager.autoLogin.user = "geezix";

  system.stateVersion = "25.05";
}
