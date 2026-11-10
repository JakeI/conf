"""Run from the repository root: python3 -B -m unittest discover -s bin/tests.

Viewers are isolated mocks. Optional integration tests exercise installed
mdcat/less in test-owned terminals; no desktop applications are opened.
"""

import errno
import fcntl
import json
import os
from pathlib import Path
import re
import select
import shutil
import sqlite3
import struct
import subprocess
import sys
import tempfile
import termios
import threading
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "batcat-extended"
REAL_MDCAT = shutil.which("mdcat")
REAL_LESS = shutil.which("less")
REAL_VD = shutil.which("vd")
REAL_PDFTOTEXT = shutil.which("pdftotext")
MOCK = f"#!{sys.executable}\n" + r'''
import json
import os
from pathlib import Path
import sys
import termios

program = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["TEST_TOOL_LOG"], "a") as log:
    log.write(json.dumps({
        "program": program,
        "args": args,
        "pager": os.environ.get("MDCAT_PAGER"),
        "tty_flags": termios.tcgetattr(0)[3] if sys.stdin.isatty() else None,
    }) + "\n")

status = int(os.environ.get("TEST_EXIT_" + program.upper().replace("-", "_"), "0"))
if status:
    print(program + " failed", file=sys.stderr)
    sys.exit(status)

if program in ("batcat", "mdcat"):
    files = args[args.index("--") + 1:] if "--" in args else ["-"]
    for name in files:
        sys.stdout.write(sys.stdin.read() if name == "-" else Path(name).read_text())
elif program == "less":
    sys.stdout.write(sys.stdin.read())
elif program == "tput":
    sys.stdout.write("\033[32m" if args == ["setaf", "2"] else "\033[0m")
elif program == "figlet":
    sys.stdout.write("FIGLET: " + sys.stdin.read())
elif program in ("eza", "tv", "graphml2unicode"):
    sys.stdout.write("\033[31mRENDERED " + program + "\033[0m\n")
elif program == "pdftotext":
    sys.stdout.write("Extracted PDF text\n")
elif program == "wslpath":
    sys.stdout.write(os.environ.get("TEST_WINDOWS_PATH", "C:\\images\\image with spaces.png") + "\n")
elif program == "vd" and os.environ.get("TEST_REAL_VD"):
    import subprocess
    sys.exit(subprocess.run([
        os.environ["TEST_REAL_VD"], "--nothing", "--batch", "--output=-", *args,
    ]).returncode)
'''


