#!/usr/bin/env python3
"""Reuse or create an iPhone 15 Pro Max simulator for GitHub's Xcode tests."""
import json
import subprocess


def simctl(*args):
    return subprocess.check_output(["xcrun", "simctl", *args], text=True).strip()


runtimes = json.loads(simctl("list", "runtimes", "-j"))["runtimes"]
available = [runtime for runtime in runtimes if runtime.get("isAvailable") and ".iOS-" in runtime["identifier"]]
if not available:
    raise SystemExit("No available iOS simulator runtime on this GitHub runner.")
runtime = max(available, key=lambda item: tuple(int(part) for part in item["version"].split(".")))
devices = json.loads(simctl("list", "devices", "available", "-j"))["devices"]
device = next((item for item in devices.get(runtime["identifier"], []) if "iPhone 15 Pro Max" in item["name"]), None)
if device:
    print(device["udid"])
else:
    types = json.loads(simctl("list", "devicetypes", "-j"))["devicetypes"]
    kind = next((item for item in types if item["name"] == "iPhone 15 Pro Max"), None)
    if not kind:
        raise SystemExit("This Xcode runner does not provide the iPhone 15 Pro Max simulator device type.")
    print(simctl("create", "Harbor iPhone 15 Pro Max", kind["identifier"], runtime["identifier"]))
