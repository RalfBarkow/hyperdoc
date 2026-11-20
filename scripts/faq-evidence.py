"""Bind the index entry to the last completed, recorded ASDF probe run."""
import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

# Each verified entry and the cases its recorded run must pass, in order.
CASES = {
    "asdf-fasl-nix-store": ["source", "packaged", "destinations", "missing"],
    "asdf-registry-store-gc": ["registered", "vanished", "diagnose", "restored", "rooted"],
}
FAQ = Path(__file__).resolve().parents[1] / "assets/faq"
INDEX = FAQ / "index.json"
TOPIC = "asdf-fasl-nix-store"


def fields(data, expected=None):
    lines = data.decode("utf-8").splitlines()
    if not lines or not lines[-1].startswith("SUCCESS_UTC="):
        raise ValueError("Incomplete FAQ run: missing final success timestamp")
    completed = datetime.strptime(lines[-1], "SUCCESS_UTC=%Y-%m-%dT%H:%M:%SZ")
    commit, = [line[9:] for line in lines if re.fullmatch(r"checkout=[0-9a-f]{40}", line)]
    cases = [line.split()[1].rstrip(":") for line in lines if line.startswith("PASS ")]
    if cases != (expected or CASES[TOPIC]):
        raise ValueError(f"Incomplete or unexpected set of passing cases: {cases}")
    return dict(evidenceStatus="verified", lastSuccessfulRun=completed.date().isoformat(),
                evidenceCommit=commit, evidenceSha256=hashlib.sha256(data).hexdigest())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--record", type=Path, metavar="TRANSCRIPT")
    modes.add_argument("--validate-run", type=Path, metavar="TRANSCRIPT")
    parser.add_argument("--topic", choices=sorted(CASES), default=TOPIC)
    args = parser.parse_args()
    topic_id, expected = args.topic, CASES[args.topic]
    record_path = FAQ / (topic_id + "-check.txt")
    if args.validate_run:
        print(json.dumps(fields(args.validate_run.read_bytes(), expected)))
        return
    index = json.loads(INDEX.read_text())
    entry, = [item for item in index["topics"] if item["topicId"] == topic_id]
    if args.record:
        # Omit Nix startup messages and normalize trailing whitespace before hashing.
        lines = args.record.read_text().splitlines()
        start, = [n for n, line in enumerate(lines) if line.startswith("UTC=")]
        data = ("\n".join(line.rstrip() for line in lines[start:]) + "\n").encode()
    else:
        data = record_path.read_bytes()
    facts = fields(data, expected)
    topic = ET.parse(FAQ / (topic_id + ".dita")).getroot()
    status = topic.find("./prolog/metadata/othermeta[@name='status']")
    if (topic.get("id") != topic_id or status is None or status.get("content") != facts["evidenceStatus"]
            or entry["evidenceUrl"] != "/faq/" + record_path.name):
        raise ValueError("DITA identity, evidence status or transcript URL differs")
    if args.record:
        record_path.write_bytes(data)
        entry.update(facts)
        INDEX.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")
    elif any(entry.get(k) != v for k, v in facts.items()):
        raise ValueError("Published index disagrees with the recorded run")
    print(json.dumps(facts))


if __name__ == "__main__":
    main()
