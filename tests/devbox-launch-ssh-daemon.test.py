#!/usr/bin/env python3
"""Opt-in Docker name-reservation check: synthetic volume only, no host mounts.

Run: python3 tests/devbox-launch-ssh-daemon.test.py
Requires an already available alpine:latest image; never pulls or builds.
"""

import subprocess
import time
import uuid


def main():
    deadline = time.monotonic() + 240
    scope = "devbox-ssh-name-test-" + uuid.uuid4().hex
    name, volume = scope + "-refresh", scope + "-volume"
    image = "alpine:latest"
    volume_created = False

    def docker(*args, check=True):
        result = subprocess.run(
            ["docker", *args], text=True, capture_output=True,
            timeout=max(1, min(30, deadline - time.monotonic())),
        )
        if check and result.returncode:
            raise AssertionError(f"docker {args}: {result.stderr}")
        return result

    try:
        print(f"Resources: container={name}, volume={volume}, image={image}", flush=True)
        docker("image", "inspect", image)
        docker("volume", "create", volume)
        volume_created = True
        docker("run", "--pull=never", "--rm", "-d", "--name", name,
               "-v", volume + ":/dst", image, "sh", "-c", '''
                   set -eu
                   printf 'existing synthetic key\n' > /dst/existing
                   mkdir /dst/staged
                   printf 'complete synthetic snapshot\n' > /dst/staged/config
                   touch /dst/ready
                   while [ ! -f /dst/release ]; do sleep 0.1; done
                   rm /dst/existing /dst/ready /dst/release
                   mv /dst/staged/config /dst/config
                   rmdir /dst/staged
               ''')
        for _ in range(100):
            ready = docker("exec", name, "test", "-f", "/dst/ready", check=False)
            if ready.returncode == 0:
                break
            time.sleep(0.05)
        else:
            raise AssertionError("A did not reach staging/predelete pause")
        contender = docker("run", "--pull=never", "--rm", "--name", name,
                           "-v", volume + ":/dst", image, "sh", "-c",
                           "rm -rf /dst/*; touch /dst/contender-ran", check=False)
        assert contender.returncode == 125, contender
        assert "already in use" in contender.stderr, contender.stderr
        intact = docker("exec", name, "sh", "-c",
                        "set -eu; test ! -e /dst/contender-ran; "
                        "cat /dst/existing /dst/staged/config")
        assert intact.stdout == "existing synthetic key\ncomplete synthetic snapshot\n"
        print("PASS: daemon rejected competing same-name helper before execution; "
              "A's staged and existing contents retained")
        docker("exec", name, "touch", "/dst/release")
        # Wait for --rm, not merely process exit, before testing name reuse.
        for _ in range(100):
            if docker("container", "inspect", name, check=False).returncode:
                break
            time.sleep(0.05)
        else:
            raise AssertionError("A was not removed by --rm")
        subsequent = docker("run", "--pull=never", "--rm", "--name", name,
                            "-v", volume + ":/dst", image, "sh", "-c",
                            "set -eu; test ! -e /dst/existing; "
                            "test ! -e /dst/contender-ran; cat /dst/config")
        assert subsequent.stdout == "complete synthetic snapshot\n"
        print("PASS: A published its complete snapshot; subsequent same-name "
              "helper succeeded after --rm released reservation")
    finally:
        # Remove only this run's uniquely scoped resources, including on timeout.
        subprocess.run(["docker", "rm", "-f", name], capture_output=True, timeout=20)
        if volume_created:
            cleanup = subprocess.run(["docker", "volume", "rm", volume],
                                     capture_output=True, timeout=20)
            assert cleanup.returncode == 0, cleanup.stderr
    print("PASS: uniquely scoped container/volume cleanup completed")


if __name__ == "__main__":
    main()
