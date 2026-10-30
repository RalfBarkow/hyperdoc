#!/usr/bin/env python3
"""Explicit trusted GitHub GET capture; no refresh code is part of the Lisp Reading."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess

REPO = 'RalfBarkow/hyperdoc'

def get(path, pages=False):
    args = ['gh', 'api', path]
    if pages:
        args += ['--paginate']
    raw = subprocess.check_output(args, text=True)
    if not raw.strip():
        raise ValueError("Empty response is not an empty PR list")
    if not pages:
        return json.loads(raw)
    # gh versions without --slurp emit concatenated page arrays.
    decoder, result = json.JSONDecoder(), []
    remaining = raw.lstrip()
    while remaining:
        page, end = decoder.raw_decode(remaining)
        if not isinstance(page, list):
            raise ValueError('Expected a paginated array')
        result.extend(page)
        remaining = remaining[end:].lstrip()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--issue', type=int, action='append', default=[])
    args = parser.parse_args()
    repository = get('repos/' + REPO)
    if repository['full_name'] != REPO:
        raise ValueError('Unexpected repository authority')
    pulls = get('repos/' + REPO + '/pulls?state=open&per_page=100', pages=True)
    records = []
    for item in pulls:
        number = item['number']
        pr = get(f'repos/{REPO}/pulls/{number}')
        if pr['state'] != 'open':
            raise RuntimeError('PR changed state during capture; preserve the previous snapshot')
        commits = get(f'repos/{REPO}/pulls/{number}/commits?per_page=100', pages=True)
        if not commits or commits[-1]['sha'] != pr['head']['sha']:
            raise RuntimeError('Revision changed or commit listing incomplete; preserve the previous snapshot')
        records.append({key: pr[key] for key in ('number', 'title', 'body', 'html_url', 'state', 'draft', 'updated_at')})
        record = records[-1]
        for side in ('base', 'head'):
            source = pr[side]
            record[side] = {'ref': source['ref'], 'sha': source['sha'],
                            'repository': source['repo']['full_name'] if source['repo'] else None}
        record['commits'] = [{'sha': c['sha'], 'html_url': c['html_url'],
                              'message': c['commit']['message']} for c in commits]
    issues = []
    for number in args.issue:
        issue = get(f'repos/{REPO}/issues/{number}')
        if 'pull_request' in issue:
            raise ValueError('--issue must identify an Issue, not a pull request')
        issues.append({key: issue[key] for key in ('number', 'title', 'body', 'html_url', 'state', 'updated_at')})
    snapshot = {'schemaVersion': 1, 'repository': {'id': repository['id'], 'fullName': repository['full_name']},
                'observedAt': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                'sourceURL': f'https://api.github.com/repos/{REPO}/pulls?state=open&per_page=100',
                'selection': 'open', 'status': 'available', 'pullRequests': records, 'issues': issues,
                'capturePolicy': 'Explicit GET-only, paginated; non-atomic multi-request observation; no headers or credentials retained.'}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # Write only a completed capture. Failures do not replace a prior snapshot with an empty list.
    temporary = args.output.with_suffix(args.output.suffix + '.tmp')
    temporary.write_text(json.dumps(snapshot, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(args.output)
    print(f'Captured {len(records)} open PRs and {len(issues)} Issues at {snapshot["observedAt"]}')

if __name__ == '__main__':
    main()
