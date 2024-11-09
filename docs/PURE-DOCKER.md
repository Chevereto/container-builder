# Pure Docker

This is the most basic way to run Chevereto using Docker. It refers to running Chevereto using Docker without the extra provisions of [Chevereto Docker](README.md) (NGINX ingress proxy, CloudFlare integration).

## Build image (paid edition)

Image building is **recommended** for Chevereto **paid edition**. Skip to [Run (free edition)](#run-free-edition) if you are using Chevereto free edition or if you want to upgrade to paid edition within the application itself.

> [!NOTE]
> If you can't build the paid image you can use the free edition image and upgrade to paid within the application itself. To do this, pass the environment `CHEVERETO_SERVICING=server` to the container runtime and go to `/dashboard?license` to enter the license key and proceed with the upgrading process. You will also need to setup a volume for the application files.

### Clone repository

Clone the [chevereto/docker](https://github.com/chevereto/docker) repository and create an `.env` file with your license key:

```sh
CHEVERETO_LICENSE_KEY=your_license_key
```

### Make image

Run the following command to create the Chevereto image:

```sh
make image
```

By running the above command you will generate the following tags:

* `chevereto:latest`
* `chevereto:4`
* `chevereto:4.2`
* `chevereto:4.2.0`

## Upgrading

To upgrade you need to (1) Sync repository, (2) Re-build the container image, and (3) Update Chevereto instances.

### Step 1: Sync repository

Sync latest changes from [chevereto/docker](https://github.com/chevereto/docker) repository:

```sh
make sync
```

**Note:** If there's a new branch (for example 4.2) switch to that branch running the following command:

```sh
git switch 4.2
```

### Step 2: Re-build the container image

```sh
make image
```

### Step 3: Down and re-up the container

Down the container:

```sh
docker stop --name chevereto
docker rm --name chevereto
```

Then re-up the container using the same command you used to run it the first time.

## Run paid edition

To run [chevereto.com](https://chevereto.com/pricing) (paid edition) you need to pass the environment targeting your private build image, in this example `chevereto:latest`.

> Note: For running this command you need to fill your own database credentials.

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
  chevereto:latest
```

## Run free edition

To run [chevereto/chevereto](https://github.com/chevereto/chevereto) (Chevereto free edition) you need to pass the environment targeting one of its container image mirrors:

* `ghcr.io/chevereto/chevereto:latest` ([GitHub Container Registry](https://github.com/chevereto/chevereto/pkgs/container/chevereto))
* `chevereto/chevereto:latest` ([DockerHub](https://hub.docker.com/r/chevereto/chevereto))

When using `CHEVERETO_SERVICING=docker` (default) it behaves as a pure docker container, meaning that the application filesystem persists. When using `CHEVERETO_SERVICING=server` you need to mount the application directory to persist the filesystem upgrades.

> Note: For running this command you need to fill your own database credentials.

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

## Run free edition with application upgrade

If you want to run the free edition and manage the application upgrade within the application itself you need to pass `-e CHEVERETO_SERVICING=server` and setup a volume for the application files:

> Note: For running this command you need to fill your own database credentials.

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
  -e CHEVERETO_SERVICING=server \
  -v /var/www/html/images/ \
  -v /var/www/html/ \
  ghcr.io/chevereto/chevereto:latest
```

## Using compose

Create your own `docker-compose.yml` at your project folder. See more examples at the root of this repository.

```yml
services:
  database:
    image: mariadb:jammy
    networks:
      - chevereto
    volumes:
      - database:/var/lib/mysql
    restart: always
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--su-mysql", "--connect"]
      interval: 10s
      timeout: 5s
      retries: 3
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: chevereto
      MYSQL_USER: chevereto
      MYSQL_PASSWORD: user_database_password

  php:
    image: chevereto/chevereto:latest # tweak with target image to run
    networks:
      - chevereto
    volumes:
      - storage:/var/www/html/images/
      # - app:/var/www/html/ # uncomment when using CHEVERETO_SERVICING=server
    restart: always
    depends_on:
      database:
        condition: service_healthy
    expose:
      - 80
    environment:
      CHEVERETO_DB_HOST: database
      CHEVERETO_DB_USER: chevereto
      CHEVERETO_DB_PASS: user_database_password
      CHEVERETO_DB_PORT: 3306
      CHEVERETO_DB_NAME: chevereto
      CHEVERETO_HOSTNAME: hostname.com
      CHEVERETO_HOSTNAME_PATH: /
      CHEVERETO_HTTPS: 0
      CHEVERETO_MAX_POST_SIZE: 2G
      CHEVERETO_MAX_UPLOAD_SIZE: 2G
      #CHEVERETO_SERVICING: server # uncomment to enable application filesystem upgrades

volumes:
  database:
  storage:
  #app: uncomment when using CHEVERETO_SERVICING=server

networks:
  chevereto:
