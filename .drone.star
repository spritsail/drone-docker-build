repo = "spritsail/docker-build"
architectures = ["amd64", "arm64"]

def main(ctx):
  builds = []
  depends_on = []

  for arch in architectures:
    key = "build-%s" % arch
    builds.append(step(arch, key))
    depends_on.append(key)

  builds.extend(publish(depends_on))

  return builds

def step(arch, key):
  return {
    "kind": "pipeline",
    "name": key,
    "platform": {
      "os": "linux",
      "arch": arch,
    },
    "steps": [
      {
        "name": "build",
        "image": "registry.spritsail.io/spritsail/docker-build",
        "pull": "always",
      },
      {
        # Build again, this time with the newly 'just-built' image, as a test
        "name": "test",
        "image": "drone/${DRONE_REPO}/${DRONE_BUILD_NUMBER}:${DRONE_STAGE_OS}-${DRONE_STAGE_ARCH}",
        "pull": "never",
      },
      {
        "name": "publish",
        "pull": "always",
        "image": "registry.spritsail.io/spritsail/docker-publish",
        "settings": {
          "registry": {"from_secret": "registry_url"},
          "login": {"from_secret": "registry_login"},
        },
        "when": {
          "branch": ["master"],
          "event": ["push"],
        },
      },
    ],
  }

def publish(depends_on):
  return [
    {
      "kind": "pipeline",
      "name": "publish-manifest-%s" % name,
      "depends_on": depends_on,
      "platform": {
        "os": "linux",
      },
      "steps": [
        {
          "name": "publish",
          "image": "registry.spritsail.io/spritsail/docker-multiarch-publish",
          "pull": "always",
          "settings": {
            "src_registry": {"from_secret": "registry_url"},
            "src_login": {"from_secret": "registry_login"},
            "dest_registry": registry,
            "dest_repo": repo,
            "dest_login": {"from_secret": login_secret},
          },
          "when": {
            "branch": ["master"],
            "event": ["push"],
          },
        },
      ],
    }
    for name, registry, login_secret in [
      ("dockerhub", "index.docker.io", "docker_login"),
      ("spritsail", "registry.spritsail.io", "spritsail_login"),
      ("ghcr", "ghcr.io", "ghcr_login"),
    ]
  ]
