import time
import json
import urllib.request

FILE_PATH = "events.json"   # file Arduino writes to
API_URL = "https://your-ngrok-url.ngrok.io/api/event"

def send_event(event):
    try:
        data = json.dumps(event).encode("utf-8")

        req = urllib.request.Request(
            API_URL,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )

        with urllib.request.urlopen(req) as response:
            print("Sent:", event)
    except Exception as e:
        print("Error sending event:", e)


def process_file():
    try:
        with open(FILE_PATH, "r") as f:
            content = f.read().strip()

        if not content:
            return

        # assume file contains one JSON object
        event = json.loads(content)

        send_event(event)

        # clear file after successful send
        with open(FILE_PATH, "w") as f:
            f.write("")

    except Exception as e:
        print("Error processing file:", e)


if __name__ == "__main__":
    print("Listening for hardware events...")

    while True:
        process_file()
        time.sleep(5)   # check every 5 seconds