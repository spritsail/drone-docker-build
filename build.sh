#!/bin/sh
set -e

error() { >&2 echo -e "${RED}Error: $@${RESET}"; exit 1; }

# $PLUGIN_REPO          tag to this repo/repo to push to
# $PLUGIN_PATH          override working directory
# $PLUGIN_DOCKERFILE    override Dockerfile location
# $PLUGIN_BUILD_ARGS    comma/space separated build arguments
# $PLUGIN_USE_CACHE     override to disable --no-cache
# $PLUGIN_NO_LABELS     disable automatic image labelling
# $PLUGIN_ARGUMENTS     optional extra arguments to pass to `docker build`
# $PLUGIN_RM            a flag to immediately `docker rm` the built image

if [ -z "$PLUGIN_REPO" ]; then
    if [ -n "$PLUGIN_RM" ]; then
        PLUGIN_REPO="$DRONE_REPO_OWNER/$DRONE_REPO_NAME"
    else
        error "Missing 'repo' argument required for building"
    fi
fi

# Always specify pull so images are pulled, and intermediate containers removed
ARGS="--pull --force-rm"

# Override Dockerfile if specified
[ -n "$PLUGIN_DOCKERFILE" ] && ARGS="$ARGS --file=$PLUGIN_DOCKERFILE"

# Specify --no-cache unless caching is requested
[ "$PLUGIN_USE_CACHE" == "true" -o "$PLUGIN_USE_CACHE" == 1 ] || ARGS="$ARGS --no-cache"

while read -r arg; do
    # If arg is '%file: <filename>' then .parse and read file
    if echo "$arg" | grep -q "%file\\s*:\\s*"; then
        arg="${arg%%=*}=$(cat "$(echo ${arg#*:} | xargs)")"
    fi
    if [ -n "${arg// }" ]; then
        # Only add arguments if they're not empty
        # this prevents the '"docker build" requires exactly 1 argument.' error
        ARGS="$ARGS --build-arg $arg"
    fi
done << EOA
$(echo "$PLUGIN_BUILD_ARGS" | tr ',' '\n')
EOA

export VCS_REF="$DRONE_COMMIT_SHA"
export VCS_URL="$DRONE_REPO_LINK"
export VCS_BRANCH="$DRONE_COMMIT_BRANCH"
[ -n "$DRONE_JOB_STARTED" ] && \
    export BUILD_DATE="$(date -Isec -d "@$DRONE_JOB_STARTED")"

ARGS="$ARGS --build-arg VCS_REF=$VCS_REF"
ARGS="$ARGS --build-arg VCS_URL=$VCS_URL"
ARGS="$ARGS --build-arg VCS_BRANCH=$VCS_BRANCH"
ARGS="$ARGS --build-arg BUILD_DATE=$BUILD_DATE"

if [ -z "$PLUGIN_NO_LABELS" ]; then
    ARGS="$ARGS --label org.label-schema.vcs-ref=${VCS_REF:0:7}"
    ARGS="$ARGS --label org.label-schema.vcs-url=$VCS_URL"
    ARGS="$ARGS --label org.label-schema.vcs-branch=$VCS_BRANCH"
    ARGS="$ARGS --label org.label-schema.build-date=$BUILD_DATE"
    ARGS="$ARGS --label org.label-schema.schema-version=1.0"
fi

>&2 echo "+ docker build $ARGS $PLUGIN_ARGUMENTS --tag=$PLUGIN_REPO ${PLUGIN_PATH:-.}"

docker build \
    $ARGS \
    $PLUGIN_ARGUMENTS \
    --tag="$PLUGIN_REPO" \
    "${PLUGIN_PATH:-.}"

if [ -n "$PLUGIN_RM" ]; then
    docker image rm "$PLUGIN_REPO"
fi
