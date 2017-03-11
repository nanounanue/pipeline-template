.PHONY: clean data lint init deps sync_to_s3 sync_from_s3

########################################
##            Variables               ##
########################################

PROJECT_NAME:=`cat .project-name`

## Versión de python
VERSION_PYTHON:=`cat .version-python`

## Bucket de amazon
S3_BUCKET :=

SHELL := /bin/bash 

########################################
##            Ayuda                   ##
########################################

help:   ##@ayuda Diálogo de ayuda
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)


########################################
##      Tareas de Ambiente            ##
########################################

init: prepare ##@dependencias Prepara la computadora para el funcionamiento del proyecto

prepare: deps
#	pyenv virtualenv ${PROJECT_NAME}_venv
#	pyenv local ${PROJECT_NAME}_venv

#pyenv: .python-version
#	@pyenv install $(VERSION_PYTHON)

deps: pip pip-dev

pip: requirements.txt
	@pip install -r $<

pip-dev: requirements-dev.txt
	@pip install -r $<

info:
	@python --version
	@pyenv --version
	@pip --version

########################################
##      Tareas de Limpieza            ##
########################################

clean: ##@limpieza Elimina los archivos no necesarios
	@find . -name "__pycache__" -exec rm -rf {} \;
	@find . -name "*.egg-info" -exec rm -rf {} \;
	@find . -name "*.pyc" -exec rm {} \;
	@find . -name '*.pyo' -exec rm -f {} \;
	@find . -name '*~' ! -name '*.un~' -exec rm -f {} \;

clean_venv: ##@limpieza Destruye la carpeta de virtualenv
	@pyenv uninstall -f ${PROJECT_NAME}_venv
	echo ${VERSION_PYTHON} > .python-version

########################################
##      Tareas de Ejecución           ##
##    	de Infraestructura            ##
########################################

create: ##@infraestructura Crea infraestructura necesaria: Pull de imágenes y crea el storage local
	$(MAKE) --directory=infraestructura create

start: create ##@infraestructura Inicializa la infraestructura y ejecuta el entrenamiento
	$(MAKE) --directory=infraestructura start

stop: ##@infraestructura Detiene la infraestructura
	$(MAKE) --directory=infraestructura stop

status: ##@infraestructura Informa el estatus de la infraestructura
	$(MAKE) --directory=infraestructura status

logs:   ##@infraestructura Despliega en pantalla las salidas de los logs de la infraestructura
	$(MAKE) --directory=infraestructura logs

restart: ##@infraestructura Reinicializa la infraestructura
	$(MAKE) --directory=infraestructura restart

destroy: ##@infraestructura Destruye la infraestructura
	$(MAKE) --directory=infraestructura clean

nuke: ##@infraestructura Destruye la infraestructura (incluyendo las imágenes)
	$(MAKE) --directory=infraestructura nuke

########################################
##      Tareas de Validación          ##
########################################

lint:  ##@test Verifica que el código este bien escrito (según PEP8)
	@flake8 --exclude=lib/,bin/,docs/conf.py .

tox: clean  ##@test Ejecuta tox
	tox

########################################
##      Tareas de Documentación       ##
########################################

view_docs:  ##@docs Ver la documentación en http://0.0.0.0:8000
	@mkdocs serve

create_docs: ##@docs Crea la documentación
	$(MAKE) --directory=docs html

todo:         ##@docs ¿Qué falta por hacer?
	pylint --disable=all --enable=W0511 src


########################################
##      Tareas de Sincronización      ##
##             de Datos               ##
########################################


sync_to_s3: ##@data Sincroniza los datos hacia AWS S3
	@aws s3 sync data/ s3://$(S3_BUCKET)/data/


sync_from_s3: ##@data Sincroniza los datos desde AWS S3
	@aws s3 sync s3://$(S3_BUCKET)/data/ data/

########################################
##      Tareas del Proyecto           ##
########################################

run:       ##@proyecto Ejecuta el pipeline de datos
	@LUIGI_CONFIG_PATH=./${PROJECT_NAME}/pipelines/luigi.cfg ${PROJECT_NAME} --server localhost --port 8082

setup: build install ##@proyecto Crea las imágenes del pipeline e instala el pipeline como paquete en el PYTHONPATH

remove: uninstall  ##@proyecto Destruye la imágenes del pipeline y desinstala el pipeline del PYTHONPATH
	$(MAKE) --directory=$(PROJECT_NAME) clean


set_project_name: ##@proyecto Renombra el proyecto de dpa_test a PROJECT_NAME (requiere ag 'silver searcher')
  ## Basado en http://stackoverflow.com/a/39284776/754176
	@ag [dD]ummy -l0 | xargs -0 sed -i  "s/[dD]ummy/${PROJECT_NAME}/g"
	## Renombrar la carpeta del proyecto
	@[[ -d dummy ]] && mv dummy/pipelines/dummy.py dummy/pipelines/$(PROJECT_NAME).py
	@[[ -d dummy ]] && mv dummy $(PROJECT_NAME)


build:
	$(MAKE) --directory=$(PROJECT_NAME) build

install:
	@pip install --editable .

uninstall:
	@while pip uninstall -y ${PROJECT_NAME}; do true; done
	@python setup.py clean


########################################
##            Funciones               ##
##           de soporte               ##
########################################

## NOTE: Tomado de https://gist.github.com/prwhite/8168133 , en particular,
## del comentario del usuario @nowox, lordnynex y @HarasimowiczKamil

## COLORS
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RESET  := $(shell tput -Txterm sgr0)

## NOTE: Las categorías de ayuda se definen con ##@categoria
HELP_FUN = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-z0-9_\-]+)\s*:.*\#\#(?:@([a-z0-9_\-]+))?\s(.*)$$/ }; \
    print "uso: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${YELLOW}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }

## Verificando dependencias
## Basado en código de Fernando Cisneros @ datank
EXECUTABLES = docker docker-compose docker-machine pyenv ag pip 
TEST_EXEC := $(foreach exec,$(EXECUTABLES),\
				$(if $(shell which $(exec)), some string, $(error "No está $(exec) en el PATH, considera revisar Google para instalarlo (Quizá 'apt-get install $(exec)' funcione...)")))
