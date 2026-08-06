#!/usr/bin/env python3
"""Render a Checkov JSON report's summary as a Markdown blurb for
$GITHUB_STEP_SUMMARY. Reads RESULTS_PATH and CLOUD from the environment so
no untrusted input is ever interpolated into a shell or YAML string.

Usage: RESULTS_PATH=... CLOUD=... python3 scripts/checkov_summary.py
"""
import json
import os
import sys

results_path = os.environ.get("RESULTS_PATH")
cloud = os.environ.get("CLOUD", "")

if not results_path or not os.path.isfile(results_path):
    sys.exit(0)

with open(results_path) as f:
    summary = json.load(f)["summary"]

print(f"### Checkov — insecure example demo ({cloud.upper()})")
print()
print(
    f"**{summary['failed']} misconfigurations detected**, "
    f"{summary['passed']} checks passed, {summary['skipped']} skipped."
)
print()
print(
    f"This directory (`examples/insecure/{cloud}`) is intentionally broken "
    "and never applied — see its README."
)
