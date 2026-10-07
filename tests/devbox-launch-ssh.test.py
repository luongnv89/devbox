#!/usr/bin/env python3
"""SSH refresh regressions using synthetic HOME, fake Docker, and no host keys."""

import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import textwrap
import unittest


LAUNCH = Path(__file__).resolve().parents[1] / "devbox-launch.sh"


class SSHRefreshTests(unittest.TestCase):
    def setUp(self):
        # Keep UNIX socket paths below the BSD/macOS sockaddr_un limit.
        self.temp = tempfile.TemporaryDirectory(prefix="devbox-ssh-test-", dir="/tmp")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.ssh = self.home / ".ssh"
        self.ssh.mkdir(parents=True)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.tmp = self.root / "tmp"
        self.tmp.mkdir()
        self.volume = self.root / "volume"
        self.volume.mkdir()
        (self.volume / "existing-key").write_text("synthetic existing key\n")
        (self.volume / ".existing-config").write_text("synthetic existing config\n")
        (self.ssh / "config").write_text(f"IdentityFile {self.ssh}/id_fixture\n")
        (self.ssh / "id_fixture").write_text("synthetic key, not a secret\n")
        self.calls = self.root / "calls.jsonl"
        self.snapshot = self.root / "snapshot"
        self.env = os.environ.copy()
        self.env.update(
            HOME=str(self.home),
            TMPDIR=str(self.tmp),
            PATH=f"{self.bin}:{os.environ['PATH']}",
            MOCK_ROOT=str(self.root),
            MOCK_REAL_CP=shutil.which("cp"),
            MOCK_PYTHON=shutil.which("python3"),
            MOCK_CP_FAIL="",
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_GLOBAL=os.devnull,
        )
        self.write_mock("cp", '''
            import os, pathlib, sys
            args = sys.argv[1:]
            src, dst = args[-2:]
            mode = os.environ.get("MOCK_CP_FAIL", "")
            # Mode-bit check makes unreadable fixtures deterministic even as root.
            unreadable = (pathlib.Path(src).is_file()
                          and not pathlib.Path(src).is_symlink()
                          and pathlib.Path(src).stat().st_mode & 0o444 == 0)
            volume_failure = (mode == "volume" and "/volume/" in dst)
            if unreadable or pathlib.Path(src).name == mode or volume_failure:
                print("cp: synthetic fixture: Permission denied", file=sys.stderr)
                sys.exit(1)
            os.execv(os.environ["MOCK_REAL_CP"], ["cp"] + args)
        ''')
        self.write_mock("docker", '''
            import json, os, pathlib, shutil, subprocess, sys
            root = pathlib.Path(os.environ["MOCK_ROOT"])
            args = sys.argv[1:]
            with (root / "calls.jsonl").open("a") as log:
                log.write(json.dumps(args) + "\\n")
            if args[0] in ("info", "ps", "volume"):
                sys.exit(0)
            if args[0] != "run":
                sys.exit(2)
            mounts = [args[i + 1] for i, arg in enumerate(args[:-1]) if arg == "-v"]
            sources = [mount[:-len(":/src:ro")] for mount in mounts
                       if mount.endswith(":/src:ro")]
            if sources:
                src = pathlib.Path(sources[0])
                shutil.copytree(src, root / "snapshot", symlinks=True)
                (root / "staging-path").write_text(str(src.parent))
                # Execute the actual helper shell, substituting only mount paths.
                command = args[args.index("-c") + 1]
                # Also sandbox older helpers with literal mount paths, so a
                # regression can never delete a host /dst or read a host /src.
                command = command.replace("/src", str(src))
                command = command.replace("/dst", str(root / "volume"))
                sys.exit(subprocess.call(["sh", "-c", command, "sh",
                                          str(src), str(root / "volume")]))
            sys.exit(0)  # Container launch is recorded, never executed.
        ''')

    def write_mock(self, name, body):
        path = self.bin / name
        # Use the resolved interpreter, not a PATH lookup that could escape mocks.
        path.write_text(f"#!{self.env['MOCK_PYTHON']}\n" + textwrap.dedent(body))
        path.chmod(0o755)

    def launch(self):
        return subprocess.run(
            ["/bin/bash", str(LAUNCH), "-d", "-w", str(self.root), "-n", "ssh-test"],
            env=self.env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            timeout=30,
        )

    def runs(self):
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        return [args for args in calls if args[0] == "run"]

    def assert_host_abort(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("SSH staging failed", result.stderr)
        self.assertEqual(self.runs(), [], "helper and launcher must not run")
        self.assertEqual((self.volume / "existing-key").read_text(),
                         "synthetic existing key\n")
        self.assertEqual(list(self.tmp.iterdir()), [], "private staging must be cleaned")

    def test_injected_copy_failure_aborts_before_helper(self):
        # A late failure also verifies cleanup after an earlier file was copied.
        (self.ssh / "zz_failure_fixture").write_text("synthetic key\n")
        self.env["MOCK_CP_FAIL"] = "zz_failure_fixture"
        self.assert_host_abort(self.launch())

    def test_unreadable_key_aborts_before_helper(self):
        unreadable = self.ssh / "id_unreadable_fixture"
        unreadable.write_text("synthetic unreadable key\n")
        unreadable.chmod(0)
        self.addCleanup(unreadable.chmod, 0o600)
        self.assert_host_abort(self.launch())

    def test_nested_copy_failure_aborts_before_helper(self):
        nested = self.ssh / "nested"
        nested.mkdir()
        (nested / "failure_fixture").write_text("synthetic nested key\n")
        self.env["MOCK_CP_FAIL"] = "failure_fixture"
        self.assert_host_abort(self.launch())

    def test_symlink_copy_failure_aborts_before_helper(self):
        (self.ssh / "failure_link").symlink_to("id_fixture")
        self.env["MOCK_CP_FAIL"] = "failure_link"
        self.assert_host_abort(self.launch())

    def test_sockets_skipped_and_successful_refresh_preserves_entries(self):
        nested = self.ssh / "nested dir"
        nested.mkdir()
        (nested / "empty").mkdir()
        (nested / ".hidden key").write_text("synthetic hidden key\n")
        (self.ssh / ".dotfile").write_text("synthetic dotfile\n")
        (self.ssh / "file-link").symlink_to("id_fixture")
        (self.ssh / "directory-link").symlink_to("nested dir")
        (self.ssh / "dangling-link").symlink_to("missing")
        for path in (self.ssh / "agent.sock", nested / "agent.sock"):
            sock = socket.socket(socket.AF_UNIX)
            self.addCleanup(sock.close)
            sock.bind(str(path))
        (self.ssh / "socket-link").symlink_to("agent.sock")
        result = self.launch()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(self.runs()), 2, "helper and launcher must both run")
        self.assertFalse((self.snapshot / "agent.sock").exists())
        self.assertFalse((self.snapshot / "nested dir" / "agent.sock").exists())
        for tree in (self.snapshot, self.volume):
            self.assertEqual((tree / "id_fixture").read_text(),
                             "synthetic key, not a secret\n")
            self.assertEqual((tree / "nested dir" / ".hidden key").read_text(),
                             "synthetic hidden key\n")
            self.assertEqual((tree / ".dotfile").read_text(), "synthetic dotfile\n")
            self.assertTrue((tree / "nested dir" / "empty").is_dir())
            for name, target in (("file-link", "id_fixture"),
                                 ("directory-link", "nested dir"),
                                 ("dangling-link", "missing"),
                                 ("socket-link", "agent.sock")):
                self.assertTrue((tree / name).is_symlink())
                self.assertEqual(os.readlink(tree / name), target)
            self.assertEqual((tree / "config").read_text(),
                             "IdentityFile /root/.ssh/id_fixture\n")
            self.assertEqual((tree / "nested dir").stat().st_mode & 0o777, 0o700)
        self.assertFalse((self.volume / "existing-key").exists())
        self.assertFalse((self.volume / ".existing-config").exists())
        self.assertEqual(list(self.tmp.iterdir()), [])
        self.assertFalse(Path((self.root / "staging-path").read_text()).exists())
        self.assertEqual(list(self.volume.glob(".devbox-ssh-refresh.*")), [])

    def test_helper_copy_failure_preserves_existing_volume(self):
        self.env["MOCK_CP_FAIL"] = "volume"
        result = self.launch()
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(len(self.runs()), 1, "helper may run, launcher must not")
        self.assertEqual((self.volume / "existing-key").read_text(),
                         "synthetic existing key\n")
        self.assertEqual((self.volume / ".existing-config").read_text(),
                         "synthetic existing config\n")
        self.assertEqual(list(self.volume.glob(".devbox-ssh-refresh.*")), [])
        self.assertEqual(list(self.tmp.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
