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

if [ -z "$PLUGIN_REPO" ]; then
    error "Missing 'repo' argument required for building"
fi

# Always specify pull so images are pulled, and intermediate containers removed
ARGS="--pull --force-rm"

# Override Dockerfile if specified
[ -n "$PLUGIN_DOCKERFILE" ] && ARGS="$ARGS --file=$PLUGIN_DOCKERFILE"

# Specify --no-cache unless caching is requested
[ "$PLUGIN_USE_CACHE" == "true" -o "$PLUGIN_USE_CACHE" == 1 ] || ARGS="$ARGS --no-cache"

for arg in $(echo "$PLUGIN_BUILD_ARGS" | tr ',' ' '); do
    ARGS="$ARGS --build-arg $arg"
done

export VCS_REF="$DRONE_COMMIT_SHA"
export VCS_URL="$DRONE_REPO_LINK"
export VCS_BRANCH="$DRONE_REPO_BRANCH"
export BUILD_DATE="$(date -Isec -d "@$DRONE_JOB_STARTED")"

ARGS="$ARGS --build-arg VCS_REF=$VCS_REF"
ARGS="$ARGS --build-arg VCS_URL=$VCS_URL"
ARGS="$ARGS --build-arg VCS_BRANCH=$VCS_BRANCH"
ARGS="$ARGS --build-arg BUILD_DATE=$BUILD_DATE"

if [ -z "$PLUGIN_NO_LABELS" ]; then
    ARGS="$ARGS --label org.label-schema.vcs_ref=$VCS_REF"
    ARGS="$ARGS --label org.label-schema.vcs_url=$VCS_URL"
    ARGS="$ARGS --label org.label-schema.vcs_branch=$VCS_BRANCH"
    ARGS="$ARGS --label org.label-schema.build_date=$BUILD_DATE"
    ARGS="$ARGS --label org.label-schema.version=1.0"
fi

>&2 echo "+ docker build $ARGS $PLUGIN_ARGUMENTS --tag=$PLUGIN_REPO ${PLUGIN_PATH:-.}"

exec docker build \
    $ARGS \
    $PLUGIN_ARGUMENTS \
    --tag="$PLUGIN_REPO" \
    "${PLUGIN_PATH:-.}"
