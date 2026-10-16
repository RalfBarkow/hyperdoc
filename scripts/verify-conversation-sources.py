#!/usr/bin/env python3
"""Optional private-source verification. Reads originals; emits metadata only.
No transcript or excerpt is written or packaged. Paths are explicit arguments.
python3 scripts/verify-conversation-sources.py [--transcript FILE] [--report FILE]
The report argument is the existing local farm page JSON (not a transcript).
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / 'dreyeck/work/conversation-evidence/coordinates.json'
CASE = ROOT / 'dreyeck/work/collaborative-planning-evidence/case.json'
REVIEW = CASE.parent / 'claude-review-submitted.txt'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def extract(record):
    """v1: do not reinterpret pasted authorship, generated summaries or wrappers."""
    content = record['message']['content']
    if isinstance(content, str):
        return content
    return ''.join(block['text'] if block['type'] == 'text' else
                   block['input']['plan'] if block.get('name') == 'ExitPlanMode' else ''
                   for block in content)


def verify_review(text, offset=-1386):
    retained = REVIEW.read_text(encoding='utf8')
    assert offset == -1386 and retained[1386:14103] == text, 'review identity/offset'
    for finding in json.loads(CASE.read_text())['findings']:
        assert text[finding['start']+offset:finding['end']+offset] == finding['quote'], finding['id']


def verify_record(expected, actual, raw, line):
    for key in ('uuid', 'sessionId', 'parentUuid', 'timestamp'):
        assert expected[key] == actual[key], key
    assert expected['role'] == actual['message']['role'], 'speaker role'
    assert attribution(actual) == (expected['origin'], expected['author']), 'origin/author'
    assert not actual.get('isCompactSummary'), 'generated summary is not original'
    assert expected['lineOrdinal'] == line, 'line coordinate'
    assert expected['lineSha256'] == sha(raw), 'record integrity'
    text = extract(actual)
    assert expected['textSha256'] == sha(text.encode()), 'extracted text identity'
    assert expected['characters'] == len(text), 'character range'
    assert expected['octets'] == len(text.encode()), 'octet range'
    assert expected['body'] == 'not-published' and expected['decision'] is False
    if expected['ordinal'] == 8:
        assert any(b.get('name') == 'ExitPlanMode' for b in actual['message']['content'])
    if expected['ordinal'] == 20:
        assert all(value in text for value in ('d7215c50f4efa07b3e94749b060b7d7b828654f2a44caab7f1034415c6003dff',
                                              'ed37e9bac2fcd548', '11/18'))
    if expected['ordinal'] == 16:
        assert 'local-fedwiki-page' in text
    return text


def must_refuse(fn):
    try:
        fn()
    except (AssertionError, ValueError, KeyError, TypeError, UnicodeError):
        return
    raise AssertionError('mutation was accepted')


def verify_report(data, expected, message_text):
    """The SAME path verifies a real report and every mutation/404 counterprobe."""
    page = json.loads(data)
    items = [i for i in page['story'] if i['id'] == expected['itemId']]
    assert len(items) == 1, 'report item selection'
    value = items[0]['text'].encode()
    assert len(value) == expected['octets'], 'report octet count'
    assert sha(value) == expected['sha256'], 'report digest'
    assert value == message_text.encode(), 'report differs from ExitPlanMode plan'
    return len(value)


_PASTE_ATTRIBUTE = r'''[A-Za-z_:][A-Za-z0-9_.:-]*\s*=\s*(?:"[^"]*"|'[^']*')'''
_PASTE_TAG = re.compile(r'<(?P<close>/?)pasted_content(?P<attrs>(?:\s+' +
                        _PASTE_ATTRIBUTE + r')*)\s*>')
_ATTRIBUTE = re.compile(r'''([A-Za-z_:][A-Za-z0-9_.:-]*)\s*=\s*(["'])(.*?)\2''', re.DOTALL)


def has_pasted_wrapper(text):
    """Recognize paired transcript markers without changing the source text.

    Quoted attributes are allowed. The observed transcript repeats id="31d1"
    on its closing marker too: these are transcript markers, not XML end tags.
    A closing marker may omit attributes; supplied attributes must match.
    This format observation establishes no authorship.
    """
    stack = []
    for tag in _PASTE_TAG.finditer(text):
        pairs = [(m[1], m[3]) for m in _ATTRIBUTE.finditer(tag['attrs'])]
        attrs = dict(pairs)
        if len(attrs) != len(pairs):
            continue
        if not tag['close']:
            stack.append(attrs)
        elif stack:
            opening = stack.pop()
            if not attrs or attrs == opening:
                return True
    return False


def attribution(record):
    """Content format and envelope metadata do not authenticate a human author.
    Absence of a paste wrapper proves neither typing nor pasting.
    """
    if record['message']['role'] == 'user':
        return ('pasted-wrapper' if has_pasted_wrapper(extract(record)) else 'unwrapped',
                'not-recorded')
    content = record['message']['content']
    return ('tool-input:ExitPlanMode' if isinstance(content, list) and
            any(b.get('name') == 'ExitPlanMode' for b in content) else 'assistant-text',
            'agent-reported')


def verify(transcript=None, report=None):
    manifest = json.loads(MANIFEST.read_text())
    result = {'extractionRule': 'claude-code-jsonl/v1', 'privateBodiesRetained': False}
    texts = {}
    if transcript is None or not Path(transcript).is_file():
        result['originalTranscript'] = {'status': 'NOT-RUN', 'reason': 'Original transcript not supplied or unavailable.'}
    else:
        try:
            all_records = {}
            for n, raw in enumerate(Path(transcript).read_bytes().splitlines(keepends=True), 1):
                record = json.loads(raw)
                if 'uuid' in record:
                    assert record['uuid'] not in all_records, 'ambiguous UUID'
                    all_records[record['uuid']] = (record, raw, n)
            previous = None
            for expected in manifest['messages']:
                actual, raw, n = all_records[expected['uuid']]
                text = verify_record(expected, actual, raw, n)
                assert attribution(actual) == (expected['origin'], expected['author']), 'origin/author'
                if expected['role'] == 'user':
                    assert actual['origin']['kind'] == expected['sourceOriginKind'], 'origin kind'
                    assert actual['promptSource'] == expected['promptSource'], 'prompt source'
                start, end = expected['evidenceRange']
                assert 0 <= start < end <= len(text), 'evidence range'
                texts[expected['ordinal']] = text
                if previous:
                    cursor, visited = actual, set()
                    while cursor['uuid'] != previous['uuid']:
                        assert cursor['uuid'] not in visited, 'cyclic ancestry'
                        visited.add(cursor['uuid'])
                        cursor = all_records[cursor['parentUuid']][0]
                        assert cursor['sessionId'] == manifest['sessionId'], 'foreign parent'
                    assert previous['timestamp'] < actual['timestamp'], 'order'
                previous = actual
                bad = dict(actual, message=dict(actual['message'], role='user' if expected['role'] == 'assistant' else 'assistant'))
                must_refuse(lambda: verify_record(expected, bad, raw, n))
                must_refuse(lambda: verify_record(expected, actual, raw+b' ', n))
            verify_review(texts[2])
            must_refuse(lambda: verify_review(texts[2], -1385))
            must_refuse(lambda: verify_review('X'+texts[2][1:]))
            result['originalTranscript'] = {'status': 'PASS', 'messages': 4, 'selectedOrderAndAncestry': 'PASS',
                                            'originAndAuthorClassification': 'PASS',
                                            'reviewIdentityAnd11FindingOffsets': 'PASS', 'mutationControls': 10}
        except (AssertionError, ValueError, KeyError, TypeError, OSError, UnicodeError):
            result['originalTranscript'] = {'status': 'FAIL', 'reason': 'Original record, format, attribution or identity check failed.'}
            texts = {}
    if report is None or not Path(report).is_file():
        result['originalReportIdentity'] = {'status': 'NOT-RUN', 'reason': 'Local farm report JSON not supplied or unavailable.'}
    else:
        try:
            data = Path(report).read_bytes()
            # Validate supplied response format even if the transcript is unavailable.
            page = json.loads(data)
            assert isinstance(page, dict) and isinstance(page.get('story'), list), 'report page format'
            if 8 not in texts:
                result['originalReportIdentity'] = {'status': 'NOT-RUN', 'reason': 'Valid JSON supplied; original message #8 unavailable.'}
            else:
                count = verify_report(data, manifest['report'], texts[8])
                mutated = json.loads(data)
                next(i for i in mutated['story'] if i['id'] == manifest['report']['itemId'])['text'] += 'X'
                must_refuse(lambda: verify_report(json.dumps(mutated), manifest['report'], texts[8]))
                result['originalReportIdentity'] = {'status': 'PASS', 'octets': count, 'mutationControls': 1}
        except (AssertionError, ValueError, KeyError, TypeError, StopIteration, OSError, UnicodeError):
            result['originalReportIdentity'] = {'status': 'FAIL', 'reason': 'Supplied report is invalid JSON or fails source identity.'}
    assert extract({'message': {'content': '<pasted_content>example</pasted_content>'}}) == '<pasted_content>example</pasted_content>'
    assert extract({'message': {'content': [{'type': 'text', 'text': 'A'}, {'type': 'text', 'text': 'B'}]}}) == 'AB'
    result['syntheticExtractionChecks'] = 2
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--transcript')
    parser.add_argument('--report')
    args = parser.parse_args()
    result = verify(args.transcript, args.report)
    print(json.dumps(result, indent=2))
    raise SystemExit(1 if any(isinstance(v, dict) and v.get('status') == 'FAIL' for v in result.values()) else 0)