class BatcatExtendedTests(unittest.TestCase):
    def setUp(self):
        scratch = "/tmp/opencode" if Path("/tmp/opencode").is_dir() else None
        self.temp = tempfile.TemporaryDirectory(prefix="batcat-extended-", dir=scratch)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "tools with spaces"
        self.bin.mkdir()
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.log = self.root / "tools.jsonl"
        self.env = {
            "HOME": str(self.home),
            "PATH": str(self.bin),
            "TERM": "xterm-256color",
            "LANG": "C.UTF-8",
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "TEST_TOOL_LOG": str(self.log),
        }
        for tool in (
            "batcat", "eza", "tv", "vd", "viu", "tdf", "pdftotext", "graphml2unicode",
            "xdg-open", "explorer.exe", "wslpath", "less", "tput",
        ):
            self.mock(self.bin / tool)
        sed = shutil.which("sed")
        if not sed:
            self.skipTest("sed is needed for plain rendered output")
        (self.bin / "sed").symlink_to(sed)
        stty = shutil.which("stty")
        if stty:
            (self.bin / "stty").symlink_to(stty)
        self.calls = []

    def mock(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(MOCK)
        path.chmod(0o755)

    def file(self, name, content="# Heading\n\n**Text**\n"):
        path = self.root / name
        path.write_text(content)
        return path

    def run_cli(self, *args, terminal=False, stdin_terminal=False, input="", wsl=None, cwd=None, kitty_support=None):
        self.log.unlink(missing_ok=True)
        command = ["/bin/bash", str(SCRIPT), *args]
        if wsl is not None:
            override = 'source "$1"; is_wsl() { return ' + ("0" if wsl else "1") + '; }; main "${@:2}"'
            command = ["/bin/bash", "-c", override, "test", str(SCRIPT), *args]
        cwd = self.root if cwd is None else cwd
        if kitty_support is not None:
            if not (self.bin / "stty").exists():
                self.skipTest("stty is needed for graphics probing")
            terminal = stdin_terminal = True
        if not terminal and not stdin_terminal:
            result = subprocess.run(
                command, cwd=cwd, env=self.env, input=input,
                text=True, capture_output=True, timeout=10,
            )
        else:
            master, slave = os.openpty()
            self.addCleanup(os.close, master)
            chunks = []
            probe_buffer = b""
            replied = False

            def read_terminal():
                nonlocal probe_buffer, replied
                while True:
                    try:
                        chunk = os.read(master, 4096)
                    except OSError as error:
                        if error.errno == errno.EIO:
                            break
                        raise
                    if not chunk:
                        break
                    chunks.append(chunk)
                    if kitty_support is not None and not replied:
                        probe_buffer += chunk
                        match = re.search(rb"_Gi=(\d+),a=q", probe_buffer)
                        if match:
                            if kitty_support != "timeout":
                                reply = b"OK" if kitty_support else b"ENOTSUP"
                                os.write(master, b"\033_Gi=" + match[1] + b";" + reply + b"\033\\")
                            replied = True

            def claim_terminal():
                os.setsid()
                fcntl.ioctl(0, termios.TIOCSCTTY, 0)

            with subprocess.Popen(
                command, cwd=cwd, env=self.env, text=True,
                stdin=slave if stdin_terminal else subprocess.PIPE,
                stdout=slave if terminal else subprocess.PIPE,
                stderr=subprocess.PIPE,
                preexec_fn=claim_terminal if kitty_support is not None else None,
            ) as process:
                os.close(slave)
                reader = threading.Thread(target=read_terminal, daemon=True)
                if terminal:
                    reader.start()
                try:
                    stdout, stderr = process.communicate(
                        input=None if stdin_terminal else input, timeout=10,
                    )
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.communicate()
                    self.fail("CLI did not finish within 10 seconds")
                if terminal:
                    reader.join(timeout=5)
                    self.assertFalse(reader.is_alive(), "terminal output did not close")
                    stdout = b"".join(chunks).decode().replace("\r\n", "\n")
                    # A real emulator consumes these control sequences instead of displaying them.
                    stdout = re.sub(r"\x1b_G[^\x1b]*\x1b\\", "", stdout)
                result = subprocess.CompletedProcess(command, process.returncode, stdout, stderr)
        if self.log.exists():
            self.calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        else:
            self.calls = []
        return result

    def calls_for(self, program):
        return [call for call in self.calls if call["program"] == program]

    def test_help_needs_no_external_programs(self):
        empty = self.root / "empty"
        empty.mkdir()
        self.env["PATH"] = str(empty)
        for option in ("-h", "--help"):
            with self.subTest(option=option):
                result = self.run_cli(option)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("--check-health", result.stdout)
                self.assertIn("--paging", result.stdout)
                self.assertIn("--verbose", result.stdout)
                self.assertEqual(self.calls, [])

    def test_invalid_options(self):
        for args in (("--unknown",), ("-x",), ("--paging",), ("--paging=bad",), ("--paging=",)):
            with self.subTest(args=args):
                result = self.run_cli(*args)
                self.assertEqual(result.returncode, 2)
                self.assertIn("--help", result.stderr)
                self.assertEqual(self.calls, [])

    def test_options_can_follow_paths(self):
        self.file("notes.md")
        result = self.run_cli("notes.md", "--verbose", "--paging", "never")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("mdcat not found", result.stderr)
        self.assertIn("--paging=never", self.calls_for("batcat")[0]["args"])

    def test_separator_allows_option_shaped_paths(self):
        self.file("--help", "literal help file\n")
        result = self.run_cli("--", "--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "literal help file\n")
        self.assertEqual(self.calls_for("batcat")[0]["args"][-2:], ["--", "./--help"])

    def test_explicit_and_implicit_stdin(self):
        for args in ((), ("-",)):
            with self.subTest(args=args):
                result = self.run_cli(*args, input="piped input\n")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "piped input\n")
                self.assertEqual(len(self.calls_for("batcat")), 1)
                self.assertEqual(self.calls_for("eza"), [])

    def test_literal_dash_file(self):
        self.file("-", "dash file\n")
        result = self.run_cli("./-", input="not the file\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "dash file\n")

    def test_no_paths_with_terminal_stdin_shows_directory(self):
        result = self.run_cli(terminal=True, stdin_terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("eza")[0]["args"][-2:], ["--", "."])

    def test_health_reports_required_and_optional_programs_without_running_them(self):
        result = self.run_cli("--check-health")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("OK       eza", result.stdout)
        self.assertIn("OPTIONAL mdcat", result.stdout)
        self.assertIn("OPTIONAL figlet", result.stdout)
        self.assertNotIn("exa", result.stdout)
        self.assertEqual(self.calls, [])

    def test_health_fails_for_missing_feature_viewer(self):
        (self.bin / "eza").unlink()
        result = self.run_cli("--check-health")
        self.assertEqual(result.returncode, 1)
        self.assertIn("MISSING  eza", result.stdout)
        self.assertIn("OK       batcat", result.stdout)

    def test_health_finds_mdcat_in_configured_home_location(self):
        renderer = self.home / "bin/mdcat/mdcat"
        self.mock(renderer)
        result = self.run_cli("--check-health")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(renderer), result.stdout)
        self.assertEqual(self.calls, [])

    def test_health_rejects_file_operands(self):
        result = self.run_cli("--check-health", "missing.md")
        self.assertEqual(result.returncode, 2)
        self.assertIn("does not accept file operands", result.stderr)

    def test_markdown_extensions_and_unusual_names(self):
        self.mock(self.bin / "mdcat")
        names = (
            "README.md", "README.MD", "notes.markdown", "notes.MARKDOWN",
            "Mixed.Md", "notes with spaces.md", "notes\\name.md", "Überblick.md",
        )
        for name in names:
            self.file(name)
        result = self.run_cli(*names)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual([call["args"][-1] for call in self.calls_for("mdcat")], list(names))
        self.assertEqual(self.calls_for("batcat"), [])

    def test_missing_mdcat_is_quiet(self):
        self.file("notes.md")
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("--language=markdown", self.calls_for("batcat")[0]["args"])

    def test_verbose_flags_explain_missing_mdcat(self):
        self.file("notes.md")
        for option in ("-v", "--verbose"):
            with self.subTest(option=option):
                result = self.run_cli(option, "notes.md")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("mdcat not found; showing Markdown source", result.stderr)

    def test_home_renderer_and_path_priority(self):
        self.file("notes.md")
        self.mock(self.home / "bin/mdcat/mdcat")
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls_for("mdcat")), 1)
        (self.home / "bin/mdcat/mdcat").write_text("#!/bin/bash\nexit 99\n")
        self.mock(self.bin / "mdcat")
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_nonexecutable_home_renderer_falls_back_quietly(self):
        self.file("notes.md")
        renderer = self.home / "bin/mdcat/mdcat"
        self.mock(renderer)
        renderer.chmod(0o644)
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(len(self.calls_for("batcat")), 1)

    def test_terminal_markdown_uses_auto_quitting_pager(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        result = self.run_cli("notes.md", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        call = self.calls_for("mdcat")[0]
        self.assertIn("--paginate", call["args"])
        self.assertNotIn("--no-colour", call["args"])
        self.assertEqual(call["pager"], "less -FRX")

    def test_redirected_markdown_has_no_pager_or_formatting(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        call = self.calls_for("mdcat")[0]
        self.assertIn("--no-pager", call["args"])
        self.assertIn("--no-colour", call["args"])
        self.assertEqual(result.stdout, "# Heading\n\n**Text**\n")
        self.assertEqual(self.calls_for("tput"), [])

    def test_paging_always_can_be_forced(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        result = self.run_cli("--paging=always", "notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        call = self.calls_for("mdcat")[0]
        self.assertIn("--paginate", call["args"])
        self.assertEqual(call["pager"], "less -RX")

    def test_no_pager_options_and_last_option_wins(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        for option in ("--paging=never", "-P", "--no-pager"):
            with self.subTest(option=option):
                result = self.run_cli("--paging=always", option, "notes.md", terminal=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("--no-pager", self.calls_for("mdcat")[0]["args"])

    def test_custom_pager_settings_are_preserved(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        self.env["PAGER"] = 'custom-pager --flag "quoted argument"'
        result = self.run_cli("notes.md", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("mdcat")[0]["pager"], self.env["PAGER"])
        self.env["MDCAT_PAGER"] = "other-pager -R"
        result = self.run_cli("notes.md", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("mdcat")[0]["pager"], "other-pager -R")

    def test_empty_pager_configuration_disables_markdown_paging(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        for variable in ("PAGER", "MDCAT_PAGER"):
            with self.subTest(variable=variable):
                self.env.pop("PAGER", None)
                self.env.pop("MDCAT_PAGER", None)
                self.env[variable] = ""
                result = self.run_cli("notes.md", terminal=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("--no-pager", self.calls_for("mdcat")[0]["args"])

    def test_missing_default_pager_only_reports_in_verbose_mode(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        (self.bin / "less").unlink()
        result = self.run_cli("notes.md", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("--no-pager", self.calls_for("mdcat")[0]["args"])
        result = self.run_cli("-v", "notes.md", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("less not found", result.stderr)

    def test_directory_dispatch_and_terminal_aware_eza_flags(self):
        (self.root / "directory.md").mkdir()
        self.mock(self.bin / "mdcat")
        for terminal, mode in ((False, "never"), (True, "always")):
            with self.subTest(terminal=terminal):
                result = self.run_cli("directory.md", terminal=terminal)
                self.assertEqual(result.returncode, 0, result.stderr)
                args = self.calls_for("eza")[0]["args"]
                self.assertIn("--color=" + mode, args)
                self.assertIn("--icons=" + mode, args)
                self.assertEqual(self.calls_for("mdcat"), [])
                if not terminal:
                    self.assertNotIn("\033", result.stdout)

    def test_text_paging_options_reach_batcat(self):
        self.file("code.py", "print('hello')\n")
        result = self.run_cli("--paging", "always", "code.py")
        self.assertEqual(result.returncode, 0, result.stderr)
        args = self.calls_for("batcat")[0]["args"]
        self.assertIn("--paging=always", args)
        self.assertIn("--color=never", args)
        self.assertEqual(args[-2:], ["--", "code.py"])

    def test_redirected_tables_and_graphs_have_no_color_escapes(self):
        for name, program in (("data.csv", "tv"), ("graph.GRAPHML", "graphml2unicode")):
            with self.subTest(name=name):
                self.file(name)
                result = self.run_cli(name)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "RENDERED " + program + "\n")
                self.assertEqual(self.calls_for(program)[0]["args"], ["--", name])

    def test_image_and_pdf_dispatch(self):
        self.file("image.PNG")
        self.file("document.pdf")
        result = self.run_cli("image.PNG", "document.pdf")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("viu")[0]["args"], ["--name", "--", "image.PNG"])
        self.assertEqual(self.calls_for("tdf")[0]["args"], ["document.pdf"])
        self.assertEqual(self.calls_for("pdftotext"), [])
        (self.bin / "tdf").unlink()
        result = self.run_cli("document.pdf")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("pdftotext")[0]["args"], ["-layout", "-nopgbrk", "document.pdf", "-"])
        self.assertEqual(result.stdout, "Extracted PDF text\n")
        self.assertIn("--language=txt", self.calls_for("batcat")[0]["args"])

    def test_leading_dashes_are_safe_for_all_handlers(self):
        self.mock(self.bin / "mdcat")
        names = ("-notes.md", "-code.py", "-data.csv", "-image.png", "-document.pdf", "-graph.graphml")
        for name in names:
            self.file(name)
        (self.root / "-directory").mkdir()
        result = self.run_cli("--", *names, "-directory")
        self.assertEqual(result.returncode, 0, result.stderr)
        for program, name in zip(
            ("mdcat", "batcat", "tv", "viu", "tdf", "graphml2unicode", "eza"),
            (*names, "-directory"),
        ):
            with self.subTest(program=program):
                self.assertEqual(self.calls_for(program)[0]["args"][-1], "./" + name)

    def test_missing_viewers_have_actionable_errors(self):
        for program, name in (
            ("batcat", "code.py"), ("eza", "directory"), ("tv", "data.csv"),
            ("vd", "database.db"), ("graphml2unicode", "graph.graphml"),
        ):
            with self.subTest(program=program):
                if name == "directory":
                    (self.root / name).mkdir()
                else:
                    self.file(name)
                (self.bin / program).unlink()
                result = self.run_cli(name)
                self.assertEqual(result.returncode, 127)
                self.assertIn("required program '" + program + "' not found", result.stderr)
                self.mock(self.bin / program)

    def test_pdf_text_fallback_is_quiet_paged_and_verbose_on_request(self):
        self.file("-document.PDF")
        (self.bin / "tdf").unlink()
        result = self.run_cli("--paging=never", "--", "-document.PDF")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(result.stdout, "Extracted PDF text\n")
        self.assertEqual(self.calls_for("pdftotext")[0]["args"], ["-layout", "-nopgbrk", "./-document.PDF", "-"])
        self.assertIn("--paging=never", self.calls_for("batcat")[0]["args"])
        result = self.run_cli("-v", "--", "-document.PDF")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("tdf not found", result.stderr)

    def test_pdf_does_not_fall_back_when_installed_tdf_fails(self):
        self.file("document.pdf")
        self.env["TEST_EXIT_TDF"] = "19"
        result = self.run_cli("document.pdf")
        self.assertEqual(result.returncode, 19)
        self.assertEqual(self.calls_for("pdftotext"), [])

    def test_health_accepts_either_pdf_backend_and_reports_when_both_are_missing(self):
        for program in ("tdf", "pdftotext"):
            with self.subTest(program=program):
                (self.bin / program).unlink()
                result = self.run_cli("--check-health")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn("MISSING", result.stdout)
                self.assertNotIn("zathura", result.stdout)
                self.assertNotIn("modern-latexmk", result.stdout)
                self.mock(self.bin / program)
        (self.bin / "tdf").unlink()
        (self.bin / "pdftotext").unlink()
        result = self.run_cli("--check-health")
        self.assertEqual(result.returncode, 1)
        self.assertIn("MISSING  pdftotext", result.stdout)
        self.file("document.pdf")
        result = self.run_cli("document.pdf")
        self.assertEqual(result.returncode, 127)
        self.assertIn("required program 'pdftotext'", result.stderr)

    def test_linux_image_fallback_is_quiet_and_uses_safe_path(self):
        self.file("-image with spaces.png")
        (self.bin / "viu").unlink()
        result = self.run_cli("--", "-image with spaces.png", wsl=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls_for("xdg-open")[0]["args"], ["./-image with spaces.png"])
        self.assertEqual(self.calls_for("explorer.exe"), [])
        result = self.run_cli("-v", "--", "-image with spaces.png", wsl=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("viu not found", result.stderr)
        self.assertIn("xdg-open", result.stderr)

    def test_wsl_image_fallback_converts_path_before_opening(self):
        self.file("image with spaces.png")
        (self.bin / "viu").unlink()
        self.env["WSL_DISTRO_NAME"] = "Ubuntu"
        self.env["TEST_WINDOWS_PATH"] = "\\\\wsl.localhost\\Ubuntu\\home\\user\\image with spaces.png"
        result = self.run_cli("image with spaces.png")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls_for("wslpath")[0]["args"], ["-a", "-w", "image with spaces.png"])
        self.assertEqual(self.calls_for("explorer.exe")[0]["args"], [self.env["TEST_WINDOWS_PATH"]])
        self.assertEqual(self.calls_for("xdg-open"), [])

    def test_wsl_path_conversion_failure_does_not_open_a_wrong_path(self):
        self.file("image.png")
        (self.bin / "viu").unlink()
        self.env["TEST_EXIT_WSLPATH"] = "7"
        result = self.run_cli("image.png", wsl=True)
        self.assertEqual(result.returncode, 7)
        self.assertEqual(self.calls_for("explorer.exe"), [])

    def test_image_fallbacks_have_actionable_missing_program_errors(self):
        self.file("image.png")
        (self.bin / "viu").unlink()
        for program, wsl in (("xdg-open", False), ("explorer.exe", True), ("wslpath", True)):
            with self.subTest(program=program):
                (self.bin / program).unlink()
                result = self.run_cli("image.png", wsl=wsl)
                self.assertEqual(result.returncode, 127)
                self.assertIn("required program '" + program + "'", result.stderr)
                self.mock(self.bin / program)

    def test_images_prefer_viu_and_do_not_fall_back_on_its_errors(self):
        self.file("image.png")
        self.env["TEST_EXIT_VIU"] = "23"
        result = self.run_cli("image.png", wsl=True)
        self.assertEqual(result.returncode, 23)
        self.assertEqual(self.calls_for("explorer.exe"), [])
        self.assertEqual(self.calls_for("xdg-open"), [])

    def test_health_understands_platform_specific_image_fallbacks(self):
        (self.bin / "viu").unlink()
        for wsl, opener in ((False, "xdg-open"), (True, "explorer.exe")):
            with self.subTest(wsl=wsl):
                result = self.run_cli("--check-health", wsl=wsl)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("OK       " + opener, result.stdout)
                (self.bin / opener).unlink()
                result = self.run_cli("--check-health", wsl=wsl)
                self.assertEqual(result.returncode, 1)
                self.assertIn("MISSING  " + opener, result.stdout)
                self.mock(self.bin / opener)
        (self.bin / "wslpath").unlink()
        result = self.run_cli("--check-health", wsl=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn("MISSING  wslpath", result.stdout)

    def test_sqlite_extension_variants_force_the_sqlite_loader(self):
        names = ("data.db", "data.DB3", "data.sqlite", "data.SQLITE3", "data.s3db", "data.sl3", "-data.db")
        for name in names:
            self.file(name)
        result = self.run_cli("--", *names)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls_for("vd")
        self.assertEqual(len(calls), len(names))
        for name, call in zip(names, calls):
            self.assertEqual(call["args"], ["--filetype=sqlite", "--", "./" + name if name.startswith("-") else name])
        self.assertEqual(self.calls_for("batcat"), [])

    def test_tabular_formats_use_explicit_canonical_loaders(self):
        types = {
            "TSV": "tsv", "tab": "tsv", "psv": "psv", "XLS": "xls", "xlsx": "xlsx",
            "xlsb": "xlsb", "ods": "ods", "PARQUET": "parquet", "arrow": "arrow",
            "arrows": "arrows", "jsonl": "jsonl", "NDJSON": "jsonl",
        }
        for extension in types:
            self.file("data." + extension)
        result = self.run_cli(*("data." + extension for extension in types))
        self.assertEqual(result.returncode, 0, result.stderr)
        for extension, call in zip(types, self.calls_for("vd")):
            self.assertIn("--filetype=" + types[extension], call["args"])
            if types[extension] == "tsv":
                self.assertIn("--delimiter=\t", call["args"])
                self.assertIn("--header=1", call["args"])
            self.assertEqual(call["args"][-2:], ["--", "data." + extension])

    def test_csv_only_directories_open_every_file_as_a_table(self):
        directory = self.root / "CSV tables"
        directory.mkdir()
        names = ("a.csv", "b.CSV", ".hidden.csv", "-odd name.csv", "data [1]*.csv", "Überblick.csv")
        for name in names:
            self.file("CSV tables/" + name, 'name,notes\n"Ada, Lovelace","has, comma"\n')
        result = self.run_cli("CSV tables")
        self.assertEqual(result.returncode, 0, result.stderr)
        args = self.calls_for("vd")[0]["args"]
        self.assertEqual(args[:4], ["--filetype=csv", "--csv-delimiter=,", "--header=1", "--"])
        self.assertEqual(sorted(args[4:]), sorted("CSV tables/" + name for name in names))
        self.assertEqual(self.calls_for("eza"), [])
        self.assertEqual(self.calls_for("tv"), [])

    def test_empty_mixed_hidden_and_nested_directories_keep_tree_view(self):
        for kind in ("empty", "mixed", "hidden", "nested", "broken"):
            with self.subTest(kind=kind):
                directory = self.root / kind
                directory.mkdir()
                if kind != "empty":
                    self.file(kind + "/data.csv")
                if kind == "mixed":
                    self.file(kind + "/README.md")
                elif kind == "hidden":
                    self.file(kind + "/.metadata")
                elif kind == "nested":
                    (directory / "child.csv").mkdir()
                elif kind == "broken":
                    (directory / "broken.csv").symlink_to(directory / "missing")
                result = self.run_cli(kind)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(len(self.calls_for("eza")), 1)
                self.assertEqual(self.calls_for("vd"), [])

    def test_csv_directories_do_not_require_eza(self):
        (self.root / "tables").mkdir()
        self.file("tables/data.csv")
        (self.bin / "eza").unlink()
        result = self.run_cli("tables")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls_for("vd")), 1)

    def test_missing_vd_falls_back_to_tree_for_csv_directories(self):
        (self.root / "tables").mkdir()
        self.file("tables/data.csv")
        (self.bin / "vd").unlink()
        result = self.run_cli("tables")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(len(self.calls_for("eza")), 1)
        result = self.run_cli("-v", "tables")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("vd not found", result.stderr)
        result = self.run_cli("--check-health")
        self.assertEqual(result.returncode, 1)
        self.assertIn("MISSING  vd", result.stdout)

    def test_current_csv_directory_uses_vd_without_operands(self):
        directory = self.root / "tables"
        directory.mkdir()
        self.file("tables/data.csv")
        result = self.run_cli(terminal=True, stdin_terminal=True, cwd=directory)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("vd")[0]["args"][-2:], ["--", "./data.csv"])

    def test_csv_directory_does_not_fall_back_when_installed_vd_fails(self):
        (self.root / "tables").mkdir()
        self.file("tables/data.csv")
        self.env["TEST_EXIT_VD"] = "23"
        result = self.run_cli("tables")
        self.assertEqual(result.returncode, 23)
        self.assertEqual(self.calls_for("eza"), [])

    @unittest.skipIf(os.geteuid() == 0, "root bypasses ordinary file permissions")
    def test_csv_directory_validates_its_files_before_opening_vd(self):
        (self.root / "tables").mkdir()
        self.file("tables/private.csv").chmod(0)
        result = self.run_cli("tables")
        self.assertEqual(result.returncode, 1)
        self.assertIn("file is not readable", result.stderr)
        self.assertEqual(self.calls_for("vd"), [])

    def test_html_without_browser_quietly_shows_source(self):
        self.file("page.html", "<h1>Hello</h1>\n")
        self.env["TERM"] = "xterm-kitty"
        result = self.run_cli("page.html", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(len(self.calls_for("batcat")), 1)
        result = self.run_cli("-v", "page.html")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("showing HTML source", result.stderr)

    def test_html_in_kitty_compatible_terminals_uses_browser(self):
        self.file("page with spaces.HTM")
        self.mock(self.bin / "terminal-browser")
        for term in ("xterm-kitty", "xterm-ghostty", "wezterm"):
            with self.subTest(term=term):
                self.env["TERM"] = term
                result = self.run_cli("page with spaces.HTM", kitty_support=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.calls_for("terminal-browser")[0]["args"], ["open", str(self.root / "page with spaces.HTM")])
                self.assertEqual(self.calls_for("batcat"), [])

    def test_html_queries_graphics_support_instead_of_assuming_it_from_term(self):
        self.file("page.html")
        self.mock(self.bin / "terminal-browser")
        result = self.run_cli("page.html", kitty_support=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls_for("terminal-browser")), 1)
        self.env["TERM"] = "xterm-kitty"
        result = self.run_cli("page.html", kitty_support=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls_for("terminal-browser"), [])
        self.assertEqual(len(self.calls_for("batcat")), 1)

    def test_html_without_stty_keeps_code_view(self):
        self.file("page.html")
        self.mock(self.bin / "terminal-browser")
        (self.bin / "stty").unlink(missing_ok=True)
        result = self.run_cli("page.html", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("terminal-browser"), [])
        self.assertEqual(len(self.calls_for("batcat")), 1)

    def test_html_probe_restores_terminal_settings_on_success_rejection_and_timeout(self):
        self.file("page.html")
        self.mock(self.bin / "terminal-browser")
        for support in (True, False, "timeout"):
            with self.subTest(support=support):
                result = self.run_cli("page.html", kitty_support=support)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stderr, "")
                viewer = "terminal-browser" if support is True else "batcat"
                flags = self.calls_for(viewer)[0]["tty_flags"]
                self.assertTrue(flags & termios.ECHO)
                self.assertTrue(flags & termios.ICANON)

    def test_html_does_not_assume_multiplexer_graphics_support(self):
        self.file("page.html")
        self.mock(self.bin / "terminal-browser")
        self.env.update(TERM="xterm-kitty", TMUX="test-multiplexer")
        result = self.run_cli("page.html", kitty_support=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls_for("terminal-browser"), [])
        self.assertEqual(len(self.calls_for("batcat")), 1)
        result = self.run_cli("page.html", kitty_support=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls_for("terminal-browser")), 1)

    def test_redirected_html_never_probes_or_opens_a_browser(self):
        self.file("page.html", "<h1>Hello</h1>\n")
        self.mock(self.bin / "terminal-browser")
        self.env["TERM"] = "xterm-kitty"
        result = self.run_cli("page.html")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "<h1>Hello</h1>\n")
        self.assertEqual(self.calls_for("terminal-browser"), [])

    def test_unknown_terminal_html_keeps_code_view(self):
        self.file("page.html")
        self.mock(self.bin / "terminal-browser")
        result = self.run_cli("page.html", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls_for("terminal-browser"), [])
        self.assertEqual(len(self.calls_for("batcat")), 1)

    @unittest.skipUnless(REAL_VD, "VisiData is not installed")
    def test_real_visidata_loads_csv_directory_as_columns_not_lines(self):
        self.env["TEST_REAL_VD"] = REAL_VD
        (self.root / "tables").mkdir()
        self.file("tables/data.CSV", 'name,notes\n"Ada, Lovelace","has, comma"\n')
        result = self.run_cli("tables")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.splitlines(), ["name\tnotes", "Ada, Lovelace\thas, comma"])

    @unittest.skipUnless(REAL_VD, "VisiData is not installed")
    def test_real_visidata_opens_sqlite_table_index(self):
        self.env["TEST_REAL_VD"] = REAL_VD
        with sqlite3.connect(self.root / "data.DB3") as connection:
            connection.execute("CREATE TABLE people (name TEXT, age INTEGER)")
            connection.execute("INSERT INTO people VALUES ('Ada', 36)")
        result = self.run_cli("data.DB3")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("people", result.stdout)
        self.assertTrue(result.stdout.startswith("name\trows\tcols\tkeys\tsource\n"), result.stdout)
        self.assertNotIn("SQLite format", result.stdout)

    @unittest.skipUnless(REAL_PDFTOTEXT, "pdftotext is not installed")
    def test_real_pdftotext_fallback_renders_text(self):
        (self.bin / "tdf").unlink()
        (self.bin / "pdftotext").unlink()
        (self.bin / "pdftotext").symlink_to(REAL_PDFTOTEXT)
        stream = b"BT /F1 12 Tf 72 720 Td (PDF fallback works) Tj ET\n"
        objects = [
            b"<< /Type /Catalog /Pages 2 0 R >>",
            b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
            b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"endstream",
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        ]
        pdf = b"%PDF-1.4\n"
        offsets = []
        for number, obj in enumerate(objects, 1):
            offsets.append(len(pdf))
            pdf += f"{number} 0 obj\n".encode() + obj + b"\nendobj\n"
        startxref = len(pdf)
        pdf += f"xref\n0 {len(objects) + 1}\n0000000000 65535 f \n".encode()
        for offset in offsets:
            pdf += f"{offset:010d} 00000 n \n".encode()
        pdf += f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{startxref}\n%%EOF\n".encode()
        (self.root / "-document.PDF").write_bytes(pdf)
        result = self.run_cli("--", "-document.PDF")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("PDF fallback works", result.stdout)

    def test_missing_and_broken_paths(self):
        (self.root / "broken").symlink_to(self.root / "missing")
        for name in ("missing", "broken", ""):
            with self.subTest(name=name):
                result = self.run_cli(name)
                self.assertEqual(result.returncode, 1)
                self.assertIn("path does not exist", result.stderr)
                self.assertEqual(self.calls, [])

    def test_nonregular_input_is_rejected(self):
        os.mkfifo(self.root / "pipe")
        result = self.run_cli("pipe")
        self.assertEqual(result.returncode, 1)
        self.assertIn("not a regular file or directory", result.stderr)
        self.assertEqual(self.calls, [])

    @unittest.skipIf(os.geteuid() == 0, "root bypasses ordinary file permissions")
    def test_unreadable_file_and_unsearchable_directory(self):
        path = self.file("private.txt")
        path.chmod(0)
        result = self.run_cli("private.txt")
        self.assertEqual(result.returncode, 1)
        self.assertIn("file is not readable", result.stderr)
        directory = self.root / "private-dir"
        directory.mkdir(mode=0o400)
        self.addCleanup(directory.chmod, 0o700)
        result = self.run_cli("private-dir")
        self.assertEqual(result.returncode, 1)
        self.assertIn("directory is not readable/searchable", result.stderr)

    def test_all_paths_are_validated_before_opening_viewers(self):
        self.file("good.txt")
        result = self.run_cli("good.txt", "missing.txt")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertEqual(self.calls, [])

    def test_headers_preserve_literal_backslashes(self):
        name = "literal\\nname.txt"
        self.file(name)
        result = self.run_cli(name, terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("┃ " + name + " ┃", result.stdout)
        self.assertNotIn("literal\nname.txt", result.stdout)

    def test_missing_or_dumb_term_avoids_headers_colors_and_markdown_pager(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        for term in (None, "", "dumb"):
            with self.subTest(term=term):
                if term is None:
                    self.env.pop("TERM", None)
                else:
                    self.env["TERM"] = term
                result = self.run_cli("notes.md", terminal=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stderr, "")
                self.assertNotIn("┏", result.stdout)
                self.assertIn("--no-pager", self.calls_for("mdcat")[0]["args"])
                self.assertIn("--no-colour", self.calls_for("mdcat")[0]["args"])
                self.assertEqual(self.calls_for("tput"), [])

    def test_no_color_disables_colors_but_keeps_terminal_headers(self):
        self.file("notes.md")
        self.mock(self.bin / "mdcat")
        self.env["NO_COLOR"] = "1"
        result = self.run_cli("notes.md", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("┏", result.stdout)
        self.assertNotIn("\033", result.stdout)
        self.assertIn("--no-colour", self.calls_for("mdcat")[0]["args"])
        self.assertEqual(self.calls_for("tput"), [])

    def test_failed_tput_is_silent_and_does_not_leak_colors(self):
        self.file("code.py")
        self.env["TEST_EXIT_TPUT"] = "1"
        result = self.run_cli("code.py", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        self.assertIn("┏", result.stdout)
        self.assertNotIn("\033", result.stdout)

    def test_figlet_gets_header_as_stdin_not_options(self):
        self.file("-n")
        self.mock(self.bin / "figlet")
        result = self.run_cli("--", "-n", terminal=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("FIGLET: -n", result.stdout)
        self.assertEqual(self.calls_for("figlet")[0]["args"], [])

    def test_sourcing_does_not_run_main(self):
        result = subprocess.run(
            ["/bin/bash", "-c", 'source "$1"; printf "sourced\\n"', "test", str(SCRIPT)],
            cwd=self.root, env=self.env, text=True, capture_output=True, timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "sourced\n")
        self.assertFalse(self.log.exists())

    def test_viewer_failure_behavior_is_unchanged(self):
        self.file("notes.md")
        self.file("good.txt")
        self.mock(self.bin / "mdcat")
        self.env["TEST_EXIT_MDCAT"] = "23"
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 23)
        self.assertEqual(self.calls_for("batcat"), [])
        result = self.run_cli("notes.md", "good.txt")
        self.assertEqual(result.returncode, 0)
        self.file("data.csv")
        self.env["TEST_EXIT_TV"] = "17"
        result = self.run_cli("data.csv")
        self.assertEqual(result.returncode, 0)

    @unittest.skipUnless(REAL_MDCAT, "mdcat is not installed")
    def test_real_mdcat_uses_pager_for_short_and_long_documents(self):
        (self.bin / "mdcat").symlink_to(REAL_MDCAT)
        for paragraphs in (1, 200):
            with self.subTest(paragraphs=paragraphs):
                self.file("notes.md", "# Heading\n\n" + "A paragraph.\n\n" * paragraphs)
                result = self.run_cli("notes.md", terminal=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(self.calls_for("less")[0]["args"], ["-FRX"])
                self.assertEqual(result.stdout.count("A paragraph."), paragraphs)

    @unittest.skipUnless(REAL_MDCAT, "mdcat is not installed")
    def test_real_mdcat_redirected_output_is_plain_and_unpaged(self):
        (self.bin / "mdcat").symlink_to(REAL_MDCAT)
        self.file("notes.md")
        result = self.run_cli("notes.md")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("\033", result.stdout)
        self.assertNotIn("**", result.stdout)
        self.assertIn("Text", result.stdout)
        self.assertEqual(self.calls_for("less"), [])

    @unittest.skipUnless(REAL_MDCAT and REAL_LESS, "mdcat and less are not installed")
    def test_real_pager_exits_for_short_documents_and_waits_for_long_documents(self):
        (self.bin / "mdcat").symlink_to(REAL_MDCAT)
        (self.bin / "less").unlink()
        (self.bin / "less").symlink_to(REAL_LESS)
        self.env.update(LESS="-PTEST_PAGER_READY", LESSHISTFILE="-", LINES="24", COLUMNS="80")

        def claim_terminal():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        for paragraphs in (1, 200):
            with self.subTest(paragraphs=paragraphs):
                self.file("notes.md", "# Heading\n\n" + "A paragraph.\n\n" * paragraphs)
                master, slave = os.openpty()
                fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
                output = b""
                saw_prompt = False
                with subprocess.Popen(
                    ["/bin/bash", str(SCRIPT), "notes.md"], cwd=self.root, env=self.env,
                    stdin=slave, stdout=slave, stderr=slave, preexec_fn=claim_terminal,
                ) as process:
                    os.close(slave)
                    try:
                        deadline = time.monotonic() + 10
                        while True:
                            remaining = deadline - time.monotonic()
                            self.assertGreater(remaining, 0, "pager did not finish")
                            ready, _, _ = select.select([master], [], [], remaining)
                            self.assertTrue(ready, "pager did not produce output or finish")
                            try:
                                chunk = os.read(master, 4096)
                            except OSError as error:
                                if error.errno == errno.EIO:
                                    break
                                raise
                            if not chunk:
                                break
                            output += chunk
                            if b"TEST_PAGER_READY" in output and not saw_prompt:
                                saw_prompt = True
                                self.assertIsNone(process.poll(), "pager should wait for input")
                                os.write(master, b"q")
                        self.assertEqual(process.wait(timeout=5), 0, output.decode())
                    finally:
                        if process.poll() is None:
                            process.kill()
                            process.wait()
                        os.close(master)
                self.assertIn(b"A paragraph.", output)
                self.assertEqual(saw_prompt, paragraphs > 1)


if __name__ == "__main__":
    unittest.main()
