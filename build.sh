#!/bin/sh
set -e

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'
error() { >&2 echo -e "${RED}Error: $@${RESET}"; exit 1; }

# $PLUGIN_REPO          tag to this repo/repo to push to
# $PLUGIN_PATH          override working directory
# $PLUGIN_DOCKERFILE    override Dockerfile location
# $PLUGIN_BUILD_ARGS    comma/space separated build arguments
# $PLUGIN_USE_CACHE     override to disable --no-cache
# $PLUGIN_NO_LABELS     disable automatic image labelling
# $PLUGIN_ARGUMENTS     optional extra arguments to pass to `docker build`
# $PLUGIN_RM            a flag to immediately `docker rm` the built image
# $PLUGIN_SQUASH        builds with --squash
# $PLUGIN_MAKE          provides makeflags concurrent of nproc

if [ -z "$PLUGIN_REPO" ]; then
    if [ -n "$PLUGIN_RM" ]; then
        PLUGIN_REPO="$DRONE_REPO_OWNER/$DRONE_REPO_NAME"
    else
        error "Missing 'repo' argument required for building"
    fi
fi

# Always specify pull so images are pulled, and intermediate containers removed
ARGS="--pull\0--force-rm"

# Override Dockerfile if specified
[ -n "$PLUGIN_DOCKERFILE" ] && ARGS="$ARGS\0--file=$PLUGIN_DOCKERFILE"

# Squash image if requested
[ -n "$PLUGIN_SQUASH" ] && ARGS="$ARGS\0--squash"

# Specify MAKEFLAGS job concurrency flag
[ -n "$PLUGIN_MAKE" ] && ARGS="$ARGS\0--build-arg\0MAKEFLAGS=-j$(nproc)"

# Specify --no-cache unless caching is requested
[ -z "$PLUGIN_USE_CACHE" ] && ARGS="$ARGS\0--no-cache"

while read -r arg; do
    # If arg is '%file: <filename>' then .parse and read file
    if echo "$arg" | grep -q "%file\\s*:\\s*"; then
        value=$(cat "$(echo ${arg#*:} | xargs)")
        name="$(basename "$(echo ${arg//*:} | xargs)" | tr a-z A-Z)"
        arg="$name=$value"
    fi
    if [ -n "${arg// }" ]; then
        # Only add arguments if they're not empty
        # this prevents the '"docker build" requires exactly 1 argument.' error
        ARGS="$ARGS\0--build-arg\0${arg}"
    fi
done << EOA
$(echo "$PLUGIN_BUILD_ARGS" | tr ',' '\n')
EOA

export VCS_REF="$DRONE_COMMIT_SHA"
export VCS_URL="$DRONE_REPO_LINK"
export VCS_BRANCH="$DRONE_COMMIT_BRANCH"
[ -n "$DRONE_JOB_STARTED" ] && \
    export BUILD_DATE="$(date -Isec -d "@$DRONE_JOB_STARTED")"

ARGS="$ARGS\0--build-arg\0VCS_REF=$VCS_REF"
ARGS="$ARGS\0--build-arg\0VCS_URL=$VCS_URL"
ARGS="$ARGS\0--build-arg\0VCS_BRANCH=$VCS_BRANCH"
ARGS="$ARGS\0--build-arg\0BUILD_DATE=$BUILD_DATE"

if [ -z "$PLUGIN_NO_LABELS" ]; then
    ARGS="$ARGS\0--label\0org.label-schema.vcs-ref=${VCS_REF:0:7}"
    ARGS="$ARGS\0--label\0org.label-schema.vcs-url=$VCS_URL"
    ARGS="$ARGS\0--label\0org.label-schema.vcs-branch=$VCS_BRANCH"
    ARGS="$ARGS\0--label\0org.label-schema.build-date=$BUILD_DATE"
    ARGS="$ARGS\0--label\0org.label-schema.schema-version=1.0"
fi

>&2 echo "+ docker build ${ARGS//\\0/ } $PLUGIN_ARGUMENTS --tag=$PLUGIN_REPO ${PLUGIN_PATH:-.}"

# Set CWD to the same directory as is specified in PLUGIN_PATH
cd ${PLUGIN_PATH:-.}

# Un-escape the NULL characters to fix arguments with spaces in
printf "$ARGS${PLUGIN_ARGUMENTS//,/\0}\0--tag=${PLUGIN_REPO}\0$PWD" | xargs -0 docker build

if [ -n "$PLUGIN_RM" ]; then
    docker image rm "$PLUGIN_REPO"
fi
