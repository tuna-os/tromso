#!/usr/bin/env python3
"""BuildStream live build dashboard.

Tails a BST build log and serves a live HTML dashboard.

Usage:
    python3 bst-dashboard.py [OPTIONS]

Options:
    --log FILE        Build log to tail (default: $BST_LOG or /var/tmp/bst-build.log)
    --port PORT       HTTP port (default: $BST_DASHBOARD_PORT or 8765)
    --target TARGET   BST element to build via the Start button (default: $BST_TARGET or oci/aurora.bst)
    --project DIR     Project source directory mounted into container (default: $BST_PROJECT or script dir)
    --bst-image IMAGE BST2 container image (default: $BST2_IMAGE or auto-detect from running container)
    --help            Show this message
"""

import re
import os
import sys
import time
import json
import argparse
import datetime
import threading
import subprocess
import multiprocessing
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handle requests in a separate thread."""
    daemon_threads = True

_DEFAULT_BST2_IMAGE = (
    "registry.gitlab.com/freedesktop-sdk/infrastructure/"
    "freedesktop-sdk-docker-images/bst2:f89b4aef847ef040b345acceda15a850219eb8f1"
)

def _parse_args():
    p = argparse.ArgumentParser(add_help=False)
    p.add_argument("--log",       default=None)
    p.add_argument("--port",      type=int, default=None)
    p.add_argument("--target",    default=None)
    p.add_argument("--project",   default=None)
    p.add_argument("--bst-image", default=None, dest="bst_image")
    p.add_argument("--help", "-h", action="store_true")
    args, _ = p.parse_known_args()
    if args.help:
        print(__doc__)
        sys.exit(0)
    return args

_args = _parse_args()

LOG_FILE    = _args.log       or os.environ.get("BST_LOG",              "/var/tmp/bst-build.log")
PORT        = _args.port      or int(os.environ.get("BST_DASHBOARD_PORT", "8765"))
BST_TARGET  = _args.target    or os.environ.get("BST_TARGET",           "oci/aurora.bst")
PROJECT_DIR = _args.project   or os.environ.get("BST_PROJECT",          os.path.dirname(os.path.abspath(__file__)))
BST2_IMAGE  = _args.bst_image or os.environ.get("BST2_IMAGE",           _DEFAULT_BST2_IMAGE)

# ── Build process control ──────────────────────────────────────────────────────
BUILD_LOCK = threading.Lock()
BUILD_PROC: "subprocess.Popen | None" = None

_sysinfo_lock = threading.Lock()
_sysinfo = {"cpu_pct": 0.0, "cpu_cores": [], "mem_used": 0, "mem_total": 0,
            "bst_cpu_pct": None, "bst_mem": None, "cpu_temp": None,
            "bst_running": False}
_cpu_prev: list[tuple[int, int]] = []   # list of (idle_ticks, total_ticks)

def _bst_container_id() -> str:
    """Return container ID of any running BST2 container, or empty string."""
    try:
        result = subprocess.run(
            ["podman", "ps", "-q", "--filter", f"ancestor={BST2_IMAGE}"],
            capture_output=True, text=True, timeout=3,
        )
        return result.stdout.strip()
    except Exception:
        return ""


def build_running() -> bool:
    if BUILD_PROC is not None and BUILD_PROC.poll() is None:
        return True
    with _sysinfo_lock:
        return _sysinfo.get("bst_running", False)


def start_build() -> bool:
    global BUILD_PROC
    with BUILD_LOCK:
        if build_running():
            return False
        nproc = multiprocessing.cpu_count()
        cache_dir = os.path.join(os.path.expanduser("~"), ".cache", "buildstream")
        os.makedirs(cache_dir, exist_ok=True)
        with open(LOG_FILE, "w") as f:
            f.write(f"=== Build started at {datetime.datetime.now().strftime('%c')} ===\n")
        log_f = open(LOG_FILE, "a")
        cmd = [
            "podman", "run", "--rm",
            "--privileged", "--device", "/dev/fuse", "--network=host",
            "-v", f"{PROJECT_DIR}:/src:rw",
            "-v", f"{cache_dir}:/root/.cache/buildstream:rw",
            "-w", "/src",
            BST2_IMAGE,
            "bash", "-c", 'bst --colors "$@"', "--",
            "--max-jobs", str(max(1, nproc // 2)),
            "--fetchers", str(nproc),
            "build", BST_TARGET,
        ]
        BUILD_PROC = subprocess.Popen(cmd, stdout=log_f, stderr=log_f)
        return True


def stop_build() -> bool:
    global BUILD_PROC
    with BUILD_LOCK:
        killed = False
        if BUILD_PROC is not None and BUILD_PROC.poll() is None:
            BUILD_PROC.terminate()
            killed = True
        cid = _bst_container_id()
        if cid:
            try:
                subprocess.run(["podman", "stop", cid], timeout=10)
                killed = True
            except Exception:
                pass
        return killed

# Strip ANSI escape codes
ANSI = re.compile(r"\x1b\[[0-9;]*[mGKHF]|\x1b\[[0-9;]*m")

# "=== Build started at Tue Apr 22 03:00:00 IST 2026 ==="
BUILD_HEADER_RE = re.compile(r"=== Build started at (.+?) ===")

# Match a structured BST log line
LINE_RE = re.compile(
    r"^\[(?P<time>[0-9\-:]+)\]\[(?P<hash>[0-9a-f ]+)\]\[(?P<ctx>[^\]]+)\]\s+"
    r"(?P<status>START\s+|SUCCESS|FAILURE|SKIPPED|STATUS\s+|INFO\s+|WARN\s+|PULL\s+)\s*"
    r"(?P<msg>.*)$"
)

# Identify a top-level build event (the line that has the log file path)
BUILD_LOG_RE = re.compile(r"[a-z0-9_\-]+(?:/[a-zA-Z0-9_.\-]+)+\.log$")

# Pipeline Summary lines
PIPELINE_SUMMARY_RE = re.compile(r"^Pipeline Summary\s*$")
SUMMARY_TOTAL_RE    = re.compile(r"^\s+Total:\s+(\d+)")
SUMMARY_QUEUE_RE    = re.compile(r"^\s+(Pull|Build) Queue:\s+processed (\d+), skipped (\d+), failed (\d+)")

# Failure Summary element lines: "    kde-build-meta.bst:kde/plasma/foo.bst:"
FAILURE_ELEM_RE = re.compile(r"^\s+([\w\-]+\.bst:)?kde/[\w/.\-]+\.bst:\s*$")

# Log path line inside failure output: "    /root/.cache/buildstream/logs/gnome/..."
BST_LOG_PATH_RE = re.compile(r"^\s+/root/\.cache/buildstream/logs/(\S+\.log)\s*$")

# Parse element name from context
ELEMENT_RE = re.compile(r"\s*(\w+):(.+)")

# cmake/ninja/meson build progress markers in element logs: "[  42/1234]"
CMAKE_PROGRESS_RE = re.compile(r'\[\s*(\d+)/\s*(\d+)\]')
# Rust/cargo: "   Compiling foo v1.2.3" lines
RUST_COMPILE_RE   = re.compile(r'^\s+Compiling\s+\S+\s+v\S')
# Rust/cargo: "    Finished [optimized] target(s)"
RUST_FINISHED_RE  = re.compile(r'^\s+Finished\s')

# ── State ──────────────────────────────────────────────────────────────────────

class State:
    def __init__(self):
        self._lock = threading.Lock()
        self.active: dict = {}
        self.completed: list = []
        self.failures: list = []
        self._summary_elements: set = set()  # elements named in BST Failure Summary
        self.pulled: int = 0
        self.success_count: int = 0
        self.failure_count: int = 0
        self.cached_count: int = 0    # build-queue skipped (already in local cache)
        self.total_elements: int = 0  # from Pipeline Summary "Total: N"
        self.recent_lines: list = []
        # Wall-clock timestamps from the log file itself
        self.build_start_ts: float = 0.0   # parsed from "=== Build started at ==="
        self.build_end_ts: float = 0.0     # mtime of log file when build last changed
        self.catching_up: bool = True       # True while doing initial log replay
        self.version = 0

    def snapshot(self):
        with self._lock:
            live = bool(self.active) or self.catching_up
            if live:
                # Build is running: elapsed = now - start
                elapsed = int(time.time() - self.build_start_ts) if self.build_start_ts else 0
            elif self.build_end_ts and self.build_start_ts:
                # Build finished: show actual duration
                elapsed = int(self.build_end_ts - self.build_start_ts)
            else:
                elapsed = 0
            done = self.success_count + self.cached_count + self.pulled + self.failure_count
            return {
                "active": list(self.active.values()),
                "completed": self.completed[-60:],
                "failures": self.failures,
                "pulled": self.pulled,
                "success": self.success_count,
                "failure": self.failure_count,
                "cached": self.cached_count,
                "done": done,
                "total": self.total_elements,
                "recent": self.recent_lines[-80:],
                "elapsed": elapsed,
                "live": live,
                "catching_up": self.catching_up,
                "build_running": build_running(),
                "version": self.version,
                "sysinfo": dict(_sysinfo),
            }

    def update(self, fn):
        with self._lock:
            fn(self)
            self.version += 1


STATE = State()

# ── cmake progress enrichment ──────────────────────────────────────────────────

def _enrich_cmake(snap: dict):
    """Read last 8 KB of each active job's log and inject build progress info.

    Sets one of:
      cmake_done / cmake_total  — cmake/ninja/meson [x/y] markers
      rust_crates               — count of Rust "Compiling" lines seen
    """
    for job in snap.get("active", []):
        log_path = job.get("log", "")
        if not log_path:
            continue
        try:
            size = os.path.getsize(log_path)
            with open(log_path, "rb") as f:
                f.seek(max(0, size - 8192))
                tail = f.read().decode("utf-8", errors="replace")
            # cmake / ninja / meson: prefer [x/y] markers (most reliable)
            matches = CMAKE_PROGRESS_RE.findall(tail)
            if matches:
                done_s, total_s = matches[-1]
                job["cmake_done"]  = int(done_s)
                job["cmake_total"] = int(total_s)
                continue
            # Rust/cargo: count "Compiling" lines in the tail
            rust_lines = RUST_COMPILE_RE.findall(tail)
            if rust_lines:
                job["rust_crates"] = len(rust_lines)
                job["rust_done"]   = not bool(RUST_FINISHED_RE.search(tail))
        except Exception:
            pass

# ── Dependency tree ────────────────────────────────────────────────────────────

_deptree_lock = threading.Lock()
_deptree: dict = {"status": "idle", "nodes": {}, "root": ""}


def _fetch_deptree():
    """Run bst show in the BST container and populate _deptree (background thread)."""
    global _deptree
    with _deptree_lock:
        if _deptree["status"] == "loading":
            return   # already in progress
        _deptree = {"status": "loading", "nodes": {}, "root": BST_TARGET}

    try:
        cache_dir = os.path.join(os.path.expanduser("~"), ".cache", "buildstream")
        result = subprocess.run(
            [
                "podman", "run", "--rm",
                "--privileged", "--device", "/dev/fuse", "--network=host",
                "-v", f"{PROJECT_DIR}:/src:rw",
                "-v", f"{cache_dir}:/root/.cache/buildstream:rw",
                "-w", "/src",
                BST2_IMAGE,
                "bst", "show", "--deps", "all",
                "--format", "%{name}\t%{deps}\n",
                BST_TARGET,
            ],
            capture_output=True, text=True, timeout=300,
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip()[-500:] or "bst show failed")
        # %{deps} outputs YAML block-sequence format, e.g.:
        #   name.bst\t- dep1.bst
        #   - dep2.bst
        #   - dep3.bst
        # or "[]" for no deps.  We accumulate continuation "- dep" lines
        # into the current element's dep list.
        nodes: dict[str, list] = {}
        current_name: "str | None" = None
        current_deps: list = []

        def _flush():
            if current_name is not None:
                nodes[current_name] = current_deps[:]

        for raw_line in result.stdout.splitlines():
            if "\t" in raw_line:
                _flush()
                name_part, dep_part = raw_line.split("\t", 1)
                current_name = name_part.strip()
                current_deps = []
                dep_part = dep_part.strip()
                if dep_part and dep_part != "[]":
                    dep = dep_part.lstrip("-").strip()
                    if dep:
                        current_deps.append(dep)
            elif current_name is not None:
                stripped = raw_line.strip()
                if stripped.startswith("-"):
                    dep = stripped.lstrip("-").strip()
                    if dep:
                        current_deps.append(dep)
        _flush()

        with _deptree_lock:
            _deptree = {"status": "ready", "nodes": nodes, "root": BST_TARGET}
    except Exception as exc:
        with _deptree_lock:
            _deptree = {"status": "error", "nodes": {}, "root": BST_TARGET,
                        "error": str(exc)[:500]}

# ── System resource sampling ───────────────────────────────────────────────────

def _read_proc_stat() -> list[tuple[int, int]]:
    """Return a list of (idle_ticks, total_ticks), first entry is aggregate."""
    stats = []
    try:
        with open("/proc/stat") as f:
            for line in f:
                if not line.startswith("cpu"):
                    break
                parts = line.split()
                # cpu  user nice system idle iowait irq softirq ...
                vals = list(map(int, parts[1:8]))
                idle  = vals[3] + vals[4]
                total = sum(vals)
                stats.append((idle, total))
    except Exception:
        pass
    return stats


def _read_proc_meminfo() -> tuple[int, int]:
    """Return (used_bytes, total_bytes) from /proc/meminfo."""
    info: dict[str, int] = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v = line.split(":", 1)
            info[k.strip()] = int(v.split()[0])   # kB
    total = info.get("MemTotal", 0)
    avail = info.get("MemAvailable", 0)
    return (total - avail) * 1024, total * 1024


def _bst_container_stats(cid: str) -> tuple[float | None, int | None]:
    """Return (cpu_pct, mem_bytes) for the running BST container, or (None, None)."""
    if not cid:
        return None, None
    try:
        r = subprocess.run(
            ["podman", "stats", "--no-stream", "--format",
             "{{.CPUPerc}},{{.MemUsage}}", cid],
            capture_output=True, text=True, timeout=3,
        )
        line = r.stdout.strip()
        if not line:
            return None, None
        cpu_str, mem_str = line.split(",", 1)
        cpu = float(cpu_str.strip().rstrip("%"))
        # mem_str like "1.23GiB / 31.7GiB" — grab the used part
        mem_used_str = mem_str.split("/")[0].strip()
        mul = 1
        for suffix, factor in [("GiB", 1 << 30), ("MiB", 1 << 20), ("kB", 1000)]:
            if mem_used_str.endswith(suffix):
                mul = factor
                mem_used_str = mem_used_str[:-len(suffix)]
                break
        mem_bytes = int(float(mem_used_str) * mul)
        return cpu, mem_bytes
    except Exception:
        return None, None


def _get_cpu_temp() -> "float | None":
    """Return CPU package temperature in °C from hwmon or thermal_zone, or None."""
    try:
        hwmon_base = "/sys/class/hwmon"
        for hwmon_dir in sorted(os.listdir(hwmon_base)):
            hwmon_path = os.path.join(hwmon_base, hwmon_dir)
            try:
                with open(os.path.join(hwmon_path, "name")) as f:
                    name = f.read().strip()
            except Exception:
                continue
            if name not in ("coretemp", "k10temp", "zenpower", "cpu_thermal"):
                continue
            # Prefer a sensor labelled "Package id 0", "Tdie", or "Tccd"
            best = None
            for fname in sorted(os.listdir(hwmon_path)):
                if not (fname.startswith("temp") and fname.endswith("_input")):
                    continue
                label = ""
                try:
                    with open(os.path.join(hwmon_path, fname.replace("_input", "_label"))) as f:
                        label = f.read().strip()
                except Exception:
                    pass
                try:
                    with open(os.path.join(hwmon_path, fname)) as f:
                        val = int(f.read().strip()) / 1000.0
                except Exception:
                    continue
                if any(k in label for k in ("Package", "Tdie", "Tccd")):
                    return val       # best match — return immediately
                if best is None:
                    best = val       # fall back to first sensor in this hwmon
            if best is not None:
                return best
    except Exception:
        pass
    # Fallback: thermal_zone
    try:
        for zone_dir in sorted(os.listdir("/sys/class/thermal")):
            if not zone_dir.startswith("thermal_zone"):
                continue
            zone_path = os.path.join("/sys/class/thermal", zone_dir)
            try:
                with open(os.path.join(zone_path, "type")) as f:
                    tz_type = f.read().strip().lower()
                if any(k in tz_type for k in ("cpu", "x86", "acpitz")):
                    with open(os.path.join(zone_path, "temp")) as f:
                        return int(f.read().strip()) / 1000.0
            except Exception:
                continue
    except Exception:
        pass
    return None


def _sysinfo_sampler():
    global _cpu_prev
    while True:
        try:
            stats = _read_proc_stat()
            if not _cpu_prev or len(_cpu_prev) != len(stats):
                _cpu_prev = stats
                time.sleep(1)
                continue

            cpu_pcts = []
            for i in range(len(stats)):
                idle, total = stats[i]
                prev_idle, prev_total = _cpu_prev[i]
                d_total = total - prev_total
                pct = round(100.0 * (1.0 - (idle - prev_idle) / d_total), 1) if d_total else 0.0
                cpu_pcts.append(max(0.0, min(100.0, pct)))

            _cpu_prev = stats

            mem_used, mem_total = _read_proc_meminfo()
            cid = _bst_container_id()
            bst_cpu, bst_mem = _bst_container_stats(cid) if cid else (None, None)
            cpu_temp = _get_cpu_temp()

            with _sysinfo_lock:
                _sysinfo["cpu_pct"]     = cpu_pcts[0]
                _sysinfo["cpu_cores"]   = cpu_pcts[1:]
                _sysinfo["mem_used"]    = mem_used
                _sysinfo["mem_total"]   = mem_total
                _sysinfo["bst_cpu_pct"] = bst_cpu
                _sysinfo["bst_mem"]     = bst_mem
                _sysinfo["cpu_temp"]    = cpu_temp
                _sysinfo["bst_running"] = bool(cid)
        except Exception:
            pass
        time.sleep(2)


threading.Thread(target=_sysinfo_sampler, daemon=True).start()


# ── Log parser ─────────────────────────────────────────────────────────────────

def reset_state():
    """Reset state for a new build (log was truncated/rotated)."""
    def _reset(s):
        s.active.clear()
        s.completed.clear()
        s.failures.clear()
        s._summary_elements.clear()
        s.pulled = 0
        s.success_count = 0
        s.failure_count = 0
        s.cached_count = 0
        # Keep total_elements across resets — stable between runs
        s.recent_lines.clear()
        s.build_start_ts = 0.0
        s.build_end_ts = 0.0
        s.catching_up = True
    STATE.update(_reset)


def parse_line(raw: str):
    clean = ANSI.sub("", raw).rstrip()
    if not clean:
        return

    # Detect new build header ("=== Build started at ... ===")
    hm = BUILD_HEADER_RE.search(clean)
    if hm:
        try:
            # e.g. "Tue Apr 22 03:21:55 IST 2026" — strip timezone abbrev for parsing
            date_str = re.sub(r'\s+[A-Z]{2,5}\s+', ' ', hm.group(1))
            ts = datetime.datetime.strptime(date_str.strip(), "%a %b %d %H:%M:%S %Y").timestamp()
        except Exception:
            ts = time.time()
        def _set_start(s):
            s.active.clear()
            s.completed.clear()
            s.failures.clear()
            s._summary_elements.clear()
            s.pulled = 0
            s.success_count = 0
            s.failure_count = 0
            s.cached_count = 0
            s.recent_lines.clear()
            s.build_end_ts = 0.0
            s.catching_up = True
            s.build_start_ts = ts
            s.recent_lines.append(clean)
        STATE.update(_set_start)
        return

    # Pipeline Summary lines (unstructured, no BST prefix)
    # "Pipeline Summary" → build has ended; freeze state.
    # The BST "Failure Summary" block appears BEFORE "Pipeline Summary" in the log,
    # so by this point _summary_elements is fully populated. Filter out cascade
    # failures (elements that failed only because a dependency failed, not listed
    # in the Failure Summary).
    if PIPELINE_SUMMARY_RE.match(clean):
        def _pipeline_done(s):
            s.active.clear()
            s.catching_up = False
            if not s.build_end_ts:
                s.build_end_ts = time.time()
            if s._summary_elements:
                # Keep only root-cause failures (those in the Failure Summary).
                # Also reset counters — each Pipeline Summary is authoritative for
                # its sub-run; failures from prior sub-runs are superseded.
                s.failures = [f for f in s.failures if f["element"] in s._summary_elements]
                s.failure_count = len(s.failures)
            # Clear for next sub-run (BST emits multiple Pipeline Summary blocks
            # in one session without a new "Build started" header)
            s._summary_elements.clear()
            s.recent_lines.append(clean)
        STATE.update(_pipeline_done)
        return

    tm = SUMMARY_TOTAL_RE.match(clean)
    if tm:
        total = int(tm.group(1))
        def _set_total(s):
            s.total_elements = total
        STATE.update(_set_total)

    qm = SUMMARY_QUEUE_RE.match(clean)
    if qm and qm.group(1) == "Build":
        failed = int(qm.group(4))
        # cached_count and pulled are already tracked live from SKIPPED/SUCCESS Pull events.
        # Only back-fill failure_count from summary if we missed live FAILURE events.
        def _backfill_failures(s, _fl=failed):
            if s.failure_count == 0 and _fl > 0:
                s.failure_count = _fl
        STATE.update(_backfill_failures)

    # Failure Summary element lines: "    kde-build-meta.bst:kde/plasma/foo.bst:"
    # These are root-cause failures only (BST omits cascade failures from this section).
    fm = FAILURE_ELEM_RE.match(clean)
    if fm:
        raw_elem = clean.strip().rstrip(":")
        short_elem = raw_elem.split(":")[-1]
        def _add_failure_elem(s, _e=short_elem):
            s._summary_elements.add(_e)
            if not any(f["element"] == _e for f in s.failures):
                s.failures.append({"element": _e, "hash": "", "duration": 0, "status": "failure", "log": ""})
                s.failure_count = max(s.failure_count, len(s.failures))
        STATE.update(_add_failure_elem)

    # Log path line inside failure detail: attach to most recent failure without a log
    lm = BST_LOG_PATH_RE.match(clean)
    if lm:
        bst_logs = os.path.expanduser("~/.cache/buildstream/logs")
        host_log = os.path.join(bst_logs, lm.group(1))
        def _set_fail_log(s, _p=host_log):
            for f in reversed(s.failures):
                if not f.get("log"):
                    f["log"] = _p
                    break
        STATE.update(_set_fail_log)

    m = LINE_RE.match(clean)
    if not m:
        # Skip deeply-indented lines — these are embedded log/compile output from
        # the Failure Summary block and shouldn't appear in the Recent Log panel.
        if not clean.startswith("        "):
            trunc = clean[:200]
            def _add(s, _l=trunc):
                s.recent_lines.append(_l)
            STATE.update(_add)
        return

    status   = m.group("status").strip()
    ctx      = m.group("ctx").strip()
    bst_hash = m.group("hash").strip()
    msg      = m.group("msg").strip()

    cm      = ELEMENT_RE.match(ctx)
    action  = cm.group(1) if cm else ctx
    element = cm.group(2).split(":")[-1] if cm else ctx

    short = element
    for prefix in ("kde-build-meta.bst:", "freedesktop-sdk.bst:", "gnome-build-meta.bst:"):
        short = short.replace(prefix, "")

    is_top = bool(BUILD_LOG_RE.search(msg))

    def _add_recent(s):
        s.recent_lines.append(f"[{status:7s}] {short}  {msg}")
    STATE.update(_add_recent)

    if action == "build" and is_top:
        if status == "START":
            # BST emits relative log paths like "gnome/pkg/hash-build.log"
            # Full path on host: ~/.cache/buildstream/logs/<relative>
            bst_logs = os.path.expanduser("~/.cache/buildstream/logs")
            host_log = os.path.join(bst_logs, msg) if msg.endswith(".log") else ""
            def _start(s, _log=host_log):
                s.active[bst_hash] = {
                    "element": short,
                    "hash": bst_hash,
                    "start": time.time(),
                    "log": _log,
                }
            STATE.update(_start)

        elif status == "SUCCESS":
            def _done(s):
                entry = s.active.pop(bst_hash, None)
                dur = int(time.time() - entry["start"]) if entry else 0
                s.completed.append({"element": short, "hash": bst_hash, "duration": dur, "status": "success"})
                s.success_count += 1
                s.build_end_ts = time.time()
            STATE.update(_done)

        elif status == "FAILURE":
            # BST top-level failure says "Command failed" (no log path), so don't
            # require is_top — just check if this hash was actually being tracked.
            def _fail(s):
                entry = s.active.pop(bst_hash, None)
                if entry is None:
                    return  # sub-event failure we don't care about
                dur = int(time.time() - entry["start"])
                item = {"element": short, "hash": bst_hash, "duration": dur,
                        "status": "failure", "log": entry.get("log", "")}
                s.completed.append(item)
                # Avoid duplicates from Failure Summary catch-up
                if not any(f["hash"] == bst_hash for f in s.failures):
                    # Update existing catch-up entry if present (same element, no hash)
                    for f in s.failures:
                        if f["element"] == short and not f["hash"]:
                            f.update(item)
                            break
                    else:
                        s.failures.append(item)
                s.failure_count = len(s.failures)
                s.build_end_ts = time.time()
            STATE.update(_fail)

    elif action == "pull":
        if status == "SKIPPED" and "Pull" in msg:
            def _skip_pull(s):
                s.cached_count += 1
            STATE.update(_skip_pull)
        elif status == "SUCCESS" and "Pull" in msg:
            def _pull(s):
                s.pulled += 1
            STATE.update(_pull)


def tail_log():
    """Tail LOG_FILE, resetting state if the file is truncated (new build started)."""
    buf = ""
    pos = 0
    while True:
        try:
            size = os.path.getsize(LOG_FILE)
        except FileNotFoundError:
            time.sleep(2)
            continue

        if size < pos:
            # File was truncated — new build started
            reset_state()
            pos = 0
            buf = ""

        if size > pos:
            try:
                with open(LOG_FILE, "rb") as f:
                    f.seek(pos)
                    chunk = f.read(size - pos).decode("utf-8", errors="replace")
                pos = size
                buf += chunk
                lines = buf.split("\n")
                buf = lines[-1]
                for line in lines[:-1]:
                    parse_line(line)
            except Exception:
                pass
        elif STATE.catching_up:
            # We've read everything — mark catch-up complete
            def _done_catching_up(s):
                s.catching_up = False
                # If no active jobs and we have data, use log file mtime as end time
                if not s.active and s.success_count > 0 and not s.build_end_ts:
                    try:
                        s.build_end_ts = os.path.getmtime(LOG_FILE)
                    except Exception:
                        pass
            STATE.update(_done_catching_up)

        time.sleep(0.5)


# ── HTML ───────────────────────────────────────────────────────────────────────

HTML = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BST Build Dashboard</title>
<style>
  /* ── Theme: light default, auto-switch, explicit overrides ── */
  :root {
    --bg: #ffffff; --surface: #f6f8fa; --border: #d0d7de;
    --text: #1f2328; --muted: #656d76;
    --green: #1a7f37; --red: #d1242f; --blue: #0969da;
    --yellow: #9a6700; --orange: #bc4c00;
    --cached: #b6bbbf;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #0d1117; --surface: #161b22; --border: #30363d;
      --text: #e6edf3; --muted: #7d8590;
      --green: #3fb950; --red: #f85149; --blue: #58a6ff;
      --yellow: #d29922; --orange: #f0883e;
      --cached: #3a3a4a;
    }
  }
  [data-theme="light"] {
    --bg: #ffffff; --surface: #f6f8fa; --border: #d0d7de;
    --text: #1f2328; --muted: #656d76;
    --green: #1a7f37; --red: #d1242f; --blue: #0969da;
    --yellow: #9a6700; --orange: #bc4c00;
    --cached: #b6bbbf;
  }
  [data-theme="dark"] {
    --bg: #0d1117; --surface: #161b22; --border: #30363d;
    --text: #e6edf3; --muted: #7d8590;
    --green: #3fb950; --red: #f85149; --blue: #58a6ff;
    --yellow: #d29922; --orange: #f0883e;
    --cached: #3a3a4a;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text); font-family: 'Consolas','Menlo',monospace; font-size: 13px; }

  /* ── Header ── */
  header { padding: 10px 16px; border-bottom: 1px solid var(--border); display: flex; flex-wrap: wrap; align-items: center; gap: 10px 16px; }
  header h1 { font-size: 15px; font-weight: 600; color: var(--blue); white-space: nowrap; }
  .stats { display: flex; gap: 14px; flex-wrap: wrap; }
  .stat { display: flex; flex-direction: column; align-items: center; }
  .stat-val { font-size: 20px; font-weight: 700; }
  .stat-lbl { color: var(--muted); font-size: 11px; }
  #ctrl-btn { margin-left: auto; padding: 8px 18px; border-radius: 6px; border: 1px solid; background: transparent; cursor: pointer; font-family: inherit; font-size: 13px; font-weight: 600; transition: opacity .15s; touch-action: manipulation; }
  #ctrl-btn:hover { opacity: .75; }
  #theme-btn { padding: 5px 9px; border-radius: 6px; border: 1px solid var(--border); background: transparent; cursor: pointer; font-size: 14px; line-height: 1; color: var(--muted); touch-action: manipulation; }
  #theme-btn:hover { color: var(--text); }
  .green { color: var(--green); }
  .red   { color: var(--red); }
  .blue  { color: var(--blue); }
  .yellow{ color: var(--yellow); }
  .orange{ color: var(--orange); }

  /* ── Progress bar ── */
  #progress-wrap { padding: 10px 16px 6px; }
  #progress-bar-bg { background: var(--surface); border: 1px solid var(--border); border-radius: 6px; height: 18px; overflow: hidden; }
  #progress-bar { height: 100%; display: flex; }
  .pb-seg { height: 100%; transition: width .4s ease; min-width: 0; }
  #pb-cached { background: var(--cached); }
  #pb-pulled { background: var(--yellow); }
  #pb-built  { background: var(--green); }
  #pb-active { background: var(--blue); opacity: .85; }
  #pb-failed { background: var(--red); }
  #progress-label { font-size: 11px; color: var(--muted); margin-top: 4px; display: flex; gap: 10px 14px; flex-wrap: wrap; }
  .pb-legend { display: flex; align-items: center; gap: 4px; }
  .pb-dot { width: 8px; height: 8px; border-radius: 2px; flex-shrink: 0; }
  .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 11px; font-weight: 600; margin-left: 10px; vertical-align: middle; }
  .badge-live     { background: color-mix(in srgb, var(--green) 15%, transparent); color: var(--green); border: 1px solid var(--green); }
  .badge-done     { background: color-mix(in srgb, var(--blue)  10%, transparent); color: var(--muted); border: 1px solid var(--border); }
  .badge-loading  { background: color-mix(in srgb, var(--yellow) 15%, transparent); color: var(--yellow); border: 1px solid var(--yellow); }

  /* ── Panels ── */
  main { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; padding: 10px 16px 20px; height: calc(100vh - 130px); }
  section { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; display: flex; flex-direction: column; overflow: hidden; min-height: 0; }
  section h2 { font-size: 12px; padding: 8px 12px; border-bottom: 1px solid var(--border); color: var(--muted); text-transform: uppercase; letter-spacing: .08em; flex-shrink: 0; }
  .scroll { overflow-y: auto; flex: 1; padding: 8px 12px; -webkit-overflow-scrolling: touch; }

  .job { padding: 6px 0; border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 8px; cursor: pointer; touch-action: manipulation; }
  .job:last-child { border-bottom: none; }
  .job:hover, .job:active { background: color-mix(in srgb, var(--text) 5%, transparent); border-radius: 4px; }
  .pulse { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: var(--blue); animation: pulse 1s infinite; flex-shrink: 0; }
  .dot-ok  { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: var(--green); flex-shrink: 0; }
  .dot-err { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: var(--red); flex-shrink: 0; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.3} }
  .ename { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .dur { color: var(--muted); font-size: 11px; flex-shrink: 0; }

  #log-section { grid-column: 1 / -1; }
  #log-output { font-size: 11px; line-height: 1.5; white-space: pre-wrap; word-break: break-all; color: var(--muted); }
  .log-start   { color: var(--blue); }
  .log-success { color: var(--green); }
  .log-failure { color: var(--red); }
  .log-other   { color: var(--muted); }

  .fail-entry { padding: 6px 0; border-bottom: 1px solid var(--border); color: var(--red); cursor: pointer; touch-action: manipulation; }
  .fail-entry:last-child { border-bottom: none; }
  .fail-hash { color: var(--muted); font-size: 11px; }

  /* ── Log modal ── */
  #log-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.7); z-index: 100; align-items: center; justify-content: center; }
  #log-modal.open { display: flex; }
  #log-modal-box { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; width: 90vw; height: 80vh; display: flex; flex-direction: column; overflow: hidden; }
  #log-modal-title { padding: 10px 14px; border-bottom: 1px solid var(--border); font-size: 13px; font-weight: 600; display: flex; align-items: center; gap: 10px; }
  #log-modal-close { margin-left: auto; cursor: pointer; font-size: 22px; line-height: 1; background: none; border: none; color: var(--muted); padding: 4px 8px; touch-action: manipulation; }
  #log-modal-close:hover, #log-modal-close:active { color: var(--text); }
  #log-modal-body { flex: 1; overflow-y: auto; padding: 10px 14px; font-size: 11px; line-height: 1.5; white-space: pre-wrap; word-break: break-all; color: var(--muted); -webkit-overflow-scrolling: touch; }

  /* ── Sysinfo bar ── */
  #sysinfo-wrap { padding: 2px 16px 8px; display: flex; gap: 20px; flex-wrap: wrap; }
  .si-item { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--muted); }
  .si-clickable { cursor: pointer; user-select: none; }
  .si-clickable:hover { color: var(--text); }
  .si-lbl { min-width: 30px; font-weight: 600; }
  .si-bar-bg { width: 80px; height: 7px; background: var(--surface); border: 1px solid var(--border); border-radius: 3px; overflow: hidden; flex-shrink: 0; }
  .si-bar { height: 100%; border-radius: 3px; transition: width .8s ease, background-color .8s; }
  .si-txt { min-width: 54px; }
  #si-cpu-txt { min-width: 90px; }

  #si-cores-wrap {
    grid-column: 1 / -1;
    display: none;
    grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
    gap: 8px 16px;
    padding: 8px 16px;
    background: var(--surface);
    border-top: 1px solid var(--border);
    width: 100%;
  }
  #si-cores-wrap.open { display: grid; }
  .core-item { display: flex; align-items: center; gap: 6px; font-size: 10px; color: var(--muted); }
  .core-lbl { min-width: 45px; }
  .core-bar-bg { flex: 1; height: 4px; background: var(--bg); border: 1px solid var(--border); border-radius: 2px; overflow: hidden; }
  .core-bar { height: 100%; transition: width .8s ease; }

  /* ── cmake mini progress ── */
  .cmake-bar-bg { height: 3px; background: var(--border); border-radius: 2px; margin-top: 3px; overflow: hidden; }
  .cmake-bar    { height: 100%; background: var(--blue); border-radius: 2px; transition: width .4s ease; }
  .cmake-lbl    { font-size: 10px; color: var(--muted); margin-left: auto; white-space: nowrap; }

  /* ── Dependency tree modal ── */
  #tree-modal { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.7); z-index: 200; align-items: center; justify-content: center; }
  #tree-modal.open { display: flex; }
  #tree-modal-box  { background: var(--surface); border: 1px solid var(--border); border-radius: 10px; width: 92vw; height: 88vh; display: flex; flex-direction: column; overflow: hidden; }
  #tree-modal-hdr  { padding: 10px 14px; border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
  #tree-modal-hdr h3 { font-size: 13px; font-weight: 600; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .tree-view-btn { padding: 4px 10px; border-radius: 5px; border: 1px solid var(--border); background: transparent; cursor: pointer; font-family: inherit; font-size: 12px; color: var(--muted); }
  .tree-view-btn.active { background: var(--blue); color: #fff; border-color: var(--blue); }
  #tree-modal-close { cursor: pointer; font-size: 22px; line-height: 1; background: none; border: none; color: var(--muted); padding: 4px 8px; }
  #tree-modal-close:hover { color: var(--text); }
  #tree-search { padding: 6px 12px; border-bottom: 1px solid var(--border); flex-shrink: 0; }
  #tree-search input { width: 100%; padding: 5px 10px; border: 1px solid var(--border); border-radius: 6px; background: var(--bg); color: var(--text); font-family: inherit; font-size: 12px; }
  #tree-body { flex: 1; overflow: auto; padding: 10px 14px; -webkit-overflow-scrolling: touch; }
  /* Collapsible tree */
  .tree-list { list-style: none; padding-left: 18px; }
  .tree-list.root { padding-left: 0; }
  .tree-list details > summary { cursor: pointer; user-select: none; padding: 2px 0; border-radius: 3px; display: flex; align-items: center; gap: 4px; }
  .tree-list details > summary:hover { background: color-mix(in srgb, var(--text) 5%, transparent); }
  .tree-node-leaf { padding: 2px 0 2px 20px; display: flex; align-items: center; gap: 4px; }
  .tree-nm { font-size: 11px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; cursor: pointer; }
  .tree-nm:hover { text-decoration: underline; }
  .tree-nm.highlight { background: color-mix(in srgb, var(--yellow) 30%, transparent); border-radius: 3px; padding: 0 3px; }
  .tree-nm.selected { background: color-mix(in srgb, var(--blue) 20%, transparent); color: var(--blue); border-radius: 3px; padding: 0 3px; }
  .tree-cnt { font-size: 10px; color: var(--muted); margin-left: 4px; flex-shrink: 0; }
  /* Element info strip */
  #tree-info { border-top: 1px solid var(--border); padding: 8px 14px; font-size: 11px; flex-shrink: 0; display: none; background: var(--bg); }
  #tree-info .ti-name { font-weight: 600; color: var(--blue); }
  #tree-info .ti-full { color: var(--muted); font-size: 10px; word-break: break-all; }
  #tree-info .ti-badges { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 4px; }
  #tree-info .ti-badge { font-size: 10px; padding: 1px 7px; border-radius: 10px; border: 1px solid var(--border); color: var(--muted); }
  /* SVG tree view */
  #svg-container { width: 100%; height: 100%; overflow: auto; }
  #svg-container svg { display: block; }
  #tree-status { padding: 20px; color: var(--muted); font-size: 13px; }
  #tree-refresh-btn { padding: 5px 12px; border-radius: 5px; border: 1px solid var(--border); background: transparent; cursor: pointer; font-family: inherit; font-size: 12px; color: var(--blue); }

  @media (max-width: 640px) {
    #tree-modal-box { width: 100vw; height: 100dvh; border-radius: 0; border: none; }
  }

  /* ── Mobile layout ── */
  @media (max-width: 640px) {
    body { font-size: 14px; }
    header { padding: 10px 12px; gap: 8px 12px; }
    header h1 { font-size: 14px; }
    .stat-val { font-size: 18px; }
    .stats { gap: 10px; }
    #progress-wrap { padding: 8px 12px 4px; }
    /* Single-column stacked panels; natural page scroll instead of fixed height */
    main { grid-template-columns: 1fr; height: auto; padding: 8px 12px 16px; gap: 8px; }
    #log-section { grid-column: 1; }
    section { min-height: 120px; max-height: 40vh; }
    #log-section { max-height: 30vh; }
    /* Full-screen modal on mobile */
    #log-modal-box { width: 100vw; height: 100dvh; border-radius: 0; border: none; }
    #log-modal-body { font-size: 12px; }
    #ctrl-btn { padding: 8px 14px; font-size: 12px; }
  }
</style>
</head>
<body>
<header>
  <h1>⚙ BuildStream Dashboard<span id="status-badge" class="badge badge-loading">Loading…</span></h1>
  <div class="stats">

    <div class="stat"><span class="stat-val green" id="s-ok">0</span><span class="stat-lbl">Built</span></div>
    <div class="stat"><span class="stat-val blue"  id="s-active">0</span><span class="stat-lbl">Active</span></div>
    <div class="stat"><span class="stat-val yellow" id="s-pull">0</span><span class="stat-lbl">Pulled</span></div>
    <div class="stat"><span class="stat-val red"   id="s-fail">0</span><span class="stat-lbl">Failed</span></div>
    <div class="stat"><span class="stat-val"       id="s-time">0s</span><span class="stat-lbl">Elapsed</span></div>
  </div>
  <button id="tree-btn" onclick="openTree()" title="Dependency tree" style="padding:5px 9px;border-radius:6px;border:1px solid var(--border);background:transparent;cursor:pointer;font-size:13px;color:var(--muted)">🌳</button>
  <button id="theme-btn" onclick="toggleTheme()" title="Toggle light/dark">◐</button>
  <button id="ctrl-btn" onclick="toggleBuild()" style="color:var(--muted);border-color:var(--border)">…</button>
</header>

<div id="progress-wrap">
  <div id="progress-bar-bg">
    <div id="progress-bar">
      <div class="pb-seg" id="pb-cached"></div>
      <div class="pb-seg" id="pb-pulled"></div>
      <div class="pb-seg" id="pb-built"></div>
      <div class="pb-seg" id="pb-active"></div>
      <div class="pb-seg" id="pb-failed"></div>
    </div>
  </div>
  <div id="progress-label">
    <span class="pb-legend"><span class="pb-dot" style="background:var(--cached)"></span><span id="lb-cached">0 cached</span></span>
    <span class="pb-legend"><span class="pb-dot" style="background:var(--yellow)"></span><span id="lb-pulled">0 pulled</span></span>
    <span class="pb-legend"><span class="pb-dot" style="background:var(--green)"></span><span id="lb-built">0 built</span></span>
    <span class="pb-legend"><span class="pb-dot" style="background:var(--blue)"></span><span id="lb-active">0 building</span></span>
    <span class="pb-legend"><span class="pb-dot" style="background:var(--red)"></span><span id="lb-failed">0 failed</span></span>
    <span id="lb-total" style="margin-left:auto"></span>
  </div>
</div>

<div id="sysinfo-wrap">
  <div class="si-item si-clickable" onclick="toggleCores()">
    <span class="si-lbl">CPU</span>
    <div class="si-bar-bg"><div id="si-cpu-bar" class="si-bar" style="width:0%;background:var(--blue)"></div></div>
    <span class="si-txt" id="si-cpu-txt">–</span>
  </div>
  <div class="si-item">
    <span class="si-lbl">RAM</span>
    <div class="si-bar-bg"><div id="si-ram-bar" class="si-bar" style="width:0%;background:var(--green)"></div></div>
    <span class="si-txt" id="si-ram-txt">–</span>
  </div>
  <div class="si-item" id="si-bst-wrap" style="display:none">
    <span class="si-lbl">BST</span>
    <div class="si-bar-bg"><div id="si-bst-bar" class="si-bar" style="width:0%;background:var(--yellow)"></div></div>
    <span class="si-txt" id="si-bst-txt">–</span>
  </div>
  <div id="si-cores-wrap"></div>
</div>

<main>
  <section>
    <h2>Active Jobs</h2>
    <div class="scroll" id="active-list"></div>
  </section>

  <section>
    <h2>Failures</h2>
    <div class="scroll" id="fail-list"></div>
  </section>

  <section id="log-section">
    <h2>Recent Log</h2>
    <div class="scroll" id="log-scroll">
      <div id="log-output"></div>
    </div>
  </section>
</main>

<div id="log-modal">
  <div id="log-modal-box">
    <div id="log-modal-title">
      <span id="log-modal-elem"></span>
      <button id="log-modal-close" onclick="closeLog()">✕</button>
    </div>
    <div id="log-modal-body">Loading…</div>
  </div>
</div>

<div id="tree-modal">
  <div id="tree-modal-box">
    <div id="tree-modal-hdr">
      <h3>🌳 Dependency Tree</h3>
      <button class="tree-view-btn active" id="btn-view-tree" onclick="setTreeView('tree')">Collapsible</button>
      <button class="tree-view-btn" id="btn-view-graph" onclick="setTreeView('graph')">Family Tree</button>
      <button id="tree-refresh-btn" onclick="refreshTree()">↺ Refresh</button>
      <button id="tree-modal-close" onclick="closeTree()">✕</button>
    </div>
    <div id="tree-search"><input type="search" id="tree-search-input" placeholder="Search elements…" oninput="filterTree(this.value)"></div>
    <div id="tree-body"><div id="tree-status" style="color:var(--muted)">Loading dependency tree…</div></div>
    <div id="tree-info"></div>
  </div>
</div>

<script>
// ── Theme ──────────────────────────────────────────────────────────────────
(function() {
  const stored = localStorage.getItem('bst-theme');
  if (stored) document.documentElement.dataset.theme = stored;
})();

function _currentTheme() {
  return document.documentElement.dataset.theme ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
}
function toggleTheme() {
  const next = _currentTheme() === 'dark' ? 'light' : 'dark';
  document.documentElement.dataset.theme = next;
  localStorage.setItem('bst-theme', next);
  _updateThemeBtn();
}
function _updateThemeBtn() {
  document.getElementById('theme-btn').textContent = _currentTheme() === 'dark' ? '☀' : '☾';
}
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', _updateThemeBtn);
_updateThemeBtn();

function toggleCores() {
  _showCores = !_showCores;
  poll();
}

// ── Dashboard ───────────────────────────────────────────────────────────────
let lastVersion = -1;
let autoScroll = true;
let _showCores = false;
// Resolve API URL relative to where this page is hosted (works under any path prefix)
const API_URL = new URL('api/state', document.baseURI).href;

// Show connection status in lb-total (does not disturb lb-* siblings)
document.getElementById('lb-total').textContent = 'Connecting…';

const logScroll = document.getElementById('log-scroll');
logScroll.addEventListener('scroll', () => {
  const atBottom = logScroll.scrollHeight - logScroll.scrollTop - logScroll.clientHeight < 40;
  autoScroll = atBottom;
});

function fmtDur(s) {
  if (s < 60) return s + 's';
  return Math.floor(s/60) + 'm' + (s%60) + 's';
}

function fmtElapsed(s) {
  const h = Math.floor(s/3600);
  const m = Math.floor((s%3600)/60);
  const sec = s%60;
  if (h) return h + 'h' + m + 'm' + sec + 's';
  if (m) return m + 'm' + sec + 's';
  return sec + 's';
}

function colorLine(l) {
  const esc = (s, cls) => `<span class="${cls}">${s.replace(/</g,'&lt;')}</span>`;
  if (l.startsWith('[START  ]')) return esc(l, 'log-start');
  if (l.startsWith('[SUCCESS]')) return esc(l, 'log-success');
  if (l.startsWith('[FAILURE]')) return esc(l, 'log-failure');
  return esc(l, 'log-other');
}

async function poll() {
  try {
    const r = await fetch(API_URL);
    if (!r.ok) { document.getElementById('lb-total').textContent = `API error: HTTP ${r.status}`; return; }
    const d = await r.json();
    lastVersion = d.version;
    _lastBuildState = d;

    // Run/stop button
    const btn = document.getElementById('ctrl-btn');
    btn.textContent = d.build_running ? '■ Stop Build' : '▶ Start Build';
    btn.style.color = d.build_running ? 'var(--red)' : 'var(--green)';
    btn.style.borderColor = d.build_running ? 'var(--red)' : 'var(--green)';

    // Status badge
    const badge = document.getElementById('status-badge');
    if (d.catching_up) {
      badge.className = 'badge badge-loading'; badge.textContent = 'Loading…';
    } else if (d.live) {
      badge.className = 'badge badge-live'; badge.textContent = '⚡ Live';
    } else if (d.success > 0 || d.failure > 0) {
      badge.className = 'badge badge-done'; badge.textContent = 'Last build (complete)';
    } else {
      badge.className = 'badge badge-loading'; badge.textContent = 'No build data';
    }

    // Stats
    document.getElementById('s-ok').textContent     = d.success;
    document.getElementById('s-active').textContent  = d.active.length;
    document.getElementById('s-pull').textContent    = d.pulled;
    document.getElementById('s-fail').textContent    = d.failure;
    document.getElementById('s-time').textContent    = fmtElapsed(d.elapsed);

    // Segmented progress bar
    const total = d.total || (d.done + d.active.length) || 1;
    const pct = n => (Math.min(total, n) / total * 100).toFixed(2) + '%';
    document.getElementById('pb-cached').style.width = pct(d.cached);
    document.getElementById('pb-pulled').style.width = pct(d.pulled);
    document.getElementById('pb-built').style.width  = pct(d.success);
    document.getElementById('pb-active').style.width = pct(d.active.length);
    document.getElementById('pb-failed').style.width = pct(d.failure);
    document.getElementById('lb-cached').textContent = d.cached + ' cached';
    document.getElementById('lb-pulled').textContent = d.pulled + ' pulled';
    document.getElementById('lb-built').textContent  = d.success + ' built';
    document.getElementById('lb-active').textContent = d.active.length + ' building';
    document.getElementById('lb-failed').textContent = d.failure + ' failed';
    const overallPct = total > 0 ? Math.round(d.done / total * 100) : 0;
    const suffix = !d.live && d.done > 0 ? ' · last build' : '';
    document.getElementById('lb-total').textContent =
      `${d.done}${d.total ? ' / ' + d.total : ''} · ${overallPct}%${suffix}`;

    // Sysinfo bars
    const si = d.sysinfo || {};
    const cpuPct = si.cpu_pct || 0;
    const cpuColor = cpuPct > 85 ? 'var(--red)' : cpuPct > 60 ? 'var(--yellow)' : 'var(--blue)';
    document.getElementById('si-cpu-bar').style.width = cpuPct + '%';
    document.getElementById('si-cpu-bar').style.background = cpuColor;
    const tempStr = si.cpu_temp != null ? ' ' + Math.round(si.cpu_temp) + '°C' : '';
    document.getElementById('si-cpu-txt').textContent = cpuPct.toFixed(1) + '%' + tempStr;

    // Per-core bars
    const coresWrap = document.getElementById('si-cores-wrap');
    if (_showCores && si.cpu_cores && si.cpu_cores.length > 0) {
      coresWrap.classList.add('open');
      coresWrap.innerHTML = si.cpu_cores.map((pct, i) => {
        const cColor = pct > 85 ? 'var(--red)' : pct > 60 ? 'var(--yellow)' : 'var(--blue)';
        return `<div class="core-item"><span class="core-lbl">Core ${i}</span>` +
          `<div class="core-bar-bg"><div class="core-bar" style="width:${pct}%;background-color:${cColor}"></div></div>` +
          `<span style="min-width:30px;text-align:right">${Math.round(pct)}%</span></div>`;
      }).join('');
    } else {
      coresWrap.classList.remove('open');
      coresWrap.innerHTML = '';
    }

    if (si.mem_total) {
      const memPct = Math.round(si.mem_used / si.mem_total * 100);
      const memColor = memPct > 85 ? 'var(--red)' : memPct > 65 ? 'var(--yellow)' : 'var(--green)';
      const memUsedGb = (si.mem_used / 1073741824).toFixed(1);
      const memTotalGb = (si.mem_total / 1073741824).toFixed(1);
      document.getElementById('si-ram-bar').style.width = memPct + '%';
      document.getElementById('si-ram-bar').style.background = memColor;
      document.getElementById('si-ram-txt').textContent = memUsedGb + ' / ' + memTotalGb + ' GB';
    }
    const bstWrap = document.getElementById('si-bst-wrap');
    if (si.bst_cpu_pct !== null && si.bst_cpu_pct !== undefined) {
      bstWrap.style.display = '';
      const bstPct = Math.min(100, si.bst_cpu_pct);
      document.getElementById('si-bst-bar').style.width = bstPct + '%';
      const bstMemGb = si.bst_mem ? (si.bst_mem / 1073741824).toFixed(1) + 'GB' : '';
      document.getElementById('si-bst-txt').textContent = bstPct.toFixed(1) + '% ' + bstMemGb;
    } else {
      bstWrap.style.display = 'none';
    }

    // Active jobs
    const activeEl = document.getElementById('active-list');
    const now = Date.now() / 1000;
    activeEl.innerHTML = d.active.length === 0
      ? '<div style="color:var(--muted);padding:8px">No active jobs</div>'
      : d.active.map(j => {
          const dur = j.start ? Math.round(now - j.start) : 0;
          const esc = j.element.replace(/"/g, '&quot;');
          let cmakeHtml = '';
          if (j.cmake_total) {
            const cpct = Math.round(j.cmake_done / j.cmake_total * 100);
            cmakeHtml = `<div style="display:flex;align-items:center;gap:6px;margin-top:1px">` +
              `<div class="cmake-bar-bg" style="flex:1"><div class="cmake-bar" style="width:${cpct}%"></div></div>` +
              `<span class="cmake-lbl">${j.cmake_done}/${j.cmake_total}</span></div>`;
          } else if (j.rust_crates) {
            cmakeHtml = `<div style="display:flex;align-items:center;gap:6px;margin-top:1px">` +
              `<span class="cmake-lbl" style="color:var(--orange)">🦀 ${j.rust_crates} crates</span></div>`;
          }
          return `<div class="job" style="flex-direction:column;align-items:stretch" onclick="openLog('${j.hash}','${esc}')">` +
            `<div style="display:flex;align-items:center;gap:8px">` +
            `<span class="pulse"></span><span class="ename" title="${esc}">${j.element}</span>` +
            `<span class="dur">${fmtDur(dur)}</span></div>` +
            cmakeHtml + `</div>`;
        }).join('');

    // Failures
    const failEl = document.getElementById('fail-list');
    failEl.innerHTML = d.failures.length === 0
      ? '<div style="color:var(--muted);padding:8px">No failures</div>'
      : d.failures.map(f => {
          const esc = f.element.replace(/</g,'&lt;').replace(/"/g,'&quot;');
          const clickable = f.log ? `onclick="openLogPath('${encodeURIComponent(f.log)}','${esc}')" style="cursor:pointer"` : '';
          const logIcon = f.log ? ' <span style="color:var(--blue);font-size:10px">[log]</span>' : '';
          return `<div class="fail-entry" ${clickable}><span class="dot-err"></span> ${esc}${logIcon}<br><span class="fail-hash">${f.hash ? f.hash + ' · ' : ''}${fmtDur(f.duration)}</span></div>`;
        }).join('');

    // Log
    const logEl = document.getElementById('log-output');
    logEl.innerHTML = d.recent.map(colorLine).join('\\n');
    if (autoScroll) logScroll.scrollTop = logScroll.scrollHeight;

  } catch(e) { document.getElementById('lb-total').textContent = `Fetch error: ${e.message}`; }
}

let logRefreshTimer = null;

async function openLog(hash, element) {
  openLogUrl(new URL('api/log?hash=' + hash, document.baseURI).href, element);
}

async function openLogPath(encodedPath, element) {
  openLogUrl(new URL('api/log?path=' + encodedPath, document.baseURI).href, element);
}

function openLogUrl(url, element) {
  document.getElementById('log-modal-elem').textContent = element;
  document.getElementById('log-modal-body').textContent = 'Loading…';
  document.getElementById('log-modal').classList.add('open');
  clearInterval(logRefreshTimer);
  refreshLogUrl(url);
  logRefreshTimer = setInterval(() => refreshLogUrl(url), 2000);
}

async function refreshLog(hash) {
  await refreshLogUrl(new URL('api/log?hash=' + hash, document.baseURI).href);
}

async function refreshLogUrl(url) {
  try {
    const r = await fetch(url);
    const text = await r.text();
    const body = document.getElementById('log-modal-body');
    const atBottom = body.scrollHeight - body.scrollTop - body.clientHeight < 60;
    body.textContent = text;
    if (atBottom) body.scrollTop = body.scrollHeight;
  } catch(e) { document.getElementById('log-modal-body').textContent = 'Error: ' + e.message; }
}

function closeLog() {
  document.getElementById('log-modal').classList.remove('open');
  clearInterval(logRefreshTimer);
  logRefreshTimer = null;
}

document.getElementById('log-modal').addEventListener('click', e => {
  if (e.target === document.getElementById('log-modal')) closeLog();
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') { closeLog(); closeTree(); }
});

// ── Dependency tree modal ───────────────────────────────────────────────────
let _treeData     = null;   // {nodes, root}
let _treeParents  = {};     // reverse adjacency: name -> [parents]
let _treeSelected = null;   // currently selected element name
let _treeView     = 'tree'; // 'tree' | 'graph'
let _treeFilter   = '';
let _treePollTimer = null;
// Last known build state (for status badges in info panel)
let _lastBuildState = null;

function openTree() {
  document.getElementById('tree-modal').classList.add('open');
  if (!_treeData) loadTree();
}
function closeTree() {
  document.getElementById('tree-modal').classList.remove('open');
  if (_treePollTimer) { clearInterval(_treePollTimer); _treePollTimer = null; }
}
function setTreeView(view) {
  _treeView = view;
  document.getElementById('btn-view-tree').classList.toggle('active',  view === 'tree');
  document.getElementById('btn-view-graph').classList.toggle('active', view === 'graph');
  if (_treeData) renderTree();
}
function filterTree(q) {
  _treeFilter = q.trim().toLowerCase();
  if (_treeData) renderTree();
}
function refreshTree() {
  _treeData = null; _treeParents = {}; _treeSelected = null;
  document.getElementById('tree-info').style.display = 'none';
  fetch(new URL('api/deptree/refresh', document.baseURI), {method:'POST'});
  loadTree();
}

function _buildParents(nodes) {
  const p = {};
  for (const [name, deps] of Object.entries(nodes)) {
    for (const dep of deps) { if (!p[dep]) p[dep] = []; p[dep].push(name); }
  }
  return p;
}

function _selectNode(name) {
  _treeSelected = name;
  // Update highlight in collapsible tree
  document.querySelectorAll('#tree-body .tree-nm.selected').forEach(el => el.classList.remove('selected'));
  document.querySelectorAll(`#tree-body .tree-nm[data-n]`).forEach(el => {
    if (el.dataset.n === name) el.classList.add('selected');
  });
  _updateInfoPanel();
  if (_treeView === 'graph') renderGraphTree();
}

function _statusOf(name) {
  if (!_lastBuildState) return null;
  const short = name.split(':').pop(); // strip junction prefix
  const d = _lastBuildState;
  if (d.active && d.active.some(j => j.element === short)) return 'active';
  if (d.failures && d.failures.some(f => f.element === short)) return 'failure';
  if (d.completed && d.completed.some(c => c.element === short && c.status === 'success')) return 'success';
  return null;
}

function _updateInfoPanel() {
  const el = document.getElementById('tree-info');
  if (!_treeSelected || !_treeData) { el.style.display = 'none'; return; }
  const name = _treeSelected;
  const deps = _treeData.nodes[name] || [];
  const parents = _treeParents[name] || [];
  const status = _statusOf(name);
  const statusBadge = status === 'active'  ? `<span class="ti-badge" style="color:var(--blue);border-color:var(--blue)">⚡ building</span>`
                    : status === 'success' ? `<span class="ti-badge" style="color:var(--green);border-color:var(--green)">✓ built</span>`
                    : status === 'failure' ? `<span class="ti-badge" style="color:var(--red);border-color:var(--red)">✗ failed</span>`
                    : '';
  el.style.display = '';
  el.innerHTML =
    `<div class="ti-name">${_shortName(name)}</div>` +
    `<div class="ti-full">${_escAttr(name)}</div>` +
    `<div class="ti-badges">` +
    `<span class="ti-badge">${deps.length} dep${deps.length!==1?'s':''}</span>` +
    `<span class="ti-badge">${parents.length} needed by</span>` +
    statusBadge +
    (parents.length ? `<span class="ti-badge" style="cursor:pointer" onclick="_selectNode(${JSON.stringify(parents[0])})" title="First parent">↑ ${_shortName(parents[0])}</span>` : '') +
    `</div>`;
}

async function loadTree() {
  document.getElementById('tree-body').innerHTML = '<div id="tree-status">Loading dependency tree…</div>';
  if (_treePollTimer) clearInterval(_treePollTimer);
  _treePollTimer = setInterval(_pollTree, 1500);
  await _pollTree();
}

async function _pollTree() {
  try {
    const r = await fetch(new URL('api/deptree', document.baseURI));
    const d = await r.json();
    if (d.status === 'ready') {
      clearInterval(_treePollTimer); _treePollTimer = null;
      _treeData = d;
      _treeParents = _buildParents(d.nodes);
      renderTree();
    } else if (d.status === 'error') {
      clearInterval(_treePollTimer); _treePollTimer = null;
      document.getElementById('tree-body').innerHTML =
        `<div id="tree-status" style="color:var(--red)">Error: ${d.error || 'unknown'}</div>`;
    }
    // else still loading — keep polling
  } catch(e) {
    document.getElementById('tree-body').innerHTML =
      `<div id="tree-status" style="color:var(--red)">Fetch error: ${e.message}</div>`;
  }
}

function renderTree() {
  if (!_treeData) return;
  if (_treeView === 'graph') renderGraphTree();
  else renderCollapsibleTree();
}

// ── Shared helpers ─────────────────────────────────────────────────────────
function _shortName(name) {
  return name.split('/').pop().replace(/\\.bst$/, '');
}
function _escAttr(s) {
  return s.replace(/"/g, '&quot;').replace(/</g, '&lt;');
}

// ── Collapsible tree view — lazy rendering ─────────────────────────────────
// Nodes are rendered one level at a time. Children are injected into the DOM
// when the parent <details> is first opened (toggle event, capture phase).
// When a search filter is active we fall back to a flat filtered list instead,
// which is always fast regardless of tree size.

function _buildShallowNode(name, ancestors) {
  const { nodes } = _treeData;
  const q = _treeFilter;
  const deps = (nodes[name] || []).filter(d => !ancestors.has(d));
  const display = _shortName(name);
  const selClass = name === _treeSelected ? ' selected' : '';
  const hlClass  = (q && name.toLowerCase().includes(q) ? ' highlight' : '') + selClass;
  const safe = _escAttr(name);
  const jname = JSON.stringify(name);
  const nmSpan = `<span class="tree-nm${hlClass}" data-n="${safe}" title="${safe}" onclick="event.stopPropagation();_selectNode(${jname})">${display}</span>`;
  if (deps.length === 0) {
    return `<li><div class="tree-node-leaf">${nmSpan}</div></li>`;
  }
  return `<li><details data-node="${safe}"><summary>` +
    nmSpan +
    `<span class="tree-cnt">(${deps.length})</span></summary>` +
    `<ul class="tree-list" data-lazy="${safe}"></ul></details></li>`;
}

function _lazyExpandNode(ul, name) {
  const { nodes } = _treeData;
  // Collect ancestor names by walking up the DOM
  const ancestors = new Set();
  let el = ul.parentElement;
  while (el) {
    const dn = el.dataset && el.dataset.node;
    if (dn) ancestors.add(dn);
    el = el.parentElement;
  }
  const deps = (nodes[name] || []).filter(d => !ancestors.has(d));
  ul.innerHTML = deps.map(d => _buildShallowNode(d, new Set([...ancestors, name]))).join('');
  delete ul.dataset.lazy;
}

// Event delegation: capture toggle on any <details> inside #tree-body
document.getElementById('tree-body').addEventListener('toggle', e => {
  if (e.target.tagName !== 'DETAILS' || !e.target.open) return;
  const ul = e.target.querySelector('ul[data-lazy]');
  if (!ul) return;
  _lazyExpandNode(ul, ul.dataset.lazy);
}, true);

function renderCollapsibleTree() {
  const { nodes, root } = _treeData;
  const q = _treeFilter;
  const body = document.getElementById('tree-body');

  if (!q) {
    // No filter: lazy top-level render (just root + its direct children)
    const rootDeps = (nodes[root] || []);
    const rootDisplay = _shortName(root);
    const safe = _escAttr(root);
    const jroot = JSON.stringify(root).replace(/</g, '\\u003c');
    const rootSelClass = root === _treeSelected ? ' selected' : '';
    const childrenHtml = rootDeps.map(d => _buildShallowNode(d, new Set([root]))).join('');
    body.innerHTML =
      `<ul class="tree-list root"><li>` +
      `<details data-node="${safe}" open><summary>` +
      `<span class="tree-nm${rootSelClass}" data-n="${safe}" title="${safe}" onclick="event.stopPropagation();_selectNode(${jroot})">${rootDisplay}</span>` +
      `<span class="tree-cnt">(${rootDeps.length})</span></summary>` +
      `<ul class="tree-list">${childrenHtml}</ul>` +
      `</details></li></ul>`;
    return;
  }

  // Filter active: build a flat list of matching element names (fast, no recursion)
  const ql = q.toLowerCase();
  const matches = Object.keys(nodes).filter(n => n.toLowerCase().includes(ql));
  if (matches.length === 0) {
    body.innerHTML = `<div id="tree-status">No elements match "${_escAttr(q)}"</div>`;
    return;
  }
  const MAX_RESULTS = 200;
  const shown = matches.slice(0, MAX_RESULTS);
  const more = matches.length > MAX_RESULTS ? `<div style="color:var(--muted);padding:6px">…and ${matches.length - MAX_RESULTS} more</div>` : '';
  body.innerHTML =
    `<ul class="tree-list root">` +
    shown.map(name => {
      const safe = _escAttr(name);
      const jname = JSON.stringify(name).replace(/</g, '\\u003c');
      const deps = (nodes[name] || []);
      const selClass = name === _treeSelected ? ' selected' : '';
      return `<li><div class="tree-node-leaf" style="flex-direction:column;align-items:flex-start;cursor:pointer" onclick="_selectNode(${jname})">` +
        `<span class="tree-nm highlight${selClass}" data-n="${safe}" title="${safe}">${_shortName(name)}</span>` +
        `<span style="font-size:10px;color:var(--muted);pointer-events:none">${safe}</span>` +
        (deps.length ? `<span class="tree-cnt" style="pointer-events:none">${deps.length} dep${deps.length>1?'s':''}</span>` : '') +
        `</div></li>`;
    }).join('') +
    `</ul>${more}`;
}

// ── SVG family-tree view — focused subgraph ───────────────────────────────
// Shows the immediate neighbourhood of the selected element:
//   row 0: parents (who depend on it)      [yellow]
//   row 1: selected element                [blue]
//   row 2: direct deps (children)          [normal]
//   row 3: deps of deps (grandchildren)    [muted]
// Click a node in the Collapsible view first to focus here.
function renderGraphTree() {
  const body = document.getElementById('tree-body');
  if (!_treeSelected) {
    body.innerHTML = `<div id="tree-status">` +
      `Click any element in the <strong>Collapsible</strong> view to explore its dependency graph here.</div>`;
    return;
  }

  const { nodes } = _treeData;
  const sel = _treeSelected;
  const NODE_W = 164, NODE_H = 36, H_GAP = 12, V_GAP = 54;
  const MAX_PARENTS = 12, MAX_CHILDREN = 20, MAX_GRANDCHILDREN = 4;

  const parents     = (_treeParents[sel] || []).slice(0, MAX_PARENTS);
  const children    = (nodes[sel] || []).slice(0, MAX_CHILDREN);
  // Grandchildren: up to MAX_GRANDCHILDREN per child, deduped
  const gcSeen = new Set([sel, ...parents, ...children]);
  const grandchildren = [];
  for (const c of children) {
    for (const gc of (nodes[c] || []).slice(0, MAX_GRANDCHILDREN)) {
      if (!gcSeen.has(gc)) { gcSeen.add(gc); grandchildren.push(gc); }
    }
  }

  // Levels: parents→0, sel→1, children→2, grandchildren→3
  const level = {[sel]: 1};
  parents.forEach(n => level[n] = 0);
  children.forEach(n => level[n] = 2);
  grandchildren.forEach(n => level[n] = 3);

  // Edges
  const edges = [];
  parents.forEach(p => edges.push([p, sel, 'parent']));
  children.forEach(c => edges.push([sel, c, 'child']));
  for (const c of children) {
    for (const gc of (nodes[c] || []).slice(0, MAX_GRANDCHILDREN)) {
      if (level[gc] === 3) edges.push([c, gc, 'gc']);
    }
  }

  // Position each row: evenly spaced horizontally, centred on sel
  function rowX(names) {
    const n = names.length;
    return names.map((_, i) => (i - (n - 1) / 2) * (NODE_W + H_GAP));
  }
  const pos = {};
  const rows = [parents, [sel], children, grandchildren];
  rows.forEach((row, ri) => {
    const xs = rowX(row);
    row.forEach((name, i) => pos[name] = { x: xs[i], y: ri * (NODE_H + V_GAP) });
  });

  // SVG bounds
  const allX = Object.values(pos).map(p => p.x);
  const PAD = 24;
  const svgW = Math.max(500, Math.max(...allX) - Math.min(...allX) + NODE_W + PAD * 2);
  const svgH = (rows.length) * (NODE_H + V_GAP) + PAD * 2;
  const ox = svgW / 2, oy = PAD;

  const cs = getComputedStyle(document.documentElement);
  const cBorder  = cs.getPropertyValue('--border').trim();
  const cText    = cs.getPropertyValue('--text').trim();
  const cSurface = cs.getPropertyValue('--surface').trim();
  const cBlue    = cs.getPropertyValue('--blue').trim();
  const cMuted   = cs.getPropertyValue('--muted').trim();
  const cYellow  = cs.getPropertyValue('--yellow').trim();
  const cGreen   = cs.getPropertyValue('--green').trim();
  const cRed     = cs.getPropertyValue('--red').trim();

  function nodeColor(name) {
    const s = _statusOf(name);
    return s === 'active' ? cBlue : s === 'success' ? cGreen : s === 'failure' ? cRed : cBorder;
  }

  let svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${svgW}" height="${svgH}" style="font-family:monospace">`;

  // Row labels
  const labels = ['needed by', '', 'depends on', 'dep of dep'];
  rows.forEach((row, ri) => {
    if (!row.length || ri === 1) return;
    const ry = ri * (NODE_H + V_GAP) + oy + NODE_H / 2 + 4;
    const lx = svgW - 4;
    svg += `<text x="${lx}" y="${ry}" text-anchor="end" fill="${cMuted}" font-size="9">${labels[ri]} (${row.length})</text>`;
  });

  // Edges
  for (const [a, b] of edges) {
    if (!pos[a] || !pos[b]) continue;
    const x1 = pos[a].x + ox, y1 = pos[a].y + oy + NODE_H;
    const x2 = pos[b].x + ox, y2 = pos[b].y + oy;
    const my = (y1 + y2) / 2;
    svg += `<path d="M${x1} ${y1} C${x1} ${my},${x2} ${my},${x2} ${y2}" fill="none" stroke="${cBorder}" stroke-width="1.2" opacity="0.7"/>`;
  }

  // Nodes — use data-name for click binding (avoid inline onclick escaping issues)
  const nodeNames = [];
  for (const [name, {x, y}] of Object.entries(pos)) {
    const idx = nodeNames.length;
    nodeNames.push(name);
    const rx = x + ox - NODE_W / 2, ry = y + oy;
    const isSel = name === sel;
    const stroke = isSel ? cBlue : nodeColor(name);
    const sw = isSel ? 2.5 : 1.2;
    // SVG fill can't use color-mix() — use a plain color for selection
    const fill = isSel ? (document.documentElement.dataset.theme === 'light' ? '#dbeafe' : '#1e3a5f') : cSurface;
    const textColor = isSel ? cBlue : cText;
    const display = _shortName(name);
    const trunc = display.length > 21 ? display.slice(0, 19) + '…' : display;
    svg += `<g class="svg-nd" data-idx="${idx}" style="cursor:pointer">` +
      `<rect x="${rx}" y="${ry}" width="${NODE_W}" height="${NODE_H}" rx="5" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>` +
      `<text x="${rx + NODE_W/2}" y="${ry + NODE_H/2 + 4}" text-anchor="middle" fill="${textColor}" font-size="10">${trunc}</text>` +
      `</g>`;
  }

  // Truncation notes
  const pMore = (_treeParents[sel] || []).length - parents.length;
  const cMore = (nodes[sel] || []).length - children.length;
  if (pMore > 0) svg += `<text x="${svgW/2}" y="${oy - 6}" text-anchor="middle" fill="${cMuted}" font-size="9">+${pMore} more parents not shown</text>`;
  if (cMore > 0) svg += `<text x="${svgW/2}" y="${svgH - 4}" text-anchor="middle" fill="${cMuted}" font-size="9">+${cMore} more deps not shown</text>`;

  svg += '</svg>';
  body.innerHTML = `<div id="svg-container">${svg}</div>`;

  // Wire click/tap handlers after DOM insertion
  body.querySelectorAll('.svg-nd').forEach(el => {
    const name = nodeNames[parseInt(el.dataset.idx)];
    el.addEventListener('click', () => _selectNode(name));
  });
}

document.getElementById('tree-modal').addEventListener('click', e => {
  if (e.target === document.getElementById('tree-modal')) closeTree();
});

async function toggleBuild() {
  const btn = document.getElementById('ctrl-btn');
  const running = btn.textContent.includes('Stop');
  const msg = running ? 'Stop the running build?' : 'Start a new build?';
  if (!confirm(msg)) return;
  btn.disabled = true;
  try {
    await fetch(new URL(running ? 'api/stop' : 'api/start', document.baseURI), {method: 'POST'});
  } finally {
    btn.disabled = false;
  }
}

poll();
setInterval(poll, 800);
</script>
</body>
</html>
"""

