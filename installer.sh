#!/bin/sh

PROJECT_NAME:=$0

git init $(PROJECT_NAME)

cd $(PROJECT_NAME)

git remote add "template" https://github.com/nanounanue/pipeline-template.git

git pull template master

git flow init -d

git checkout develop
