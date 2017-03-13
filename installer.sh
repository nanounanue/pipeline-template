while getopts ":p:u:" opt; do
    case $opt in
        p) PROJECT_NAME="$OPTARG"
           ;;
        u) USERNAME="$OPTARG"
           ;;
        \?) echo "Opción inválida -$OPTARG" >&2
            ;;
    esac
done


git init ${PROJECT_NAME}

cd ${PROJECT_NAME}

git remote add "template" https://github.com/${USERNAME}/pipeline-template.git

git pull template master

echo ${PROJECT_NAME} > .project-name

hub create ${USERNAME}/${PROJECT_NAME}

git push origin master

git flow init -d

git checkout develop

make help 




