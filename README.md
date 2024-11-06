# Docker

> 🔔 [Subscribe](https://chevereto.com/go/newsletter) to don't miss any update regarding Chevereto.

<img alt="Chevereto" src="chevereto.svg" width="100%">

[![Chevereto Docs](https://img.shields.io/badge/chevereto-docs-50C878?style=flat-square)](https://v4-docs.chevereto.com/)
[![Chevereto Community](https://img.shields.io/badge/chevereto-community-blue?style=flat-square)](https://chevereto.com/community)
[![Chevereto Discord](https://img.shields.io/badge/chevereto-discord-5865F2?style=flat-square)](https://chevereto.com/go/discord)
[![Chevereto Demo](https://img.shields.io/badge/chevereto-demo-d4af37?style=flat-square)](https://demo.chevereto.com)

Dockerfile driven template project for building images and manage containers for **Chevereto V4** projects. Go to [GitHub Container Registry](https://github.com/chevereto/chevereto/pkgs/container/chevereto/versions) or [Docker Hub](https://hub.docker.com/r/chevereto/chevereto/tags) for ready to use tagged images/versions.

> **Warning**: Do not publish Docker images to a public registry when using a paid Chevereto edition as its [commercial license](https://chevereto.com/license) restricts re-distribution rights.

## Installation service available

We offer a [paid installation service](https://chevereto.com/support) for this guide. We will install Chevereto Docker for you, including all the requirements and configurations.

## Features

* One-click commands using `make`
* Built-in HTTP ingress using nginx-proxy for multiple instances
* Automatic renewable [HTTPS](./docs/HTTPS.md) using Let's Encrypt
* One-click Chevereto [updates](./docs/UPDATING.md)
* Integrated with [CloudFlare](./docs/CLOUDFLARE.md) API (automatic sub-domain handling)
* [Pure Docker](./docs/PURE-DOCKER.md) instructions

## Requirements

To follow this guide, make sure you have:

* Ubuntu server with shell access and public IP address.
* Domain managed by CloudFlare (if using this integration)
* Chevereto license (required for the paid edition)
  * [Purchase](https://chevereto.com/pricing) new license
  * [Access](https://chevereto.com/panel/license) existing purchase

## Quick-start

Run the following command to install this project and all its dependencies in your brand new **Ubuntu 24.04** server.

```sh
bash <(curl -s https://chevereto.com/sh/ubuntu/24.04/docker.sh)
```

Create configuration file at `.env` by running this command.

```sh
make env
```

Run the following command to setup the system.

```sh
make setup
```

If using Chevereto paid edition, build the Chevereto image by running this command.

```sh
make image
```

### Deploying websites

To deploy a new website use the following command format.

```sh
make deploy NAMESPACE=yourproject ADMIN_EMAIL=admin@domain.tld
```

Replace `yourproject` with the desired project name and `admin@domain.tld` with the admin email for the website.

### Destroying websites

To destroy a website use the following command format.

```sh
make destroy NAMESPACE=yourproject
```

Replace `yourproject` with the desired project name to destroy.

### Altering existing websites

To alter a website edit `./namespace/yourproject` to reflect the new variables and run the following commands.

```sh
make down NAMESPACE=yourproject
make up-d NAMESPACE=yourproject
```

## Pure Docker

> [!NOTE]
> If you can't build the paid image you can use the free edition image and upgrade to paid within the application itself. Go to [PURE-DOCKER](./docs/PURE-DOCKER.md#run-free-edition-with-application-upgrade) to learn how.

If you want full control of the container provisioning you can get the container running with the following command.

```sh
docker run -d \
  --name chevereto \
  -p 80:80 \
  -e CHEVERETO_DB_HOST=database \
  -e CHEVERETO_DB_USER=chevereto \
  -e CHEVERETO_DB_PASS=user_database_password \
  -e CHEVERETO_DB_PORT=3306 \
  -e CHEVERETO_DB_NAME=chevereto \
  -e CHEVERETO_MAX_POST_SIZE=2G \
  -e CHEVERETO_MAX_UPLOAD_SIZE=2G \
  -v /var/www/html/images/ \
  ghcr.io/chevereto/chevereto:latest
```

See [PURE-DOCKER](docs/PURE-DOCKER.md) for a complete pure Docker command reference, including how to [run Chevereto paid edition](./docs/PURE-DOCKER.md#build-image-paid-edition).

## Manual setup

* Clone this repository [chevereto/docker](https://github.com/chevereto/docker) (see [SETUP](docs/SETUP.md#clone))

```sh
git clone https://github.com/chevereto/docker.git
```

* Get Docker in your Ubuntu server

```sh
make install-docker
```

You may also check [Docker for Desktop](https://docs.docker.com/get-docker/) and [Docker Engine](https://docs.docker.com/engine/install/) (servers) instructions.

* Create `.env` configuration file

```sh
make env
```

* Create Cron (see [SETUP](docs/SETUP.md#cron))

```sh
make cron
```

* Create [nginx-proxy](https://github.com/nginx-proxy/nginx-proxy)

```sh
make proxy EMAIL_HTTPS=mail@yourdomain.tld
```

## Build Chevereto image

Omit this step when using free edition as the image is available at [GHCR](https://github.com/chevereto/chevereto/pkgs/container/chevereto).

* Create Chevereto image (see [SETUP](docs/SETUP.md#custom-application))

```sh
make image
```

## Create a NAMESPACE

* Setup a [NAMESPACE](docs/NAMESPACE.md) for your website project

```sh
make namespace NAMESPACE=yourproject HOSTNAME=yourdomain.tld
```

## Documentation

* [SETUP](./docs/SETUP.md)
* [NAMESPACE](docs/NAMESPACE.md)
* [PURE-DOCKER](./docs/PURE-DOCKER.md)
* [COMMANDS](./docs/COMMANDS.md)
* [UPGRADING](./docs/UPGRADING.md)
* [DOCKER-COMPOSE](./docs/DOCKER-COMPOSE.md)
* [VOLUMES](./docs/VOLUMES.md)
* [PERSISTENT](./docs/PERSISTENT.md)
* [LOGS](./docs/LOGS.md)
* [HTTPS](./docs/HTTPS.md)
* [CLOUDFLARE](./docs/CLOUDFLARE.md)
* [UPDATING](./docs/UPDATING.md)
* [REPO SYNCING](./docs/REPO-SYNCING.md)
* [BUILDING](./docs/BUILDING.md)
* [FEEDBACK](./docs/FEEDBACK.md)
