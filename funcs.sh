#!/bin/bash

# Remove first charater in a string and print the results into sdtout.
# See the tests for usage example.
remove_1st () {
  target=$1

  res="${target:1}"
  echo $res
}

# Validate required environment variables.
# If any required environment variables is not provided an error message will
# be printed in the stdout.
# See the tests for usage example.
validate_envs () {
  for ENV in "$@"
  do
    res="$(eval echo "\$$ENV")"
    if [ "$res" == "" ]
    then
      echo "ERROR: $ENV is not defined"
      exit 0
    fi
  done
}

# Calls validate_envs but exits with error on failure.
validate_envs_x () {
  res=$(validate_envs "$@")
  if [ "$res" != "" ]
  then
    >&2 echo "$res"
    exit 1
  fi
}

# Determine the deployment environment for github branch or tag.
# See the tests for usage example.
get_deployment_env () {
  env=unknown
  branch_or_tag=$1

  if [ "$env" == "unknown" ] && [ "$branch_or_tag" == "develop" ]
  then
    echo "test"
    exit 0
  fi

  if [ "$env" == "unknown" ] && [[ "$branch_or_tag" == release/* ]]
  then
    echo "stage"
    exit 0
  fi

  if [ "$env" == "unknown" ] && [[ "$branch_or_tag" == v* ]]
  then
    echo "prod"
    exit 0
  fi

  echo $env
}

# Build and push docker images for respective environment when applicable.
# WARNING! Please be careful about positional arguments.
# NOTE: See tests for usage example.
create_docker_image () {
    ENV=$1
    IMAGE=$2
    STAGE_IMAGE=$3
    VERSION=$4
    SHORT_SHA=$5
    RELEASE_TAG=$6

    # We don't create a new docker image for production environment.
    if [ "$ENV" != "prod" ]
    then
        docker build -t $IMAGE .
        docker tag $IMAGE:latest $IMAGE:$TAG
        docker push $IMAGE:latest
    fi

    if [ "$ENV" == "stage" ]
    then
        docker tag $IMAGE:latest $IMAGE:beta
        docker push $IMAGE:beta
    fi

    if [ "$ENV" == "prod" ]
    then
        TAG=$(remove_1st $RELEASE_TAG)

        # Pull beta docker image from staging.
        docker pull $STAGE_IMAGE:beta

        # Create production docker image tag from staging beta image.
        docker tag $STAGE_IMAGE:beta $IMAGE:stable
        docker tag $STAGE_IMAGE:beta $IMAGE:$TAG

        # Push production stable docker image.
        docker push $IMAGE:stable
    fi

    docker push $IMAGE:$TAG
}

# Exit if `ENV` is unknown or no target deployment environment identified.
exit_if_unknown_env () {
    ENV=$1

    if [ "$ENV" == "unknown" ]
    then
        echo "INFO: not for deployment"
        exit 0
    fi
}
