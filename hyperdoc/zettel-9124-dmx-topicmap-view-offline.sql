SELECT local_id, type_uri, value
FROM dmx_sql_object
WHERE object_kind = 'topic'
  AND (local_id LIKE 'plan:zettel-9124-pdf-reading%'
       OR local_id LIKE 'episode:zettel-9124%'
       OR local_id LIKE 'concept:how-to-read-a-web%'
       OR local_id LIKE 'store:dmx-sqlite%'
       OR local_id LIKE 'bridge:live-lisp%'
       OR local_id LIKE 'shop3:function:%')
ORDER BY local_id;
SELECT a.local_id, a.type_uri, p1.player_local_id, p2.player_local_id
FROM dmx_sql_object a
JOIN dmx_sql_assoc_player p1
  ON p1.assoc_id = a.local_id AND p1.player_no = 1
JOIN dmx_sql_assoc_player p2
  ON p2.assoc_id = a.local_id AND p2.player_no = 2
WHERE a.object_kind = 'assoc'
  AND (a.local_id LIKE 'assoc:pdf-reading-plan:%'
       OR a.local_id = 'assoc:live-lisp:mirrors-to:dmx-sqlite')
ORDER BY a.local_id;