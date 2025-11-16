{ config, pkgs, ... }:

{
    # Prometheus
    services.prometheus = {
        enable = true;
        port = 9090;
        globalConfig.scrape_interval = "15s";
        scrapeConfigs = [
            {
                job_name = "nix-ax41";
                static_configs = [
                    {targets = [ "localhost:9100" ]; }
                ];
            }
        ];
    };

    #Node exporter for metrics
    services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
    };

    #Loki for logs
    services.loki = {
        enable = true;
        configuration = {
            server = { 
                http_listen_port = 3100;
                grpc_listen_port = 19095;
            };
            auth_enabled = false;
            common ={
                ring = {
                    instance_addr = "127.0.0.1";
                    kvstore = {
                        store = "inmemory";
                    };
                };
                replication_factor = 1;
                path_prefix = "/var/lib/loki";
                instance_interface_names = builtins.attrNames config.networking.interfaces; # letting Loki decide whether enp41s0, eth0, lo nor en0 network interface he listens to 
            };

            ingester = {
                lifecycler = {
                    address = "127.0.0.1";
                ring = {
                    kvstore = {
                        store = "inmemory";
                    };
                    replication_factor = 1;
                    };
                };
            };

            limits_config = {
                allow_structured_metadata = false;
            };

            schema_config.configs = [{
                from = "2024-04-01";
                store = "boltdb-shipper";
                object_store = "filesystem";
                schema = "v13";
                index = {
                    prefix = "index_";
                    period = "24h";
                };
            }];
            storage_config = {
                boltdb_shipper = {
                    active_index_directory = "/srv/loki/index";
                    cache_location = "/srv/loki/boltdb-cache";
                };
                filesystem.directory = "/srv/loki/chunks";
            };
        };
    };

    #Promtail agent to ship systemd logs to Loki
    services.promtail = {
        enable = true;
        configuration = {
            server.http_listen_port = 9080;
            clients = [{ url = "http://localhost:3100/loki/api/v1/push";}];
            positions.filename = "/var/lib/promtail/positions.yml";
            scrape_configs = [{
                job_name = "systemd-journal";
                journal = { max_age = "12h"; path = "/var/log/journal/"; };
                relabel_configs = [{
                    source_labels = [ "__journal__systemd_unit" ];
                    target_label = "unit";
                }];
            }];
        };
    };

    #Grafana
    services.grafana = {
        enable = true;
        settings.server = {
            http_addr = "127.0.0.1";
            http_port = 3000;
            domain = "grafana.devopsincoming.com";
            root_url = "http://grafana.devopsincoming.com";
        };
        provision = {
            enable = true;
            datasources = {
                settings = {
                    apiVersion = 1;
                    datasources = [
                        {
                            name = "Prometheus";
                            type = "prometheus";
                            url = "http://localhost:9090";
                            access = "proxy";
                            isDefault = true;
                        }
                        {
                            name = "Loki";
                            type = "loki";
                            url = "http://localhost:3100";
                            access = "proxy";
                        }
                    ];
                };
            };
        };
    };
}
