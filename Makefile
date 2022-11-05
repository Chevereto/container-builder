SOURCE ?= ~/git/chevereto/v4
TARGET ?= prod# prod|dev
VERSION ?= 4.0
PHP ?= 8.1
DOCKER_USER ?= www-data
HOSTNAME ?= localhost
HOSTNAME_PATH ?= /
PROTOCOL ?= http
NAMESPACE ?= chevereto
SERVICE ?= php

HTTP_PORT ?= 80
HTTPS_PORT ?= 443
PORT = $(shell [ "${PROTOCOL}" = "http" ] && echo \${HTTP_PORT} || echo \${HTTPS_PORT})
HTTPS = $(shell [ "${PROTOCOL}" = "http" ] && echo 0 || echo 1)
HTTPS_CERT = https/$(shell [ -f "https/cert.pem" ] && echo || echo dummy/)cert.pem
HTTPS_KEY = https/$(shell [ -f "https/key.pem" ] && echo || echo dummy/)key.pem

URL = ${PROTOCOL}://${HOSTNAME}:${PORT}/
PROJECT = $(shell [ "${TARGET}" = "prod" ] && echo \${NAMESPACE}_chevereto || echo \${NAMESPACE}_chevereto-\${TARGET})
CONTAINER_BASENAME = ${PROJECT}-${VERSION}
IMAGE_TAG = chevereto:${VERSION}

COMPOSE ?= docker-compose
PROJECT_COMPOSE = ${COMPOSE}.yml
COMPOSE_SAMPLE = $(shell [ "${TARGET}" = "prod" ] && echo default || echo dev).yml
COMPOSE_FILE = $(shell [ -f \${PROJECT_COMPOSE} ] && echo \${PROJECT_COMPOSE} || echo \${COMPOSE_SAMPLE})

FEEDBACK = $(shell echo 👉 \${TARGET} V\${VERSION} \${NAMESPACE} [PHP \${PHP}] \(\${DOCKER_USER}\))
FEEDBACK_SHORT = $(shell echo 👉 \${TARGET} V\${VERSION} [PHP \${PHP}] \(\${DOCKER_USER}\))

LICENSE ?= $(shell stty -echo; read -p "Chevereto V4 License key: 🔑" license; stty echo; echo $$license)

ACME_CHALLENGE = $(shell [ ! -d ".well-known" ] && mkdir -p .well-known)
DOCKER_COMPOSE = $(shell ${ACME_CHALLENGE} echo @CONTAINER_BASENAME=\${CONTAINER_BASENAME} \
	SOURCE=\${SOURCE} \
	HTTP_PORT=\${HTTP_PORT} \
	HTTPS_PORT=\${HTTPS_PORT} \
	HTTPS_CERT=\${HTTPS_CERT} \
	HTTPS_KEY=\${HTTPS_KEY} \
	HTTPS=\${HTTPS} \
	IMAGE_TAG=\${IMAGE_TAG} \
	VERSION=\${VERSION} \
	HOSTNAME=\${HOSTNAME} \
	HOSTNAME_PATH=\${HOSTNAME_PATH} \
	URL=\${URL} \
	docker compose -p \${PROJECT} -f \${COMPOSE_FILE})

# Informational

feedback:
	@./scripts/logo.sh
	@echo "${FEEDBACK}"

feedback--short:
	@echo "${FEEDBACK_SHORT}"

feedback--compose:
	@echo "🐋 ${COMPOSE_FILE}"

feedback--url:
	@echo "🌎 ${URL}"

feedback--volumes:
	@echo "${PROJECT}_database"
	@echo "${PROJECT}_storage"

# Docker

image: feedback--short
	@chmod +x ./scripts/chevereto.sh
	@LICENSE=${LICENSE} \
	VERSION=${VERSION} \
	./scripts/chevereto.sh
	@echo "* Building image ${IMAGE_TAG}"
	@docker build . \
		--network host \
		-f Dockerfile \
		-t ${IMAGE_TAG}

image-custom: feedback--short
	@mkdir -p chevereto
	echo "* Building custom image ${IMAGE_TAG}"
	@docker build . \
		--network host \
		-f Dockerfile \
		-t ${IMAGE_TAG}

volume-cp:
	@docker run --rm -it -v ${VOLUME_FROM}:/from -v ${VOLUME_TO}:/to alpine ash -c "cd /from ; cp -av . /to"

volume-rm:
	@docker volume rm ${VOLUME}

# Logs

log: feedback
	@docker logs -f ${CONTAINER_BASENAME}_${SERVICE}

log-access: feedback
	@docker logs ${CONTAINER_BASENAME}_${SERVICE} -f 2>/dev/null

log-error: feedback
	@docker logs ${CONTAINER_BASENAME}_${SERVICE} -f 1>/dev/null

# Tools

bash: feedback
	@docker exec -it --user ${DOCKER_USER} \
		${CONTAINER_BASENAME}_${SERVICE} \
		bash

run: feedback
	@docker exec -it \
		${CONTAINER_BASENAME}_${SERVICE} \
		bash /var/scripts/${SCRIPT}.sh

# Docker compose

up: feedback feedback--compose feedback--url
	${DOCKER_COMPOSE} up

up-d: feedback feedback--compose feedback--url
	${DOCKER_COMPOSE} up -d

stop: feedback feedback--compose
	${DOCKER_COMPOSE} stop

start: feedback feedback--compose
	${DOCKER_COMPOSE} start

restart: feedback feedback--compose
	${DOCKER_COMPOSE} restart

down: feedback feedback--compose
	${DOCKER_COMPOSE} down

down--volumes: feedback feedback--compose
	${DOCKER_COMPOSE} down --volumes

# nginx-proxy

proxy:
	@docker network create nginx-proxy || true
	@docker run \
		--detach \
		--name nginx-proxy \
		--net nginx-proxy \
		--publish 80:80 \
		--publish 443:443 \
		--volume certs:/etc/nginx/certs \
		--volume vhost:/etc/nginx/vhost.d \
		--volume html:/usr/share/nginx/html \
		--volume /var/run/docker.sock:/tmp/docker.sock:ro \
		nginxproxy/nginx-proxy
	@docker run \
		--detach \
		--name nginx-proxy-acme \
		--volumes-from nginx-proxy \
		--volume /var/run/docker.sock:/var/run/docker.sock:ro \
		--volume acme:/etc/acme.sh \
		--env "DEFAULT_EMAIL=mail@yourdomain.tld" \
		nginxproxy/acme-companion

proxy--view:
	@docker exec nginx-proxy cat /etc/nginx/conf.d/default.conf

proxy--remove:
	@docker container rm -f nginx-proxy nginx-proxy-acme || true

# https

certbot:
	@echo "🔐 Generating certificate"
	@HOSTNAME=${HOSTNAME} \
	docker container run \
		-it \
		--rm \
		-v ${PWD}/letsencrypt/certs:/etc/letsencrypt \
		-v ${PWD}/.well-known:/data/letsencrypt/.well-known \
		certbot/certbot certonly \
		--webroot \
		--webroot-path=/data/letsencrypt \
		-d ${HOSTNAME} \
	&& cp ${PWD}/letsencrypt/certs/live/${HOSTNAME}/fullchain.pem ${PWD}/https/cert.pem \
	&& cp ${PWD}/letsencrypt/certs/live/${HOSTNAME}/privkey.pem ${PWD}/https/key.pem

cert-self:
	@echo "🔐 Generating self-signed certificate"
	@cd ${PWD}/https \
	&& openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem

