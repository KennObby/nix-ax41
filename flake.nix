{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, sops-nix }:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.nix-ax41 = lib.nixosSystem {
      inherit system;
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix

        # sops-nix module
        sops-nix.nixosModules.sops

        # host-local sops config
        {
          # Store host age key here:
          sops.age.keyFile = "/var/lib/sops-nix/key.txt";
          # Default secrets file:
          sops.defaultSopsFile = ./secrets/secrets.yaml;
        }
      ];
    };
  };
}