# ── HTTP handler ───────────────────────────────────────────────────────────────

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # silence access log

    def _json_reply(self, data: dict):
        body = json.dumps(data).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _norm_path(self):
        """Strip /bst prefix so we work both via Caddy and Tailscale Serve directly."""
        p = self.path.split("?", 1)
        path = p[0].rstrip("/") or "/"
        query = p[1] if len(p) > 1 else ""
        if path.startswith("/bst"):
            path = path[4:] or "/"
        return path, query

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        path, _ = self._norm_path()
        if path == "/api/start":
            ok = start_build()
            self._json_reply({"ok": ok})
        elif path == "/api/stop":
            ok = stop_build()
            self._json_reply({"ok": ok})
        elif path == "/api/deptree/refresh":
            threading.Thread(target=_fetch_deptree, daemon=True).start()
            self._json_reply({"ok": True})
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        path, query = self._norm_path()
        if path == "/api/state":
            snap = STATE.snapshot()
            _enrich_cmake(snap)
            data = json.dumps(snap).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
        elif path == "/api/deptree":
            with _deptree_lock:
                payload = dict(_deptree)
            # Auto-trigger fetch if idle
            if payload["status"] == "idle":
                threading.Thread(target=_fetch_deptree, daemon=True).start()
                payload["status"] = "loading"
            data = json.dumps(payload).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
        elif path == "/api/log":
            import urllib.parse
            params = dict(p.split("=", 1) for p in query.split("&") if "=" in p)
            log_path = None
            if "path" in params:
                # Direct path (for failures) — validate it stays inside buildstream logs
                candidate = urllib.parse.unquote(params["path"])
                bst_logs = os.path.expanduser("~/.cache/buildstream/logs")
                if os.path.abspath(candidate).startswith(bst_logs):
                    log_path = candidate
            elif "hash" in params:
                h = params["hash"]
                with STATE._lock:
                    entry = STATE.active.get(h)
                    if entry:
                        log_path = entry.get("log")
            if not log_path or not os.path.exists(log_path):
                body = b"Log not available"
                self.send_response(404)
            else:
                try:
                    with open(log_path, "rb") as f:
                        raw = f.read().decode("utf-8", errors="replace")
                    lines = ANSI.sub("", raw).splitlines()[-300:]
                    body = "\n".join(lines).encode()
                    self.send_response(200)
                except Exception as e:
                    body = str(e).encode()
                    self.send_response(500)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)
        else:
            body = HTML.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(body)


# ── Main ───────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    tailer = threading.Thread(target=tail_log, daemon=True)
    tailer.start()

    server = ThreadedHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"BST Dashboard  http://localhost:{PORT}/")
    print(f"  log:     {LOG_FILE}")
    print(f"  target:  {BST_TARGET}")
    print(f"  project: {PROJECT_DIR}")
    print(f"  image:   {BST2_IMAGE[:60]}…" if len(BST2_IMAGE) > 60 else f"  image:   {BST2_IMAGE}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
