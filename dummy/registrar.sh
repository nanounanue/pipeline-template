IMAGES="test-r test-python"
IMAGE_VERSION="0.1"
DOCKER_REGISTRY="localhost:5000"

for IMAGE in ${IMAGES} ; do
    docker build --tag ${DOCKER_REGISTRY}/dpa/${IMAGE}:${IMAGE_VERSION} tasks/${IMAGE}
    docker push ${DOCKER_REGISTRY}/dpa/${IMAGE}:${IMAGE_VERSION}
done
