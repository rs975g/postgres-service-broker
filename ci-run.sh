#!/bin/bash
set -e

ARTIFACTORY_REPOSITORY_URL="$1"
TRIGGER_DEPLOY="$2"
RUN_SONAR="$3"
BASE_PATH="$ARTIFACTORY_REPOSITORY_URL/com/mendix/cloud"
PROJECT_ID="devops/postgresql-service-broker"

if [ -z "$ARTIFACTORY_REPOSITORY_URL" ]; then
    echo "No artifactory repository URL given: " $0 "https://example.com/blah-local"
    exit 1
fi

# must match with docker params in gitlab-ci.yml
export MASTER_JDBC_URL="jdbc:postgresql://localhost:5433/travis_ci_test?user=postgres&password="
export LL_COMMIT=$(git rev-parse HEAD | cut -c1-8)
export VERSION="${CI_BUILD_REF_NAME}_${CI_BUILD_ID}_${CI_BUILD_REF:0:8}"
mvn package -Dbuild.version="${VERSION}"

push-to-artifactory.sh $(pwd)/target/postgresql-cf-service-broker-*_*.jar $BASE_PATH/postgresql-cf-service-broker/$VERSION

if [ "$TRIGGER_DEPLOY" == "trigger-deploy" ]; then
    trigger-deployment.sh postgresql-cf-service-broker $BASE_PATH/postgresql-cf-service-broker/$VERSION/postgresql-cf-service-broker-$VERSION.jar
fi

if [ "$RUN_SONAR" == "run-sonar" ]; then
    run-sonar-analysis.sh ${CI_BUILD_REF} ${CI_BUILD_REF_NAME} ${PROJECT_ID}
fi
