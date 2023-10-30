job bitbucket {
    datacenters = [ "ptc1-development-bitbucket" ]
    group bitbucket {
        count = 1
        update {
            max_parallel        = 1
            min_healthy_time    = 1
        }
        restart {
            attempts = 2
            delay    = "20s"
        }
        task bitbucket {
            template {
                change_mode = "restart"
                data = <<EOH
                jdbc.user = {{with secret "secret/nomad/Bitbucket"}}{{.Data.user}}{{end}}
                jdbc.password   = {{with secret "secret/nomad/Bitbucket"}}{{.Data.password}}{{end}}
                EOH
                env = true
                destination = "secrets/file.env"
            }
            config {
                image           = "https://docker.repo.ihsmarkit.com/markitdigital/base/atlassian/bitbucket-server:7.21.10"
                interactive     = true
                labels {
                    datacenter  = "${meta.DATACENTER}"
                    environment = "${meta.ENVIRONMENT}"
                }
                logging {
                    config {
                        tag = "${NOMAD_JOB_NAME}"
                    }
                    type = "gelf"
                }
                port_map {
                    http = 7990
                }
                tty = true
                mounts = [
					{
						type		= "bind"
						target		= "/var/atlassian/application-data/bitbucket"
						source		= "/bitbucket"
						readonly	= false
					}
				]
                command = "/usr/bin/ls"
                args = [
                "-e jdbc.user=", "${jdbc.user}",
                "-e jdbc.password=", "${jdbc.password}"
                 ]
                // volumes = [
                //     "/var/lib/docker/volumes/bitbucketVolume:/var/atlassian/application-data/bitbucket"
                // ]
                // volume_driver = "local"
            }
            driver = "docker"
            resources {
                cpu     = 4000
                memory  = 4096
                network {
                    mbits               = 10
                    mode                = "host"
                    port "http" {
                        static          = "7990"
                    }
                }
            }
            service {
                check {
                    name                = "bitbucket-server-http"
                    interval            = "10s"
                    timeout             = "2s"
                    type                = "http"
                    port                = "http"
                    path                = "/"
                }
                tags = [
                    "bitbucket-server",
                    "meta.team=Mercury",
                    "meta.email=sonu.singh@spglobal.com"
                ]
            }
        }
    }
    vault {
        policies = [ "nomad-system" ]
    }
}
