#!/usr/bin/env bash

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

  if [ "$env" == "unknown" ] && [[ "$branch_or_tag" == v*-rc ]]
  then
    echo "pilot"
    exit 0
  fi

  if [ "$env" == "unknown" ] && [[ "$branch_or_tag" == v*-* ]]
  then
    echo "unknown"
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
#
# WARNING! Please be careful about positional arguments.
#
# NOTE: See tests for usage example.
create_docker_image () {
    ENV=$1
    IMAGE=$2
    STAGE_IMAGE=$3
    VERSION=$4
    SHORT_SHA=$5
    RELEASE_TAG=$6

    TAG=$VERSION-$SHORT_SHA

    # We don't create a new docker image for production & pilot environment.
    if [ "$ENV" != "prod" ] && [ "$ENV" != "pilot" ]
    then
        docker build -t $IMAGE .
        docker tag $IMAGE:latest $IMAGE:$TAG
        docker push $IMAGE:latest

        echo "$IMAGE:latest docker image pushed"

        docker push $IMAGE:$TAG
        echo "$IMAGE:$TAG docker image pushed"
    fi

    if [ "$ENV" == "stage" ]
    then
        docker tag $IMAGE:latest $IMAGE:beta
        docker push $IMAGE:beta

        echo "$IMAGE:beta docker image pushed"

        docker push $IMAGE:$TAG
        echo "$IMAGE:$TAG docker image pushed"
    fi

    if [ "$ENV" == "pilot" ]
    then
        TAG=$(get_version $RELEASE_TAG)

        # Pull beta docker image from staging.
        docker pull $STAGE_IMAGE

        # Create pilot docker image tag from staging beta image.
        docker tag $STAGE_IMAGE $IMAGE:$TAG-rc

        # Push pilot docker image.
        docker push $IMAGE:$TAG-rc

        echo "$IMAGE:$TAG-rc docker image pushed"
    fi

    if [ "$ENV" == "prod" ]
    then
        TAG=$(get_version $RELEASE_TAG)

        # Pull release candidate docker image.
        docker pull $IMAGE:$TAG-rc

        # Create production docker image tag from release candidate image.
        docker tag $IMAGE:$TAG-rc $IMAGE:stable
        docker tag $IMAGE:$TAG-rc $IMAGE:$TAG

        # Push production stable docker image.
        docker push $IMAGE:stable

        echo "$IMAGE:stable docker image pushed"

        docker push $IMAGE:$TAG
        echo "$IMAGE:$TAG docker image pushed"
    fi
}

# Exit if `ENV` is unknown or no target deployment environment identified.
exit_if_unknown_env () {
    ENV=$1
    OPT=$2

    if [ "$ENV" == "unknown" ] && [ "$OPT" != "force-deploy" ]
    then
        echo "INFO: not for deployment"
        exit 0
    fi
}

# Get release type.
#
# - If the tag is v1.1.0 pattern it is considered as a production release.
# - If the tag is v1.1.0-2 pattern it is considered as a non-production release.
#
# NOTE: See tests for usage examples.
get_release_type () {
    RELEASE_TAG=$1

    if [[ "$RELEASE_TAG" == *-* ]]
    then
        echo "non-prod"
        exit 0
    fi

    echo "prod"
}

# NOTE: See tests for usage examples.
exit_if_non_production_release () {
    RELEASE_TAG=$1

    RELEASE_TYPE=$(get_release_type $RELEASE_TAG)
    if [ "$RELEASE_TYPE" == "non-prod" ]
    then
        echo "INFO: non-production release"
        exit 0
    fi
}

# NOTE: See tests for usage examples.
get_version () {
    RELEASE_TAG=$1
    SPACE=""

    echo "$RELEASE_TAG" | sed "s/-rc/$SPACE/" | sed "s/v/$SPACE/"
}

# Exit if `BRANCH` is a hotfix release.
# NOTE: See tests for usage examples.
exit_if_hotfix () {
    BRANCH=$1

    if [[ "$BRANCH" == release/v*-hotfix ]]
    then
        echo "INFO: hotfix release"
        exit 0
    fi
}


# WARNING! Please be careful about positional arguments.
deployment_cleanup () {
  local script_dir_name=$1
  local build_id=$2
  local app_name=$3
  local other_file=$4

  if [[ $build_id != "" ]];
  then
    [ -z "$script_dir_name" ] && echo "provide the 'scripts' directory" && exit 1;
    [ -z "$app_name" ] && echo "provide the 'app_name/go-build' file" && exit 1;
    [ -z "$other_file" ] && echo "See Dockerfile for other files included during docker-build" && exit 1;

    for dir in $(ls); do
        if [[ $dir != $script_dir_name ]] &&
          [[ $dir != $app_name ]] &&
          [[ $dir != "Dockerfile" ]] &&
          [[ $dir != $other_file ]];
        then
          rm -rf $dir
        fi
    done

    echo "cleanup done"
    exit 0
  else
    echo "cleaning up is possible if substitution BUILD_ID is supplied" 
    exit 0
  fi
}
