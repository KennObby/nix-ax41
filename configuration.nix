{ config, pkgs, lib, ... }:

{
    imports = [ ./hardware-configuration.nix ];

    boot.loader.grub = {
        enable = true;
        devices = [ "/dev/nvme0n1" "/dev/nvme1n1" ];   # Install GRUB on the first disk
        forceInstall = true;
        useOSProber = false;
    };

    networking = {
        hostName = "nix-ax41";
        useDHCP = true;
        firewall = {
            enable = true;
            allowedTCPPorts = [ 22 80 443 53 ];
        };
    };

    time.timeZone = "Europe/Brussels";

    i18n.defaultLocale = "en_US.UTF-8";
    console.keyMap = "us";

    services.openssh = {
        enable = true;
        settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        };
    };
    boot.swraid.enable = true;
    boot.swraid.mdadmConf = "
            MAILADDR devopsincoming@gmail.com
            ARRAY /dev/md126 metadata=1.2 name=backup:md126 UUID=e8039f71-f630-44be-bad6-c6ecca498b5d
            ARRAY /dev/md127 metadata=1.2 name=boot:md127 UUID=92782dfb-8c1e-4a8f-994d-42ef2f77ee0b
    ";
    users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAi4HWZEDhnICeZtwS4i4kaXqxtFvoddlnbHZsLSBCH4 hetzner-nixos 2025-11-11"
    ];

    users.users.b_water = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHe5nRFLPOeEEkC8/kuZ+DHv4hK1AC0Xh5OXSkwMsngN"
        ];
    };

    users.groups.wwwrun = { };
    users.users.wwwrun = {
        isSystemUser = true;
        group = "wwwrun";
        description = "Web server user (for Zabbix PHP-FPM)";
    };

    swapDevices = [
        { device = "/dev/md126"; }
    ];

    services.qemuGuest.enable = true;
    console.earlySetup = true;
    boot.kernelParams = [ "Console=ttyS0,115200" "panic=30" ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    environment.systemPackages = with pkgs; [
        git neovim sops age kitty docker kubernetes openshift
        wget curl zsh-powerlevel10k nodejs_24
    ];
    system.stateVersion = "25.05";
}
