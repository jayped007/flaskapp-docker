#Import and expose environment variables
cnf ?= .env
include $(cnf)
export $(shell sed 's/=.*//' $(cnf))

.PHONY: init

#Create secret for development
DEV_SECRET=$(shell echo  $(APP_NAME) | tr /a-z/ /A-Z/ )_SECRET=$(shell openssl rand -base64 32)

help: 
	@echo
	@echo "Usage: make TARGET"
	@echo
	@echo "$(PROJECT_NAME) project automation helper"
	@echo
	@echo "Targets:"
	@echo " init        generate source codebase from GitHub repo"
	@echo " init-purge  clean up generated code"
	@echo " dev-up/down start/stop DEV application on port 5000"
	@echo " dev-logs    examine logging from DEV app"
	@echo " dev-ps      examine processes running in DEV app"

#Generate project codebase form GitHub using cookiecutter
init:
	docker-compose -f docker/init/docker-compose.yml up -d --build
	docker cp flask-sql-ci-initiator:/root/$(APP_NAME) ./$(APP_NAME)
	docker-compose -f docker/init/docker-compose.yml down

#Remove the generated code, use this before re-running the `init` target
init-purge:
	sudo rm -rf ./$(APP_NAME)

#Write the development secret to file
.dev-secret:
	echo $(DEV_SECRET) > dev-secret.env

# Build the DEV image
dev-build: .dev-secret
	docker-compose -f docker/dev/docker-compose.yml build

#Start up development environment
dev-up: .dev-secret
	docker-compose -f docker/dev/docker-compose.yml up -d

#Bring down development environment
dev-down:
	docker-compose -f docker/dev/docker-compose.yml down
	rm dev-secret.env

dev-logs:
	docker-compose -f docker/dev/docker-compose.yml logs -f

dev-ps:
	docker-compose -f docker/dev/docker-compose.yml ps
