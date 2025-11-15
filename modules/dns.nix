{ config, pkgs, ...}:

{
    services.nsd = {
        enable = false;

        interfaces = [ "0.0.0.0" "::"];

        zones = {
            "nix-ax41.io" = {
                data = builtins.readFile ../zones/nix-ax41.io.zone;
            };
        };
    };
}
