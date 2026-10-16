"""Synthetic gate; original private sources remain optional and NOT-RUN by default."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/verify-conversation-sources.py'
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('sources', SCRIPT)
v = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v)


class SourceContracts(unittest.TestCase):
    def setUp(self):
        self.page = {'story': [{'id': 'fixture', 'text': 'Synthetic plan only'}]}
        self.expected = {'itemId': 'fixture', 'octets': 19, 'sha256': v.sha(b'Synthetic plan only')}

    def test_actual_report_path(self):
        self.assertEqual(19, v.verify_report(json.dumps(self.page), self.expected, 'Synthetic plan only'))
        bad = copy.deepcopy(self.page)
        bad['story'][0]['text'] += 'X'
        with self.assertRaises(AssertionError):
            v.verify_report(json.dumps(bad), self.expected, 'Synthetic plan only')

    def test_wrong_item_and_duplicate(self):
        for page in [{'story': []}, {'story': self.page['story'] * 2}]:
            with self.assertRaises(AssertionError):
                v.verify_report(json.dumps(page), self.expected, 'Synthetic plan only')

    def test_equal_hash_not_wrong_message(self):
        with self.assertRaises(AssertionError):
            v.verify_report(json.dumps(self.page), self.expected, 'Other message')

    def test_404_and_non_json_have_structured_failure(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'response'
            for value in [b'<html>404 Page not found</html>', b'{', b'\xff', b'null', b'[]']:
                p.write_bytes(value)
                result = subprocess.run([sys.executable, str(SCRIPT), '--report', str(p)], capture_output=True, text=True)
                self.assertEqual(1, result.returncode, result.stderr)
                self.assertEqual('FAIL', json.loads(result.stdout)['originalReportIdentity']['status'])
                self.assertNotIn('Traceback', result.stderr)

    def test_bad_transcript(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'response'
            p.write_text('not json')
            self.assertEqual('FAIL', v.verify(transcript=p)['originalTranscript']['status'])

    def test_missing_originals_are_not_run(self):
        r = v.verify()
        self.assertEqual('NOT-RUN', r['originalTranscript']['status'])
        self.assertEqual('NOT-RUN', r['originalReportIdentity']['status'])

    def test_unwrapped_does_not_prove_typed_or_pasted_authorship(self):
        for t in ['Synthetic short input', '<pasted_content>Fixture</pasted_content>']:
            r = {'message': {'role': 'user', 'content': t}, 'origin': {'kind': 'human'}}
            self.assertEqual('not-recorded', v.attribution(r)[1])
        self.assertEqual('unwrapped', v.attribution({'message': {'role': 'user', 'content': 'Short'}})[0])

    def test_observed_attributed_paste_markers(self):
        # Exact marker form observed in #20, with a synthetic body only.
        text = '\n\n<pasted_content id="31d1">Fixture</pasted_content id="31d1">\n'
        record = {'message': {'role': 'user', 'content': text}}
        self.assertEqual(('pasted-wrapper', 'not-recorded'), v.attribution(record))
        self.assertEqual(text, v.extract(record))

    def test_paste_marker_structure(self):
        for text in ['<pasted_content>Fixture</pasted_content>',
                     '<pasted_content id="31d1">Fixture</pasted_content>',
                     "<pasted_content id = '31d1' source=\"fixture\">Fixture</pasted_content source='fixture' id=\"31d1\">",
                     '<pasted_content\n id="31d1">Fixture</pasted_content>']:
            with self.subTest(text=text):
                self.assertEqual(('pasted-wrapper', 'not-recorded'), v.attribution(
                    {'message': {'role': 'user', 'content': text}}))
        for text in ['Fixture', '<pasted_contents>Fixture</pasted_contents>',
                     '&lt;pasted_content&gt;Fixture&lt;/pasted_content&gt;',
                     '<pasted_content id="31d1">Fixture', '</pasted_content>',
                     '<pasted_content id="31d1">Fixture</pasted_content id="other">',
                     '<pasted_content id=31d1>Fixture</pasted_content>']:
            with self.subTest(text=text):
                self.assertEqual('unwrapped', v.attribution(
                    {'message': {'role': 'user', 'content': text}})[0])


if __name__ == '__main__':
    unittest.main()
