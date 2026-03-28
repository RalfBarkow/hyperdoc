#!/usr/bin/env python3
import json
import os
import sys
import urllib.error
import urllib.request


URL = os.environ.get("DMX_MCP_URL", "http://127.0.0.1:8787/mcp")
WORKSPACE_URI = os.environ.get("DMX_MCP_WORKSPACE_URI", "dmx://workspace/context-window")
TOPIC_URI = os.environ.get("DMX_MCP_TOPIC_URI", "dmx://topic/907120")
VERBOSE = os.environ.get("DMX_MCP_VERBOSE", "").lower() in {"1", "true", "yes", "on"}


def fetch(method, payload=None, session_id=None):
    headers = {"Accept": "application/json, text/event-stream"}
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode("utf-8")
    if session_id:
        headers["Mcp-Session-Id"] = session_id
    request = urllib.request.Request(URL, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, dict(response.headers), response.read().decode("utf-8")
    except urllib.error.HTTPError as error:
        return error.code, dict(error.headers), error.read().decode("utf-8")


def header_value(headers, name):
    lowered = name.lower()
    for key, value in headers.items():
        if key.lower() == lowered:
            return value
    return None


def rpc(method, request_id=None, params=None, session_id=None):
    payload = {"jsonrpc": "2.0", "method": method}
    if request_id is not None:
        payload["id"] = request_id
    if params is not None:
        payload["params"] = params
    return fetch("POST", payload=payload, session_id=session_id)


def main():
    get_status, _, get_body = fetch("GET")
    print(f"GET_STATUS {get_status}")
    if VERBOSE:
        print(f"GET_BODY {get_body.strip()}")

    init_status, init_headers, init_body = rpc(
        "initialize",
        request_id=1,
        params={
            "protocolVersion": "2025-03-26",
            "clientInfo": {"name": "probe-dmx-mcp-server", "version": "1.0"},
        },
    )
    print(f"INIT_STATUS {init_status}")
    if VERBOSE:
        print(f"INIT_BODY {init_body.strip()}")
    if init_status != 200:
        return 1

    session_id = header_value(init_headers, "Mcp-Session-Id")
    if not session_id:
        print("MISSING_SESSION_ID")
        return 2
    init_payload = json.loads(init_body)
    print(f"SESSION_ID {session_id}")
    print(f"MCP_PROTOCOL_VERSION {header_value(init_headers, 'MCP-Protocol-Version')}")
    print(f"SERVER_NAME {init_payload['result']['serverInfo']['name']}")
    print(f"SERVER_VERSION {init_payload['result']['serverInfo']['version']}")

    notify_status, _, _ = rpc("notifications/initialized", session_id=session_id)
    print(f"NOTIFY_STATUS {notify_status}")
    if notify_status != 202:
        return 3

    tools_status, _, tools_body = rpc(
        "tools/list",
        request_id=2,
        session_id=session_id,
    )
    print(f"TOOLS_LIST_STATUS {tools_status}")
    if VERBOSE:
        print(f"TOOLS_LIST_BODY {tools_body.strip()}")
    if tools_status != 200:
        return 4
    tools_payload = json.loads(tools_body)
    tool_names = [tool["name"] for tool in tools_payload["result"]["tools"]]
    print(f"TOOL_NAMES {','.join(tool_names)}")

    workspace_status, _, workspace_body = rpc(
        "resources/read",
        request_id=3,
        params={"uri": WORKSPACE_URI},
        session_id=session_id,
    )
    print(f"WORKSPACE_READ_STATUS {workspace_status}")
    if VERBOSE:
        print(f"WORKSPACE_READ_BODY {workspace_body.strip()}")
    if workspace_status != 200:
        return 5
    workspace_payload = json.loads(workspace_body)
    workspace_contents = workspace_payload["result"]["contents"][0]
    workspace_json = json.loads(workspace_contents["text"])
    print(f"WORKSPACE_TOPICMAP_ID {workspace_json['workspace']['topicmapId']}")
    print(f"WORKSPACE_NOTE_COUNT {workspace_json['noteCount']}")

    topic_status, _, topic_body = rpc(
        "resources/read",
        request_id=4,
        params={"uri": TOPIC_URI},
        session_id=session_id,
    )
    print(f"TOPIC_READ_STATUS {topic_status}")
    if VERBOSE:
        print(f"TOPIC_READ_BODY {topic_body.strip()}")
    if topic_status != 200:
        return 6
    topic_payload = json.loads(topic_body)
    topic_contents = topic_payload["result"]["contents"][0]
    topic_json = json.loads(topic_contents["text"])
    print(f"TOPIC_TITLE {topic_json['title']}")

    dry_run_status, _, dry_run_body = rpc(
        "tools/call",
        request_id=5,
        params={
            "name": "validated_dmx_write_dry_run",
            "arguments": {
                "writeKind": "topicmap_context_add",
                "topicmapId": 919822,
                "topicId": 907120,
                "viewProps": {
                    "dmx.topicmaps.x": 160,
                    "dmx.topicmaps.y": 120,
                    "dmx.topicmaps.visibility": True,
                    "dmx.topicmaps.pinned": False,
                },
            },
        },
        session_id=session_id,
    )
    print(f"DRY_RUN_STATUS {dry_run_status}")
    if VERBOSE:
        print(f"DRY_RUN_BODY {dry_run_body.strip()}")
    if dry_run_status != 200:
        return 7
    dry_run_payload = json.loads(dry_run_body)
    structured = dry_run_payload["result"]["structuredContent"]
    print(f"DRY_RUN_VALIDATION_STATUS {structured['validationStatus']}")
    print(f"DRY_RUN_INTENDED_ENDPOINT {structured['intendedEndpoint']}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
