#!/usr/bin/env bash

# Separator line.
sep () {
  echo "====================="
}

success () {
  echo "SUCCESS!"
}

failure () {
  want=$1
  got=$2

  if [ "$want" != "" ]
  then
    >&2 echo "FAILURE!!! want $want, got $got"
    exit 1
  fi

  echo "FAILURE!!!"
}

source ${PWD}/funcs.sh

test_remove_1st () {
  echo "Testing remove_1st"

  target="v1.4.5"
  want="1.4.5"

  got=$(remove_1st $target)

  if [ $got != $want ]
  then
    failure "$want" "$got"
    exit 1
  fi

  success
}

test_validate_envs_valid () {
  echo "Testing validate_envs - VALID"

  PROJECT_ID="my-project"
  VERSION=1.4.5

  got=$(validate_envs PROJECT_ID VERSION)
  if [ "$got" != "" ]
  then
    failure
    exit 1
  fi

  success
}

test_validate_envs_invalid () {
  echo "Testing validate_envs - INVALID"
  got=$(validate_envs SHORT_SHA)
  if [ "$got" == "" ]
  then
    failure
    exit 1
  fi

  success
}

test_get_deployment_env_develop_branch () {
  echo "Testing get_deployment_env - develop branch"
  branch=develop
  got=$(get_deployment_env $branch)
  want=test

  if [ "$want" != "$got" ]
  then
    failure $want $got
  fi

  success
}

test_get_deployment_env_release_branch () {
  echo "Testing get_deployment_env - release branch"
  got=$(get_deployment_env release/v1.2.3)
  want=stage

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_deployment_env_release_tag () {
  echo "Testing get_deployment_env - release tag"
  got=$(get_deployment_env v1.2.3)
  want=prod

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_deployment_env_unknown () {
  echo "Testing get_deployment_env - unknown"
  got=$(get_deployment_env)
  want=unknown

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_deployment_env_feature_branch () {
  echo "Testing get_deployment_env - feature branch"
  got=$(get_deployment_env feature/FE-1234-testing)
  want=unknown

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_deployment_env_hotfix_branch () {
  echo "Testing get_deployment_env - hotfix branch"
  got=$(get_deployment_env hotfix/FE-1234-testing)
  want=unknown

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_deployment_env_bugfix_branch () {
  echo "Testing get_deployment_env - bugfix branch"
  got=$(get_deployment_env bugfix/FE-1234-testing)
  want=unknown

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_exit_if_unknown_env_test () {
  echo "Testing exit_if_unknown_env - test"

  want=""
  got=$(exit_if_unknown_env "test")

  if [ "$want" != "$got" ]
  then
    failure $want $got
  fi

  success
}

test_exit_if_unknown_env_unknown () {
  echo "Testing exit_if_unknown_env - unknown"

  want="INFO: not for deployment"
  got=$(exit_if_unknown_env "unknown")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_remove_1st
test_validate_envs_valid
test_validate_envs_invalid
test_get_deployment_env_develop_branch
test_get_deployment_env_release_branch
test_get_deployment_env_release_tag
test_get_deployment_env_unknown
test_get_deployment_env_feature_branch
test_get_deployment_env_hotfix_branch
test_get_deployment_env_bugfix_branch
test_exit_if_unknown_env_test
test_exit_if_unknown_env_unknown
