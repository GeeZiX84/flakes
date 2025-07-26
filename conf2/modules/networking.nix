{ config, pkgs, ... }:

{
  networking.wireguard.enable = true;

  # Автоматически копируем твой warp-конфиг wg-warp.conf в /etc/wireguard
  systemd.tmpfiles.rules = [
    "z /etc/wireguard/wg-warp.conf 0600 root root - -"
  ];

  # Для корректных прав нужно, чтобы файл лежал в корне /etc/nixos (или собрать в другой директории)
  environment.etc."wireguard/wg-warp.conf".source = ./wg-warp.conf;
}
