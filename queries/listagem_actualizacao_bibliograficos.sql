--metadb:function listagem_actualizacao_bibliograficos

DROP FUNCTION IF EXISTS listagem_actualizacao_bibliograficos;

CREATE FUNCTION listagem_actualizacao_bibliograficos(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    hrid,
    titulo,
    data_actualizacao,
    timestamp_actualizacao,
    IDUsuarioCriador,
    CodigoUsuario,
    NomeUsuario,
    GrupoUsuario
    )
AS $$

SELECT
    i.jsonb->>'hrid'  AS hrid,
    i.jsonb->>'title' AS title,
    to_char((i.jsonb->'metadata'->>'updatedDate')::date, 'YYYY-MM-DD') AS data_actualizacao,
    (i.jsonb->'metadata'->>'updatedDate')::timestamptz AS timestamp_actualizacao,
    u.id AS userid,
    u.jsonb->>'username' AS username,
    concat_ws(' ',
        u.jsonb->'personal'->>'firstName',
        u.jsonb->'personal'->>'lastName') AS usuario,
    g.desc AS GrupoUsuario
FROM folio_inventory.instance__ i
LEFT JOIN folio_users.users__ u
       ON u.id = (i.jsonb->'metadata'->>'updatedByUserId')::uuid
      AND u.__current
LEFT JOIN folio_users.groups__t__ g
       ON g.id = (u.jsonb->>'patronGroup')::uuid
      AND g.__current
WHERE (i.jsonb->'metadata'->>'updatedDate')::date BETWEEN start_date AND end_date
  AND i.__current
ORDER BY timestamp_actualizacao DESC, usuario

$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;

