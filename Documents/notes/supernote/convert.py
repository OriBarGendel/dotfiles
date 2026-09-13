#!/usr/bin/env python3
"""
syncthing-watch.py

Listens to a running Syncthing instance's REST event API and prints the
relative path (extension stripped) of every *.note file that is newly
added or updated by sync. Deletes, and any non-.note files, are ignored.

Usage:
    export SYNCTHING_API_KEY=xxxx
    python3 syncthing-watch.py

Requires: pip install requests
"""

import argparse
import os
import sys
import time

import requests


class SyncthingWatcher:
    def __init__(self, base_url, api_key, since=0, verbose=False, timeout=60):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.since = since
        self.verbose = verbose
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({"X-API-Key": self.api_key})
        self._folder_paths = {}

    def log(self, *args):
        if self.verbose:
            print(*args, file=sys.stderr, flush=True)

    def _api_get(self, path, **params):
        url = f"{self.base_url}{path}"
        resp = self.session.get(url, params=params, timeout=self.timeout + 15)
        resp.raise_for_status()
        return resp.json()

    def load_folder_paths(self):
        """Map folder ID -> its local filesystem root path."""
        config = self._api_get("/rest/config")
        self._folder_paths = {
            f["id"]: f["path"] for f in config.get("folders", [])
        }
        self.log(f"Loaded {len(self._folder_paths)} folder(s): "
                  f"{self._folder_paths}")

    def poll_events(self):
        """Long-poll /rest/events for ItemFinished events newer than self.since."""
        return self._api_get(
            "/rest/events",
            since=self.since,
            timeout=self.timeout,
            type="ItemFinished",
        )

    def handle_item_finished(self, event):
        data = event.get("data", {})
        folder_id = data.get("folder")
        item = data.get("item")
        action = data.get("action")  # "update" or "delete"
        err = data.get("error")

        if err:
            self.log(f"Skipping {folder_id}/{item}: sync error: {err}")
            return

        if action != "update":
            self.log(f"Skipping non-update action '{action}': "
                      f"{folder_id}/{item}")
            return

        if not item or not item.lower().endswith(".note"):
            self.log(f"Skipping non-.note file: {folder_id}/{item}")
            return

        # item is already relative to the folder root; strip the extension.
        rel_path_no_ext = os.path.splitext(item)[0]
        print(rel_path_no_ext, flush=True)

    def run_forever(self):
        self.load_folder_paths()
        self.log(f"Watching Syncthing at {self.base_url} "
                  f"(starting since={self.since})...")
        while True:
            try:
                events = self.poll_events()
            except requests.exceptions.ReadTimeout:
                # Normal: long-poll timed out with no new events.
                continue
            except requests.exceptions.RequestException as exc:
                print(f"Request error: {exc}. Retrying in 5s...",
                      file=sys.stderr)
                time.sleep(5)
                continue

            for event in events:
                self.since = max(self.since, event.get("id", self.since))
                if event.get("type") == "ItemFinished":
                    self.handle_item_finished(event)


def main():
    parser = argparse.ArgumentParser(
        description="Print the relative path (no extension) of each new "
                     "or updated .note file synced by Syncthing."
    )
    parser.add_argument(
        "--url", default="http://127.0.0.1:8384",
        help="Syncthing GUI/API base URL (default: %(default)s)",
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("SYNCTHING_API_KEY"),
        help="Syncthing API key (or set SYNCTHING_API_KEY env var). "
             "Find it in Settings > General in the Syncthing web UI, "
             "or in config.xml.",
    )
    parser.add_argument(
        "--since", type=int, default=0,
        help="Only report events newer than this event ID "
             "(0 = only new events from now on; default: %(default)s)",
    )
    parser.add_argument(
        "--verbose", action="store_true", help="Print debug logging to stderr.",
    )
    args = parser.parse_args()

    if not args.api_key:
        parser.error(
            "An API key is required: pass --api-key or set "
            "SYNCTHING_API_KEY."
        )

    since = args.since
    if since == 0:
        # Get the current last event id so we only react to NEW events,
        # rather than replaying all history since Syncthing started.
        try:
            probe = requests.get(
                f"{args.url.rstrip('/')}/rest/events",
                headers={"X-API-Key": args.api_key},
                params={"limit": 1},
                timeout=10,
            )
            probe.raise_for_status()
            data = probe.json()
            if data:
                since = data[-1]["id"]
        except requests.exceptions.RequestException as exc:
            print(f"Warning: could not fetch initial event id: {exc}",
                  file=sys.stderr)

    watcher = SyncthingWatcher(
        base_url=args.url,
        api_key=args.api_key,
        since=since,
        verbose=args.verbose,
    )

    try:
        watcher.run_forever()
    except KeyboardInterrupt:
        print("\nStopped.", file=sys.stderr)


if __name__ == "__main__":
    main()
