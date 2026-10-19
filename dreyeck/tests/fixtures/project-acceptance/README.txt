SYNTHETIC test fixtures for dreyeck/tests/project-ctm.lisp (acceptance tests). Nothing here is a source of the project CTM,
and nothing here was decided by anyone: every identifier starts with "synthetic-", and the dates are in the year 2000.

synthetic-work.html                    declares synthetic-wp-1, -2 and -3 (a Work source of the tests)
synthetic-dictionary-c1.html           a declared WBS Dictionary: synthetic-wp-1 with criterion C1 (30 s), synthetic-wp-2
synthetic-dictionary-c2.html           the same dictionary after the criterion changed: C2 (10 s), C1 retained
synthetic-second-dictionary.html       a second declared WBS Dictionary: synthetic-wp-3
synthetic-proposed-dictionary.html     a draft dictionary for the proposed synthetic-wp-p
synthetic-assignments-addition.html    appended to Implementation Assignments: the proposal synthetic-wp-p and synthetic-assignment-1
                                       with identified evidence entries (execution reports and a note) and unidentified notes
synthetic-records-s1.html              record 1 accepts synthetic-wp-1 against C1; record 3 accepts synthetic-wp-3
synthetic-records-s3.html              s1, then record 2 rejects synthetic-wp-1 against C2 and supersedes record 1
synthetic-records-conflict.html        s1, then record 2 rejects without superseding: two unsuperseded records
synthetic-records-withdrawn.html       s1, then a withdrawal supersedes record 1
synthetic-records-withdrawal-conflict.html  s3, then a withdrawal also supersedes record 1: record 2 and the withdrawal compete

Each records page is the previous one with records appended, as an Acceptance Records page grows. The refusals are derived from
these pages in the test file, one changed attribute or section each.
