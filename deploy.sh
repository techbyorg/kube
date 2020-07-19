#!/bin/bash

# props to https://github.com/zolmeister for writing this awesome script 
# any ugly parts were probably my doing (Austin)

set -e

function main () {
  #
  # Parse args
  #
  NAMESPACE="$1"

  if [ "$NAMESPACE" == "-h" ] || [ "$NAMESPACE" == "" ]; then
    cat << EOF
  Kubernetes Deploy

  Usage:
    ./deploy.sh NAMESPACE ACTION PROJECT [FLAGS]

  Available Commands:
    update                  create/update deployment
    semver                  version project
    yolo                    run: 'staging update' 'production update -s' 'semver -p patch'
                               (gives prompt between each step)
    logs                    tail project logs
    logsc                    tail project container logs (when multiple containers per pod)
    delete                  delete pods by project name

  Available Global Flags:
    -s                      skip building the project
    -t                      tag to deploy

  Available semver Flags:
    -p [patch|minor|major]  required, version type, defaults to patch


EOF
    exit 0
  fi

  local COMMAND="$2"
  if [ -z $COMMAND ]; then
    echo "Missing COMMAND"
    exit 1
  fi
  shift 2

  case $COMMAND in
    update)
      update "$@"
    ;;
    semver)
      semver "$@"
    ;;
    yolo)
      yolo "$@"
    ;;
    logs)
      logs "$@"
    ;;
    logsc)
      logs_container "$@"
    ;;
    delete)
      delete "$@"
    ;;
    *)
      echo "Error, unknown command $COMMAND" >&2
      exit 1
    ;;
  esac
}

function logs () {
  local PROJECT="$1"

  kubectl get pods --namespace="$NAMESPACE" | \
    grep "^\($PROJECT-\w\{5\}\)\|\($PROJECT-next-\w\{5\}\)" | \
    cut -d ' ' -f 1 | \
    xargs -n 1 -P 0 kubectl logs -f --namespace="$NAMESPACE" $CONTAINER
}

function logs_container () {
  local PROJECT="$1"
  local CONTAINER="$2"

  ./kubetail.sh $PROJECT -n $NAMESPACE -c $CONTAINER
}

function delete () {
  local PROJECT="$1"

  kubectl get pods --namespace="$NAMESPACE" | \
    grep "^\($PROJECT-\w\{5\}\)\|\($PROJECT-next-\w\{5\}\)" | \
    cut -d ' ' -f 1 | \
    xargs -n 1 -P 0 kubectl delete pod --namespace="$NAMESPACE"
}

function yolo () {
  local PROJECT="$1"

  if [ ! $NAMESPACE == "production" ]; then
    echo "Must use production namespace."
    exit 1
  fi

  # echo "./deploy.sh staging update $PROJECT -t latest"
  # read -p "press [ENTER] to continue"
  # ./deploy.sh staging update $PROJECT -t latest

  echo "./deploy.sh production update $PROJECT -t latest"
  read -p "check staging, then press [ENTER] to continue"
  ./deploy.sh production update $PROJECT -t latest

  echo "./deploy.sh production semver $PROJECT -s -p patch"
  read -p "check production, then press [ENTER] to continue"
  ./deploy.sh production semver $PROJECT -s -p patch

}

function update () {
  local PROJECT="$1"
  shift
  local TAG=$(get_current_version $PROJECT)
  local TIMESTAMP=$(date +%s)

  local SKIP_BUILD=0

  while getopts "st:f" opt; do
    case $opt in
      s)
        SKIP_BUILD=1
      ;;
      t)
        TAG=$OPTARG
        if [ $TAG != 'latest' ]; then
          SKIP_BUILD=1
        fi
      ;;
    esac
  done

  local UPDATING_FILE=$(project_deployment_file $PROJECT $TAG $TIMESTAMP)

  echo "Rolling update to tag $TAG"

  if [ $SKIP_BUILD == "0" ]; then
    update_repo $PROJECT
    build $PROJECT
    push $PROJECT $TAG
  else
    echo "Skipping build"
  fi

  kubectl apply -f $UPDATING_FILE --namespace="$NAMESPACE" --record
}

function semver () {
  local PROJECT="$1"
  shift
  local TAG=latest
  local SKIP_BUILD=0
  local TYPE=patch

  while getopts "sp:" opt; do
    case $opt in
      s)
        echo "Skipping build"
        SKIP_BUILD=1
      ;;
      p)
        TYPE=$OPTARG
      ;;
    esac
  done

  if [ $SKIP_BUILD == "0" ]; then
    update_repo $PROJECT
    build $PROJECT
    push $PROJECT $TAG
  fi


  local CURRENT_VERSION=$(get_current_version $PROJECT)
  local NEXT_VERSION=$(get_next_version $CURRENT_VERSION $TYPE)

  echo "Versioning $PROJECT from $CURRENT_VERSION to $NEXT_VERSION"
  set_version $PROJECT $NEXT_VERSION
}

