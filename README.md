![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# TINYAUTH
![size](https://img.shields.io/badge/image_size-23MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/tinyauth?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-tinyauth?color=7842f5">](https://github.com/11notes/docker-tinyauth/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

run tinyauth rootless and distroless.

# INTRODUCTION 📢

[Tinyauth](https://github.com/steveiliop56/tinyauth) (created by [steveiliop56](https://github.com/steveiliop56)) is a simple authentication middleware that adds a simple login screen or OAuth with Google, Github and any provider to all of your docker apps. It supports all the popular proxies like Traefik, Nginx and Caddy.

# SYNOPSIS 📖
**What can I do with this?** This image will run tinyauth [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md) for more security, including disabling it's telemetry in [code](https://github.com/11notes/docker-tinyauth/blob/master/arch.dockerfile#L51).

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
>* ... this image is auto updated to the latest version via CI/CD
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is automatically scanned for CVEs before and after publishing
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/tinyauth | 23MB | 1000:1000 | ✅ | amd64, arm64 |
| steveiliop56/tinyauth | 42MB | 0:0 | ❌ | amd64, arm64 |

# VOLUMES 📁
* **/tinyauth/var** - Directory of SQLite database and static assets

# COMPOSE ✂️
```yaml
name: "auth"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  tinyauth:
    image: "11notes/tinyauth:4.1.0"
    <<: *lockdown
    environment:
      APP_URL: "https://${FQDN_TINYAUTH}"
      # secret must be a 32 Byte long string (32 characters)
      SECRET: ${SECRET}
      # admin / admin, please do not use in production!
      USERS: "admin:$2y$12$zzekhr74SUez9vo8TK2Be.mJ4EMX44k7whOogQo4F/2i84a6Rl6U6"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.tinyauth.rule=Host(`${FQDN_TINYAUTH}`)"
      - "traefik.http.routers.tinyauth.entrypoints=https"
      - "traefik.http.routers.tinyauth.tls=true"
      - "traefik.http.routers.tinyauth.service=tinyauth"
      - "traefik.http.services.tinyauth.loadbalancer.server.port=3000"
      - "traefik.http.middlewares.tinyauth.forwardauth.address=http://tinyauth:3000/api/auth/traefik"
    volumes:
      - "tinyauth.var:/tinyauth/var"
    networks:
      backend:

  socket-proxy:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-socket-proxy
    image: "11notes/socket-proxy:2.1.6"
    <<: *lockdown
    user: "0:0"
    volumes:
      - "/run/docker.sock:/run/docker.sock:ro" 
      - "socket-proxy.run:/run/proxy"
    restart: "always"

  traefik:
    # for more information about this image checkout:
    # https://github.com/11notes/docker-traefik
    depends_on:
      socket-proxy:
        condition: "service_healthy"
        restart: true
    image: "11notes/traefik:3.5.4"
    <<: *lockdown
    command:
      # this is an example configuration, do not use in production
      - "--ping=true"
      - "--ping.terminatingStatusCode=204"
      - "--global.checkNewVersion=false"
      - "--global.sendAnonymousUsage=false"
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--log.level=INFO"
      - "--log.format=json"
      - "--providers.docker.exposedByDefault=false"
      - "--entrypoints.http.address=:80"
      - "--entrypoints.https.address=:443"
    ports:
      - "80:80/tcp"
      - "443:443/tcp"
      - "8080:8080/tcp"
    networks:
      frontend:
      backend:
    volumes:
      - "socket-proxy.run:/var/run"
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 80
    restart: "always"

  whoami:
    image: "traefik/whoami:latest"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`${FQDN_WHOAMI}`)"
      - "traefik.http.routers.whoami.entrypoints=https"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.middlewares=tinyauth@docker"
      - "traefik.http.routers.whoami.service=whoami@docker"
      - "traefik.http.services.whoami.loadbalancer.server.port=80"
    networks:
      backend:

volumes:
  tinyauth.var:
  socket-proxy.run:

networks:
  frontend:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /tinyauth | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [4.1.0](https://hub.docker.com/r/11notes/tinyauth/tags?name=4.1.0)
* [4.1.0-unraid](https://hub.docker.com/r/11notes/tinyauth/tags?name=4.1.0-unraid)
* [4.1.0-nobody](https://hub.docker.com/r/11notes/tinyauth/tags?name=4.1.0-nobody)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:4.1.0``` you can use ```:4``` or ```:4.1```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/tinyauth:4.1.0
docker pull ghcr.io/11notes/tinyauth:4.1.0
docker pull quay.io/11notes/tinyauth:4.1.0
```

# UNRAID VERSION 🟠
This image supports unraid by default. Simply add **-unraid** to any tag and the image will run as 99:100 instead of 1000:1000.

# NOBODY VERSION 👻
This image supports nobody by default. Simply add **-nobody** to any tag and the image will run as 65534:65534 instead of 1000:1000.

# SOURCE 💾
* [11notes/tinyauth](https://github.com/11notes/docker-tinyauth)

# PARENT IMAGE 🏛️
> [!IMPORTANT]
>This image is not based on another image but uses [scratch](https://hub.docker.com/_/scratch) as the starting layer.
>The image consists of the following distroless layers that were added:
>* [11notes/distroless](https://github.com/11notes/docker-distroless/blob/master/arch.dockerfile) - contains users, timezones and Root CA certificates, nothing else
>* [11notes/distroless:localhealth](https://github.com/11notes/docker-distroless/blob/master/localhealth.dockerfile) - app to execute HTTP requests only on 127.0.0.1

# BUILT WITH 🧰
* [steveiliop56/tinyauth](https://github.com/steveiliop56/tinyauth)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# CAUTION ⚠️
> [!CAUTION]
>* The example compose has a default user account, please provide your own user account and do not blindly copy and paste

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-tinyauth/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-tinyauth/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-tinyauth/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 11.12.2025, 07:41:51 (CET)*