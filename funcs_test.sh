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

test_get_deployment_env_release_candidate_tag () {
  echo "Testing get_deployment_env - release candidate tag"
  got=$(get_deployment_env v1.2.3-rc)
  want=stage

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

  got=$(get_deployment_env v1.2.3-67)

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

test_get_deployment_hotfix_release_branch () {
  echo "Testing get_deployment_env - hotfix release branch"
  got=$(get_deployment_env hotfix/v1.2.3)
  want=stage

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

test_exit_if_unknown_env_unknown_force_deploy () {
  echo "Testing exit_if_unknown_env - unknown and force deploy"

  want=""
  got=$(exit_if_unknown_env "unknown" "force-deploy")

  if [ "$want" != "$got" ]
  then
    failure "'$want'" "'$got'"
  fi

  success
}

test_create_docker_image_test () {
  echo "Testing create_docker_image - test"

  got=$(create_docker_image "test" "royge/shutil" "royge/shutil" "1.0.0" "fg3rf23d" "develop")

  want="royge/shutil:latest docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  want="royge/shutil:1.0.0-fg3rf23d docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  success
}

test_create_docker_image_stage () {
  echo "Testing create_docker_image - stage"

  got=$(create_docker_image "stage" "royge/shutil" "royge/shutil" "1.0.0" "fg3rf23d" "release/v1.0.0")

  want="royge/shutil:beta docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  got=$(create_docker_image "stage" "royge/shutil" "royge/shutil" "1.0.1" "fg3rf23d" "release/v1.0.1-rc")

  want="royge/shutil:1.0.1-rc docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  success
}

test_create_docker_image_prod () {
  echo "Testing create_docker_image - prod"

  got=$(create_docker_image "prod" "royge/shutil" "royge/shutil" "1.0.0" "fg3rf23d" "v1.0.0")

  want="royge/shutil:stable docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  want="royge/shutil:1.0.0 docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  success
}

test_create_docker_image_stage_hotfix () {
  echo "Testing create_docker_image - stage hotfix"

  got=$(create_docker_image "stage" "royge/shutil" "royge/shutil" "1.0.1" "fg3rf23d" "hotfix/v1.0.1")

  want="royge/shutil:1.0.1-rc docker image pushed"
  if [[ "$got" != *"$want"* ]]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_release_type_prod () {
  echo "Testing get_release_type - prod"

  got=$(get_release_type "v1.1.0")

  want="prod"
  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_release_type_non_prod () {
  echo "Testing get_release_type - non-production"

  got=$(get_release_type "v1.1.0-58.1")

  want="non-prod"
  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_exit_if_non_production_release () {
  echo "Testing exit_if_unknown_env_unknown - v1.1.0-58.1"

  want="INFO: non-production release"
  got=$(exit_if_non_production_release "v1.1.0-58.1")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_version () {
  echo "Testing get_version - v1.1.10"

  want="1.1.10"
  got=$(get_version "v1.1.10")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_version_from_rc () {
  echo "Testing get_version - v1.1.12-rc"

  want="1.1.12"
  got=$(get_version "v1.1.12-rc")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_version_from_rc_with_extra () {
  echo "Testing get_version - v1.1.34-67-rc"

  want="1.1.34-67"
  got=$(get_version "v1.1.34-67-rc")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_version_from_hotfix () {
  echo "Testing get_version - hotfix/v1.1.34"

  want="1.1.34"
  got=$(get_version "hotfix/v1.1.34")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_version_from_release () {
  echo "Testing get_version - release/v1.2.34"

  want="1.2.34"
  got=$(get_version "release/v1.2.34")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_version_from_unknowns () {
  want="unknown"

  echo "Testing get_version - develop"
  got=$(get_version "develop")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  echo "Testing get_version - feature"
  got=$(get_version "feature/AM-1234-test")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  echo "Testing get_version - bugfix"
  got=$(get_version "bugfix/AM-1234-test")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_exit_if_hotfix_ok () {
  echo "Testing exit_if_hotfix - hotfix/v1.2.3"

  want="INFO: hotfix release"
  got=$(exit_if_hotfix "hotfix/v1.2.3")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_exit_if_hotfix_not_ok () {
  echo "Testing exit_if_hotfix - hotfix-1234"

  want=""
  got=$(exit_if_hotfix "hotfix-1234")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_cleanup () {
  echo "Testing cleanup"

  testdir=/tmp/shutiltest

  mkdir -p $testdir

  mkdir -p "$testdir/scripts"
  mkdir -p "$testdir/k8s"
  mkdir -p "$testdir/others"
  touch "$testdir/dummy.txt"
  touch "$testdir/others/sample.txt"

  contents=$(ls $testdir)
  contents=$(echo "$contents" | tr '\r\n' ' ')
  if [[ $contents != "dummy.txt k8s others scripts " ]]; then
    >&2 echo "FAILURE!!! unable to prepare test"
    exit 1
  fi

  contents=$(ls "$testdir/others")
  if [[ $contents != "sample.txt" ]]; then
    >&2 echo "FAILURE!!! unable to prepare test file"
    exit 1
  fi

  cleanup $testdir scripts,k8s
  contents=$(ls $testdir)

  want="k8s scripts "
  got=$(echo "$contents" | tr '\r\n' ' ')
  if [[ $got != $want ]]; then
    failure "$want" "$got"
  fi

  cleanup $testdir scripts
  contents=$(ls $testdir)

  want="scripts "
  got=$(echo "$contents" | tr '\r\n' ' ')
  if [[ $got != $want ]]; then
    failure "$want" "$got"
  fi

  cleanup $testdir
  contents=$(ls $testdir)

  want=" "
  got=$(echo "$contents" | tr '\r\n' ' ')
  if [[ $got != $want ]]; then
    failure "$want" "$got"
  fi

  rm -rf $testdir

  success
}

test_get_branch_type_feature () {
  echo "Testing get_branch_type - feature"

  want="feature"
  got=$(get_branch_type "feature/ABC-1234")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_branch_type_release () {
  echo "Testing get_branch_type - release"

  want="release"
  got=$(get_branch_type "release/v.1.2.3")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_branch_type_hotfix () {
  echo "Testing get_branch_type - hotfix"

  want="hotfix"
  got=$(get_branch_type "hotfix/v.1.2.4")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_get_branch_type_unknowns () {
    echo "Testing get_branch_type - unknown(s)"

  want="unknown"
  got=$(get_branch_type "")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "feature")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "release")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "hotfix")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "feature-")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "release-")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "hotfix-")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  got=$(get_branch_type "v1.2.3")

  if [ "$want" != "$got" ]
  then
    failure "$want" "$got"
  fi

  success
}

test_validate_envs_valid
test_validate_envs_invalid
test_get_deployment_env_develop_branch
test_get_deployment_env_release_branch
test_get_deployment_env_release_tag
test_get_deployment_env_release_candidate_tag
test_get_deployment_env_unknown
test_get_deployment_env_feature_branch
test_get_deployment_env_hotfix_branch
test_get_deployment_env_bugfix_branch
test_get_deployment_hotfix_release_branch
test_exit_if_unknown_env_test
test_exit_if_unknown_env_unknown
test_exit_if_unknown_env_unknown_force_deploy
test_create_docker_image_test
test_create_docker_image_stage
test_create_docker_image_stage_hotfix

## WARNING: Dependent of test_create_docker_image_stage
test_create_docker_image_prod

test_get_release_type_prod
test_get_release_type_non_prod
test_exit_if_non_production_release
test_get_version
test_get_version_from_rc
test_get_version_from_rc_with_extra
test_get_version_from_hotfix
test_get_version_from_release
test_get_version_from_unknowns
test_exit_if_hotfix_ok
test_exit_if_hotfix_not_ok

test_cleanup
test_get_branch_type_feature
test_get_branch_type_release
test_get_branch_type_hotfix
test_get_branch_type_unknowns
