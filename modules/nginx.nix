{config, pkgs, lib, ...}:

{
    security.acme = {
        acceptTerms = true;
        defaults.email = "devopsincoming@gmail.com";
    };

    services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        virtualHosts."grafana.devopsincoming.com" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://127.0.0.1:3000/";
            };
        };

        virtualHosts."prometheus.devopsincoming.com" = {
            enableACME = true;
            forceSSL = true;
            locations."/" = {
                proxyPass = "http://127.0.0.1:9090";
            };
        };
    };
}
