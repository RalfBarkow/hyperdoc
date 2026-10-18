#!/usr/bin/env python3
"""Build the Federated Wiki page topicmap-inspection-dita from the DITA topics next to it.

The topics in dreyeck/work/topicmap-inspection-docs/dita/*.dita are the sources; the page file under site/pages/ holds them as
story Items of type "dita" (the XML text is the Item's text). The tests compare the two, so the sources and the page cannot drift.
Usage: python3 scripts/build-topicmap-inspection-page.py [--check]
"""
import json, pathlib, re, sys

root = pathlib.Path(__file__).resolve().parent.parent / "dreyeck/work/topicmap-inspection-docs"
page_file = root / "site/pages/topicmap-inspection-dita"
# Stable ids, in reading order. The id is the identity of an Item; the position is not.
topics = [("4f1c7a92b3d85e01", "topicmap-signs-and-represented-objects", "concept"),
          ("4f1c7a92b3d85e02", "tmdm-roles-and-projected-edges", "concept"),
          ("4f1c7a92b3d85e03", "topicmap-gesture-operations", "reference"),
          ("4f1c7a92b3d85e04", "inspect-a-topicmap-sign", "task")]
INTRO = ("Topicmap inspection in DITA: the two Operations Inspect Topicmap sign and Inspect represented object, and what they open. "
         "Four topics in reading order: Topicmap Signs and Represented Objects (concept), TMDM Roles and Projected Edges (concept), "
         "Topicmap Gesture Operations (reference), Inspect a Topicmap Sign (task). Each is a story Item of type dita that holds one DITA 1.3 topic as XML. "
         "The Work item that carries them is topicmap-interaction-documentation in Work Breakdown.")
DATE = 1792281600000  # 2026-10-18T00:00:00Z

def build():
    story = [{"type": "paragraph", "id": "4f1c7a92b3d85e00", "text": INTRO}]
    for item_id, name, info_type in topics:
        xml = (root / "dita" / (name + ".dita")).read_text(encoding="utf-8")
        assert re.search(r"<%s id=\"%s\"" % (info_type, name), xml), name
        story.append({"type": "dita", "id": item_id, "text": xml, "ditaVersion": "1.3", "infoType": info_type})
    title = "Topicmap Inspection (DITA)"
    return {"title": title, "story": story,
            "journal": [{"type": "create", "id": "4f1c7a92b3d85eff", "item": {"title": title, "story": story}, "date": DATE}]}

if __name__ == "__main__":
    text = json.dumps(build(), indent=2, ensure_ascii=False) + "\n"
    if "--check" in sys.argv:
        sys.exit(0 if page_file.exists() and page_file.read_text(encoding="utf-8") == text else 1)
    page_file.parent.mkdir(parents=True, exist_ok=True)
    page_file.write_text(text, encoding="utf-8")
    print("wrote", page_file, len(text), "bytes")
