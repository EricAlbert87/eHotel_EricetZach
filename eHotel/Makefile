APP_NAME=ehotel-app-1.0-SNAPSHOT-jar-with-dependencies.jar
APP_JAR=target/$(APP_NAME)
DB_NAME=ehotels
DB_USER=postgres
DB_PASSWORD=postgres
SQL_FILE=database/ehotels_postgresql.sql

SERVER_USER?=user
SERVER_HOST?=server
SERVER_DIR?=/opt/ehotel

.PHONY: help install db-init setup build run start deploy-copy deploy-run deploy

help:
	@echo "Available targets:"
	@echo "  make install      - Install Java, Maven, PostgreSQL (Ubuntu/Debian)"
	@echo "  make db-init      - Create ehotels database and import SQL file"
	@echo "  make setup        - install + db-init"
	@echo "  make build        - Build jar with Maven"
	@echo "  make run          - Run application jar"
	@echo "  make start        - build + run"
	@echo "  make deploy-copy  - Copy jar to remote server"
	@echo "  make deploy-run   - Run jar on remote server (nohup)"
	@echo "  make deploy       - build + deploy-copy + deploy-run"
	@echo ""
	@echo "Deploy vars: SERVER_USER, SERVER_HOST, SERVER_DIR"
	@echo "Example: make deploy SERVER_USER=ubuntu SERVER_HOST=1.2.3.4"

install:
	sudo apt-get update
	sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-21-jdk maven postgresql postgresql-contrib
	sudo systemctl enable postgresql || true
	sudo systemctl start postgresql

db-init:
	@test -f "$(SQL_FILE)" || (echo "Missing SQL file: $(SQL_FILE)" && exit 1)
	cd /tmp && sudo -u $(DB_USER) psql -c "ALTER USER $(DB_USER) WITH PASSWORD '$(DB_PASSWORD)';"
	cd /tmp && if ! sudo -u $(DB_USER) psql -tAc "SELECT 1 FROM pg_database WHERE datname='$(DB_NAME)'" | tr -d '[:space:]' | grep -qx "1"; then sudo -u $(DB_USER) createdb $(DB_NAME); fi
	cd /tmp && sudo -u $(DB_USER) psql -d $(DB_NAME) < "$(abspath $(SQL_FILE))"

setup: install db-init

build:
	mvn clean package

run:
	java -jar $(APP_JAR)

start: build run

deploy-copy: build
	ssh $(SERVER_USER)@$(SERVER_HOST) "mkdir -p $(SERVER_DIR)"
	scp $(APP_JAR) $(SERVER_USER)@$(SERVER_HOST):$(SERVER_DIR)/

deploy-run:
	ssh $(SERVER_USER)@$(SERVER_HOST) "cd $(SERVER_DIR) && nohup java -jar $(APP_NAME) > ehotel.log 2>&1 &"

deploy: deploy-copy deploy-run
