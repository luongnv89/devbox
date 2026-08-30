# shellcheck shell=bash

docker_dev_cmd_list() {
    local format="text"
    while [ $# -gt 0 ]; do
        case "$1" in
        --format)
            format="$2"
            shift 2
            ;;
        -h | --help)
            echo "Usage: cdev list [--format text|json]"
            return 0
            ;;
        *) usage_error "Unknown list option: $1" ;;
        esac
    done

    # shellcheck source=images.sh
    source "$(dirname "${BASH_SOURCE[0]}")/images.sh"

    case "$format" in
    json)
        printf '['
        local first=1 img
        for img in "${DOCKER_DEV_IMAGES[@]}"; do
            [ "$first" -eq 1 ] || printf ','
            first=0
            printf '"%s"' "$img"
        done
        printf ']\n'
        ;;
    text)
        echo "Available images:"
        local img
        for img in "${DOCKER_DEV_IMAGES[@]}"; do
            echo "  - ${img}"
        done
        ;;
    *)
        usage_error "Unknown format: ${format}"
        ;;
    esac
}
