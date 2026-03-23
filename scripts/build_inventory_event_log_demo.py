#!/usr/bin/env python3
"""
Deprecated. The event log at /demo/inventory-event-log is now server-rendered by Flask
using replay.get_recent_inventory_events() — no embedded JSON.

This script is kept only so old docs/commands fail loudly instead of overwriting
Templates/hw_inventory_log_demo.html.
"""


def main() -> None:
    print(
        "Nothing to build: hw_inventory_log_demo.html is maintained as a Jinja template "
        "and populated from the database on each request (see app.inventory_event_log_demo)."
    )


if __name__ == "__main__":
    main()
