{config, pkgs, lib, ...}:

{
    security.acme = {
        acceptTerms = true;
        defaults.email = "devopsincoming@gmail.com";

        certs."grafana.devopsincoming.com" = {
            extraDomainNames = [
                "zabbix.devopsincoming.com"
                "prometheus.devopsincoming.com"
                "loki.devopsincoming.com"
            ];
        };
    };

    services.nginx = {
        enable = true;
        user = "wwwrun";
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        virtualHosts = {
            "grafana.devopsincoming.com" = {
                enableACME = true;
                forceSSL = true;
                locations."/" = {
                    proxyPass = "http://127.0.0.1:3000/";
                };
            };

            "prometheus.devopsincoming.com" = {
                enableACME = true;
                forceSSL = true;
                locations."/" = {
                    proxyPass = "http://127.0.0.1:9090";
                };
            };

            "zabbix.devopsincoming.com" = {
                enableACME = true;
                forceSSL  = true;

                root = "/nix/store/nwsrwrb8y848iis44vailvpbr23yhzbx-zabbix-web-6.0.36/share/zabbix";

                # Default location: serve PHP frontend
                locations."/" = {
                    index = "index.php";
                    tryFiles = "$uri $uri/ /index.php?$args";
                };

                # PHP handling for Zabbix frontend
                locations."~ \\.php$" = {
                    extraConfig = ''
                        include ${pkgs.nginx}/conf/fastcgi.conf;
                        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                        fastcgi_pass unix:/run/phpfpm/zabbix.sock;
                    '';
                };
            };
        };
    };
}
