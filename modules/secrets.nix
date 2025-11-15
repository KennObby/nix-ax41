{ lib, ... }:

let
    secretDir = ../secrets;
    dir = builtins.readDir  secretDir;

    yamlFiles = lib.filterAttrs (_name: type: type == "regular") dir;
    yamlNames = lib.filter (name: lib.hasSuffix ".yaml" name) (builtins.attrNames yamlFiles);
in
{
    sops.secrets =
        lib.genAttrs yamlNames (name: {
            sopsFile = "${secretDir}/${name}";
        });
}
