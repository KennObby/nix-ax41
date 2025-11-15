{
    description = "nix-ax-41 NixOS config";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
            ./configuration.nix
            ./modules/observability.nix
            ./modules/zabbix.nix
            ./modules/fail2ban.nix
            ./modules/nginx.nix
            ./modules/dns.nix
            #./modules/wazuh.nix

            # sops-nix module
            sops-nix.nixosModules.sops

            # host-local sops config
            {
                # Store host age key here:
                sops.age.keyFile = "/var/lib/sops-nix/key.txt";
            }
        ];
    };
};
}
