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
    echo "stage"
    exit 0
  fi

  if [ "$env" == "unknown" ] && [[ "$branch_or_tag" == v*-* ]]
  then
    echo "unknown"
    exit 0
  fi

  if [ "$env" == "unknown" ] && [[ "$branch_or_tag" == hotfix/v* ]]
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
#
# WARNING! Please be careful about positional arguments.
#
# NOTE: See tests for usage example.
create_docker_image () {
    ENV=$1
    IMAGE=$2
    RELEASE_IMAGE=$3
    VERSION=$4
    SHORT_SHA=$5
    BRANCH_OR_TAG=$6

    # Check if docker daemon is running.
    # Credits to: https://stackoverflow.com/a/55283209
    if ! docker info > /dev/null 2>&1; then
      echo "This script uses docker, and it isn't running - please start docker and try again!"
      exit 1
    fi

    TAG=$(get_version $BRANCH_OR_TAG)

    # We don't create a new docker image for production environment except
    # for hotfix.
    if [ "$ENV" != "prod" ]
    then
        if [ "$TAG" == "unknown" ]; then
            TAG=$VERSION-$SHORT_SHA
        fi

        docker build -t $IMAGE .
        docker tag $IMAGE:latest $IMAGE:$TAG
        docker push $IMAGE:latest

        echo "$IMAGE:latest docker image pushed"

        docker push $IMAGE:$TAG
        echo "$IMAGE:$TAG docker image pushed"
    fi

    if [ "$ENV" == "stage" ]
    then
        if [ "$TAG" == "" ]; then
            echo "Invalid release branch name. Please follow this pattern release/v1.2.3 in your branch name."
            exit 1
        fi

        docker tag $IMAGE:latest $IMAGE:beta
        docker tag $IMAGE:latest $IMAGE:$TAG-beta
        docker push $IMAGE:beta
        docker push $IMAGE:$TAG-beta

        echo "$IMAGE:beta docker image pushed"

        # Release candidate tag will create a release candidate docker image.
        if [[ "$BRANCH_OR_TAG" == v*-rc ]]
        then
            docker tag $IMAGE:latest $IMAGE:$TAG-rc
            docker push $IMAGE:$TAG-rc

            echo "$IMAGE:$TAG-rc docker image pushed"
        fi

        BRANCH_TYPE=$(get_branch_type $BRANCH_OR_TAG)
        if [ "$BRANCH_TYPE" == "hotfix" ]
        then
            docker tag $IMAGE:latest $IMAGE:$TAG-rc

            docker push $IMAGE:$TAG-rc
            echo "$IMAGE:$TAG-rc docker image pushed"
            exit 0
        fi

        docker push $IMAGE:$TAG
        echo "$IMAGE:$TAG docker image pushed"
    fi

    if [ "$ENV" == "prod" ]
    then
        docker pull $RELEASE_IMAGE:$TAG-rc

        # Create production docker image tag from release candidate image.
        docker tag $RELEASE_IMAGE:$TAG-rc $IMAGE:stable
        docker tag $RELEASE_IMAGE:$TAG-rc $IMAGE:$TAG

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
    BRANCH_OR_TAG=$1
    SPACE=""

    if [[ "$BRANCH_OR_TAG" != v*-rc ]] && \
        [[ "$BRANCH_OR_TAG" != v* ]] && \
        [[ "$BRANCH_OR_TAG" != hotfix/v* ]] && \
        [[ "$BRANCH_OR_TAG" != release/v* ]]
        then
            echo "unknown"
            exit 0
    fi

    echo "$BRANCH_OR_TAG" | \
        sed "s/-rc/$SPACE/" | \
        sed "s/v/$SPACE/" | \
        sed "s/hotfix\//$SPACE/" | \
        sed "s/release\//$SPACE/"
}

# Exit if `BRANCH` is a hotfix release.
# NOTE: See tests for usage examples.
exit_if_hotfix () {
    BRANCH=$1

    if [[ "$BRANCH" == hotfix/v* ]]
    then
        echo "INFO: hotfix release"
        exit 0
    fi
}

# NOTE: See tests for usage example
cleanup () {
    local target=$1
    local excludes=$(echo $2 | tr "," " ")

    [ -z "$target" ] && echo "provide the 'target' directory" && exit 1;

    for item in $(ls $target); do
        found="no"
        for v in $excludes; do
            if [[ $item == $v ]]; then
                found="yes"
                break
            fi
        done

        if [[ $found == "no" ]]; then
            rm -rf "$target/$item"
        fi
    done

    echo "cleanup done"
}

get_branch_type () {
    BRANCH=$1

    if [[ "$BRANCH" == feature/* ]]
    then
        echo "feature"
        exit 0
    fi

    if [[ "$BRANCH" == release/* ]]
    then
        echo "release"
        exit 0
    fi

    if [[ "$BRANCH" == hotfix/* ]]
    then
        echo "hotfix"
        exit 0
    fi

    echo "unknown"
}
