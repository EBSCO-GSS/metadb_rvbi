--metadb:function listagem_actualizacao_bibliograficos

DROP FUNCTION IF EXISTS listagem_actualizacao_bibliograficos(date, date);

CREATE FUNCTION listagem_actualizacao_bibliograficos(
    start_date date DEFAULT '2020-01-01',
    end_date   date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    hrid                    text,
    titulo                  text,
    data_actualizacao       text,
    timestamp_actualizacao  timestamptz,
    idusuariocriador        uuid,
    codigousuario           text,
    nomeusuario             text,
    grupousuario            text
)
AS $$

SELECT
    i.jsonb->>'hrid',
    i.jsonb->>'title',
    to_char((i.jsonb->'metadata'->>'updatedDate')::date, 'YYYY-MM-DD'),
    (i.jsonb->'metadata'->>'updatedDate')::timestamptz,
    u.id,
    u.jsonb->>'username',
    concat_ws(' ',
        u.jsonb->'personal'->>'firstName',
        u.jsonb->'personal'->>'lastName'),
    g.desc
FROM folio_inventory.instance__ i
LEFT JOIN folio_users.users__ u
       ON u.id = (i.jsonb->'metadata'->>'updatedByUserId')::uuid
      AND u.__current
LEFT JOIN folio_users.groups__t__ g
       ON g.id = (u.jsonb->>'patronGroup')::uuid
      AND g.__current
WHERE (i.jsonb->'metadata'->>'updatedDate')::date BETWEEN start_date AND end_date
  AND i.__current
ORDER BY
    (i.jsonb->'metadata'->>'updatedDate')::timestamptz DESC,
    concat_ws(' ',
        u.jsonb->'personal'->>'firstName',
        u.jsonb->'personal'->>'lastName')

$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;