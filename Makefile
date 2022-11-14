#!make
NAMESPACE ?= chevereto
NAMESPACE_FILE = ./namespace/${NAMESPACE}
NAMESPACE_FILE_EXISTS = false
ifneq ("$(wildcard ${NAMESPACE_FILE})","")
	NAMESPACE_FILE_EXISTS = true
	include ${NAMESPACE_FILE}
	export $(shell sed 's/=.*//' ${NAMESPACE_FILE})
endif
SOURCE ?= ~/git/chevereto/v4
TARGET ?= prod# prod|dev
VERSION ?= 4.0
PHP ?= 8.1
DOCKER_USER ?= www-data
HOSTNAME ?= localhost
HOSTNAME_PATH ?= /
PROTOCOL ?= https
SERVICE ?= php
ENCRYPTION_KEY ?=
EMAIL_HTTPS ?= mail@yourdomain.tld
DB_PORT ?= 8836
HTTP_PORT ?= 80
HTTPS_PORT ?= 443
PORT = $(shell [ "${PROTOCOL}" = "http" ] && echo \${HTTP_PORT} || echo \${HTTPS_PORT})
HTTPS = $(shell [ "${PROTOCOL}" = "http" ] && echo 0 || echo 1)
HTTPS_CERT = https/$(shell [ -f "https/cert.pem" ] && echo || echo dummy/)cert.pem
HTTPS_KEY = https/$(shell [ -f "https/key.pem" ] && echo || echo dummy/)key.pem
URL_BARE = ${PROTOCOL}://${HOSTNAME}${HOSTNAME_PATH}
URL_PORT = ${PROTOCOL}://${HOSTNAME}:${PORT}${HOSTNAME_PATH}
URL = $(shell [ "${PORT}" = 80 -o "${PORT}" = 443 ] && echo ${URL_BARE} || echo ${URL_PORT})
PROJECT = $(shell [ "${TARGET}" = "prod" ] && echo \${NAMESPACE}_chevereto || echo \${NAMESPACE}_chevereto-\${TARGET})
CONTAINER_BASENAME = ${PROJECT}-${VERSION}
IMAGE_TAG = chevereto$(shell [ ! "${TARGET}" = "prod" ] && echo -\${TARGET}):${VERSION}
COMPOSE ?= docker-compose
PROJECT_COMPOSE = ${COMPOSE}.yml
COMPOSE_SAMPLE = $(shell [ "${TARGET}" = "prod" ] && echo default || echo dev).yml
COMPOSE_FILE = $(shell [ -f \${PROJECT_COMPOSE} ] && echo \${PROJECT_COMPOSE} || echo \${COMPOSE_SAMPLE})
FEEDBACK = $(shell echo 👉 \${TARGET} \${NAMESPACE}@\${NAMESPACE_FILE} V\${VERSION} [PHP \${PHP}] \(\${DOCKER_USER}\))
FEEDBACK_SHORT = $(shell echo 👉 \${TARGET} V\${VERSION} [PHP \${PHP}] \(\${DOCKER_USER}\))
LICENSE ?= $(shell stty -echo; read -p "Chevereto V4 License key: 🔑" license; stty echo; echo $$license)
ACME_CHALLENGE = $(shell [ ! -d ".well-known" ] && mkdir -p .well-known)
DOCKER_COMPOSE = $(shell ${ACME_CHALLENGE} echo @CONTAINER_BASENAME=\${CONTAINER_BASENAME} \
	SOURCE=\${SOURCE} \
	DB_PORT=\${DB_PORT} \
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
	@echo "🔌 ${PORT}"
	@echo "${URL} @URL"

feedback--image:
	@echo "📦 ${IMAGE_TAG}"

feedback--volumes:
	@echo "${PROJECT}_database"
	@echo "${PROJECT}_storage"

feedback--namespace:
	@echo "$(shell [ "${NAMESPACE_FILE_EXISTS}" = "true" ] && echo "✅" || echo "❌") ${NAMESPACE_FILE}"
	@echo "🔑 ${ENCRYPTION_KEY}"
	@echo "🌎 ${HOSTNAME}"

# Docker

image: feedback--image feedback--short
	@LICENSE=${LICENSE} \
	VERSION=${VERSION} \
	./scripts/chevereto.sh
	@echo "* Building image ${IMAGE_TAG}"
	@docker build . \
		--network host \
		-f Dockerfile \
		-t ${IMAGE_TAG}

image-custom: feedback--image feedback--short
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

exec: feedback
	@docker exec -it --user ${DOCKER_USER} \
		${CONTAINER_BASENAME}_${SERVICE} \
		${COMMAND}

run: feedback
	@docker exec -it \
		${CONTAINER_BASENAME}_${SERVICE} \
		bash /var/scripts/${SCRIPT}.sh

cron:
	@./scripts/cron.sh

cron-run:
	@./scripts/cron-run.sh

cloudflare:
	@./scripts/cloudflare.sh

encryption-key:
	@openssl rand -base64 32

.PHONY: namespace
namespace:
	@chmod +x ./scripts/namespace.sh
	@NAMESPACE=${NAMESPACE} \
	NAMESPACE_EXISTS=${NAMESPACE_EXISTS} \
	NAMESPACE_FILE=${NAMESPACE_FILE} \
	HOSTNAME=${HOSTNAME} \
	ENCRYPTION_KEY=${ENCRYPTION_KEY} \
	./scripts/namespace.sh

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
	@sudo docker run \
		--detach \
		--name nginx-proxy \
		--net nginx-proxy \
		--publish 80:80 \
		--publish 443:443 \
		--volume certs:/etc/nginx/certs \
		--volume vhost:/etc/nginx/vhost.d \
		--volume html:/usr/share/nginx/html \
		--mount type=bind,source=/var/run/docker.sock,target=/tmp/docker.sock,readonly \
		--mount type=bind,source=${PWD}/nginx/chevereto.conf,target=/etc/nginx/conf.d/chevereto.conf,readonly \
		--mount type=bind,source=${PWD}/nginx/cloudflare.conf,target=/etc/nginx/conf.d/cloudflare.conf,readonly \
		nginxproxy/nginx-proxy
	@sudo docker run \
		--detach \
		--name nginx-proxy-acme \
		--volumes-from nginx-proxy \
		--volume acme:/etc/acme.sh \
		--mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock,readonly \
		--env "DEFAULT_EMAIL=${EMAIL_HTTPS}" \
		nginxproxy/acme-companion

proxy--view:
	@docker exec nginx-proxy cat /etc/nginx/conf.d/default.conf

proxy--remove:
	@docker container rm -f nginx-proxy nginx-proxy-acme || true
	@docker network rm nginx-proxy || true

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

