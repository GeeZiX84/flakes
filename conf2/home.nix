/*
Flake-based NixOS configuration for flash drive setup with Hyprland and Sway,
refactored from the original non-flake configuration, preserving all previous functionality,
adding Home Manager support and modular structure.
*/

{
  description = "NixOS + Hyprland + Sway flake setup for USB installation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.nixos-hypr = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          ./hosts/nixos-hypr/configuration.nix
          home-manager.nixosModules.home-manager
        ];
        specialArgs = { inherit self pkgs hyprland; };
      };

      homeConfigurations.geezix = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs;
        modules = [
          ./home/geezix/home.nix
        ];
        extraSpecialArgs = { inherit hyprland pkgs; };
        # Version sync with your actual nixpkgs (25.05)
        configuration = {
          home.stateVersion = "25.05";
        };
      };
    };
}
