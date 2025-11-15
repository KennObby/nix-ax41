{ lib, config, pkgs, ...}:

{
    security.auditd.enable = true;

    services.fail2ban = {
        enable = true;
        jails.sshd = lib.mkForce {
            settings = {
                enabled = "true";
                port = "ssh";
                filter = "sshd";
                backend = "systemd";
                maxretry = "5";
            };
        };
    };
}
