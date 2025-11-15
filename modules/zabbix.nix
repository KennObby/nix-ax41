{ config, pkgs, lib, ...}:

{

    sops.secrets."zabbix_db_password" = {
        sopsFile = ../secrets/zabbix.yaml;
        owner = "zabbix";
        group = "zabbix";
        mode = "0400";
    };

    services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        settings.mysqld = {
            "bind-address" = "127.0.0.1";
            port = 3306;
        };
    };

    services.zabbixServer = {
        enable = true;
        
        database = {
            type = "mysql";
            host = "127.0.0.1";
            port = 3306;
            name = "zabbix";
            user = "zabbix";
            passwordFile = config.sops.secrets."zabbix_db_password".path;
            createLocally = false;
            };
        };

    services.zabbixAgent = {
        enable = true;
        server = "localhost";
    };

    services.zabbixWeb = {
        enable = true;
        hostname = "zabbix.nix-ax41.io";

        nginx.virtualHost = {
            serverName = "zabbix.nix-ax41.io";
            serverAliases = [ "zabbix" ];
            enableACME = true;
            forceSSL = true;
        };
        database = {
            type = "mysql";
            host = "127.0.0.1";
            name = "zabbix";
            user = "zabbix";
            passwordFile = config.sops.secrets."zabbix_db_password".path;
            port = 3306;
        };

    };
    services.httpd = lib.mkForce {
        enable = false;
    };
    time.timeZone = "Europe/Brussels";
}