function checkout_master () {
  local BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ ! $BRANCH = 'master' ]; then
    git checkout master
  fi
}

function get_current_version () {
  local PROJECT="$1"

  cd $(project_dir $PROJECT)
  checkout_master
  local TAG=$(git tag | sort -V -r | grep -m 1 .)
  if [ -z $TAG ]; then
    local VERSION="v0.0.0"
  else
    local VERSION=$(git tag | sort -V -r | grep -m 1 .)
  fi
  cd - 2>&1 >> /dev/null
  echo $VERSION
}

function set_version () {
  local PROJECT="$1"
  local VERSION="$2"

  cd $(project_dir $PROJECT)

  echo "Adding git and docker tags for version $VERSION"
  checkout_master
  git tag $VERSION
  git push origin master --tags
  docker tag $PROJECT gcr.io/free-roam-app/$PROJECT:$VERSION
  docker push gcr.io/free-roam-app/$PROJECT:$VERSION

  # clean up
  docker rmi gcr.io/free-roam-app/$PROJECT:$VERSION

  cd - 2>&1 >> /dev/null
}

function get_next_version () {
  local CURRENT_VERSION="$1"
  local TYPE="$2"
  local RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'

  local MAJOR=$(echo $CURRENT_VERSION | sed -e "s#$RE#\1#")
  local MINOR=$(echo $CURRENT_VERSION | sed -e "s#$RE#\2#")
  local PATCH=$(echo $CURRENT_VERSION | sed -e "s#$RE#\3#")
  local SPECIAL=$(echo $CURRENT_VERSION | sed -e "s#$RE#\4#")

  case $TYPE in
    major)
      MAJOR=$((MAJOR + 1))
      MINOR="0"
      PATCH="0"
    ;;
    minor)
      MINOR=$((MINOR + 1))
      PATCH="0"
    ;;
    patch)
      PATCH=$((PATCH + 1))
    ;;
    *)
      echo "Error, unknown semver type $TYPE" >&2
      exit 1
    ;;
  esac

  echo "v$MAJOR.$MINOR.$PATCH"
}

function push () {
  local PROJECT="$1"
  local TAG="$2"

  echo "pushing $PROJECT:$TAG"
  docker tag $PROJECT gcr.io/free-roam-app/$PROJECT:$TAG
  # gcloud docker -- push gcr.io/free-roam-app/$PROJECT:$TAG
  # run gcloud auth configure-docker
  docker push gcr.io/free-roam-app/$PROJECT:$TAG
}

function project_deployment_file () {
  local PROJECT="$1"
  local TAG="$2"
  local TIMESTAMP="$3"
  local FILE=./deployments/$(echo $PROJECT | sed s/-/_/g).yaml

  if [ ! -e $FILE ]; then
    echo "Project deployment file not found at $FILE"
    exit 1
  fi

  local TEMP_FILE=$(mktemp).yaml
  # compgen / sed stuff is to only replace defined vars
  source ./secrets/$NAMESPACE.env.sh
  cat $FILE | env -i bash -c "source ./secrets/$NAMESPACE.env.sh && TAG=$TAG TIMESTAMP=$TIMESTAMP NAMESPACE=$NAMESPACE envsubst '\$$(compgen -v | sed ':a;N;$!ba;s/\n/:\$/g')'" > $TEMP_FILE

  echo $TEMP_FILE
}

function project_dir () {
  local DIR="../$PROJECT"

  case $PROJECT in
    # custom-name)
    #   local DIR="../../different_path/$PROJECT"
    # ;;
    *)
      local DIR="../$PROJECT"
    ;;
  esac

  if [ ! -d "$DIR" ]; then
    echo "project directory not found for $PROJECT"
    exit 1
  fi

  echo $DIR
}

function update_repo () {
  local PROJECT="$1"

  echo "Checking out and updating to latest master, and updating deps"
  cd $(project_dir $PROJECT)
  checkout_master
  git pull origin master --tags
  cd -
}

function build () {
  local PROJECT="$1"

  cd $(project_dir $PROJECT)

  if [ -e ./package.json ]; then
    echo "pre-building project via npm"
    # npm install
    # redirect errors to /dev/null & don't fail if dist script doesn't exist
    npm run dist 2> /dev/null || true
  fi

  echo "Building Docker image"
  docker build -t $PROJECT .
  cd -
}

main "$@"

echo -e "Done!"
exit 0
