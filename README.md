[hub]: https://hub.docker.com/r/spritsail/docker-build
[git]: https://github.com/spritsail/drone-docker-build
[drone]: https://drone.spritsail.io/spritsail/docker-build
[mbdg]: https://microbadger.com/images/spritsail/docker-build

# [spritsail/docker-build][hub]
[![Layers](https://images.microbadger.com/badges/image/spritsail/docker-build.svg)][mbdg]
[![Latest Version](https://images.microbadger.com/badges/version/spritsail/docker-build.svg)][hub]
[![Git Commit](https://images.microbadger.com/badges/commit/spritsail/docker-build.svg)][git]
[![Docker Stars](https://img.shields.io/docker/stars/spritsail/docker-build.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/spritsail/docker-build.svg)][hub]
[![Build Status](https://drone.spritsail.io/api/badges/spritsail/drone-docker-build/status.svg)][drone]

A plugin for [Drone CI](https://github.com/drone/drone) to build and label Docker images with minimal effort

## Supported tags and respective `Dockerfile` links

`latest` - [(Dockerfile)](https://github.com/spritsail/drone-docker-build/blob/master/Dockerfile)

## Configuration

An example configuration of how the plugin should be configured:
```yaml
pipeline:
  build:
    image: spritsail/docker-build
    volumes: [ '/var/run/docker.sock:/var/run/docker.sock' ]
    repo: user/image-name:optional-tag
    build_args:
    - BUILD_ARG=value
```

### Available options
- `repo`          tag to this repo/repo to push to. _required_
- `path`          specify the build directory (or URL). _default: `.`_
- `cwd`           cd before calling docker build. _optional_
- `dockerfile`    override Dockerfile location. _default: `Dockerfile`_
- `buildkit`      set false to disable buildkit. _default: `true`_
- `use_cache`     override to disable `--no-cache`. _default: `false`_
- `no_labels`     disable automatic image labelling. _default: `false`_
- `build_args`    additional build arguments. _optional_
- `arguments`     optional extra arguments to pass to `docker build`. _optional_
- `make`          provides MAKEFLAGS=-j$(nproc) as a build-argument
- `rm`            a flag to immediately `docker rm` the built image. _optional_
- `squash`        squash the built image into one layer. _optional_
