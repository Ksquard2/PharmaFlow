"""
Bridge: watches a JSON file (e.g. written by Arduino tooling) and POSTs each event to Flask.

Default target: http://127.0.0.1:5000/smartBinScan
Override: PHARMAFLOW_SCAN_URL=https://xxxx.ngrok.io/smartBinScan

The file should contain ONE JSON object — the inner "event" payload, e.g.:
{
  "itemid": 1,
  "eventType": "usage",
  "batchNumber": 1001,
  "quantityDelta": -1,
  "expirationDate": "2026-03-28",
  "locationid": 1
}

Flask wraps it as {"event": <that object>}. eventTime is set on the server (NOW()).
"""
import json
import os
import time
import urllib.request

FILE_PATH = os.environ.get("PHARMAFLOW_EVENTS_FILE", "events.json")
API_URL = os.environ.get("PHARMAFLOW_SCAN_URL", "http://127.0.0.1:5000/smartBinScan")


def send_event(event: dict) -> None:
    payload = {"event": event}
    data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(req, timeout=30) as response:
        body = response.read().decode("utf-8", errors="replace")
        print("Sent:", event, "->", response.status, body)


def process_file() -> None:
    try:
        with open(FILE_PATH, encoding="utf-8") as f:
            content = f.read().strip()

        if not content:
            return

        event = json.loads(content)
        send_event(event)

        with open(FILE_PATH, "w", encoding="utf-8") as f:
            f.write("")

    except Exception as e:
        print("Error processing file:", e)


if __name__ == "__main__":
    print(f"Watching {FILE_PATH!r} -> POST {API_URL}")

    while True:
        process_file()
        time.sleep(5)
