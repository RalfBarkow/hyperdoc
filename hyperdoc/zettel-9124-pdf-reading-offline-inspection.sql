SELECT local_id, type_uri, value
FROM dmx_sql_object
WHERE local_id LIKE 'plan:zettel-9124-pdf-reading%'
   OR local_id LIKE 'episode:zettel-9124%'
   OR local_id LIKE 'concept:how-to-read-a-web%'
   OR local_id LIKE 'bridge:live-lisp%'
   OR local_id LIKE 'shop3:function:%'
ORDER BY object_kind, local_id;

SELECT a.local_id AS assoc_id,
       a.type_uri AS assoc_type,
       p1.player_local_id AS from_topic,
       p2.player_local_id AS to_topic
FROM dmx_sql_object a
JOIN dmx_sql_assoc_player p1
  ON p1.assoc_id = a.local_id AND p1.player_no = 1
JOIN dmx_sql_assoc_player p2
  ON p2.assoc_id = a.local_id AND p2.player_no = 2
WHERE a.object_kind = 'assoc'
  AND a.local_id LIKE 'assoc:pdf-reading-plan:%'
ORDER BY a.local_id;