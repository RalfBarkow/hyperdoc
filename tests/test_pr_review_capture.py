"""Focused explicit-import boundary tests. No remote API is contacted."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('capture', ROOT / 'scripts/capture-pr-review.py')
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


class CaptureBoundary(unittest.TestCase):
    def test_pagination_includes_all_pages(self):
        with patch.object(subprocess, 'check_output', return_value='[{"number":1}]\n[{"number":2}]') as call:
            self.assertEqual([1, 2], [p['number'] for p in capture.get('example', pages=True)])
            self.assertIn('--paginate', call.call_args.args[0])
            self.assertNotIn('--method', call.call_args.args[0])

    def test_blank_success_is_not_an_empty_list(self):
        with patch.object(subprocess, 'check_output', return_value='  '):
            with self.assertRaises(ValueError):
                capture.get('example', pages=True)

    def test_bad_page_shape_is_refused(self):
        with patch.object(subprocess, 'check_output', return_value='{"error":"fixture"}'):
            with self.assertRaises(ValueError):
                capture.get('example', pages=True)

    def test_unavailable_capture_preserves_previous_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'snapshot.json'
            output.write_text('previous observation')
            with patch('sys.argv', ['capture', '--output', str(output)]), \
                 patch.object(capture, 'get', side_effect=subprocess.CalledProcessError(1, 'fixture')):
                with self.assertRaises(subprocess.CalledProcessError):
                    capture.main()
            self.assertEqual('previous observation', output.read_text())

    def test_zero_prs_is_a_successful_available_observation(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'snapshot.json'
            with patch('sys.argv', ['capture', '--output', str(output)]), \
                 patch.object(capture, 'get', side_effect=[{'id': 1, 'full_name': capture.REPO}, []]):
                capture.main()
            value = json.loads(output.read_text())
            self.assertEqual('available', value['status'])
            self.assertEqual([], value['pullRequests'])

    def test_changed_head_or_state_cannot_replace_snapshot(self):
        snapshot = json.loads((ROOT / 'dreyeck/pr-review/example/github-snapshot.json').read_text())
        pr = snapshot['pullRequests'][0]
        for state in ['open', 'closed']:
            detail = {**pr, 'state': state}
            responses = [{'id': 1, 'full_name': capture.REPO}, [{'number': pr['number']}], detail]
            if state == 'open':
                responses.append([{'sha': 'different-head'}])
            with self.subTest(state=state), tempfile.TemporaryDirectory() as directory:
                output = Path(directory) / 'snapshot.json'
                output.write_text('previous observation')
                with patch('sys.argv', ['capture', '--output', str(output)]), \
                     patch.object(capture, 'get', side_effect=responses):
                    with self.assertRaises(RuntimeError):
                        capture.main()
                self.assertEqual('previous observation', output.read_text())

if __name__ == '__main__':
    unittest.main()
