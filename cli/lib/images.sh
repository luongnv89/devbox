# shellcheck shell=bash

# Published / first-class images (CI builds these only — see .github/workflows/build-images.yml)
DOCKER_DEV_IMAGES=(u2204dev u2404dev u2604dev devbox)

# Legacy names accepted by cdev run/build with a deprecation notice (not listed by cdev list)
DOCKER_DEV_DEPRECATED_IMAGES=(u2604dev-opencode)

docker_dev_is_deprecated_image() {
    local image="$1"
    local leg
    for leg in "${DOCKER_DEV_DEPRECATED_IMAGES[@]}"; do
        [ "$leg" = "$image" ] && return 0
    done
    return 1
}

# Maps legacy image names to their replacement; prints resolved name on stdout.
docker_dev_resolve_image() {
    local image="$1"
    case "$image" in
    u2604dev-opencode)
        log_info "u2604dev-opencode is deprecated; using u2604dev (OpenCode and other AI tools are already baked in)."
        log_info "Migration: cdev run --image u2604dev --mount-opencode --mount-pi (see CHANGELOG.md)."
        image="u2604dev"
        ;;
    esac
    printf '%s' "$image"
}

docker_dev_validate_image() {
    local image="$1"
    local img
    for img in "${DOCKER_DEV_IMAGES[@]}"; do
        [ "$img" = "$image" ] && return 0
    done
    usage_error "Unsupported image: ${image} (use: cdev list)"
}
