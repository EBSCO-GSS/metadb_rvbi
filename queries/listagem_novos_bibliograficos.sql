--metadb:function listagem_novos_bibliograficos

DROP FUNCTION IF EXISTS listagem_novos_bibliograficos;

CREATE FUNCTION listagem_novos_bibliograficos(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    hrid,
    titulo,
    data_criacao,
    timestamp_criacao,
    IDUsuarioCriador,
    CodigoUsuario,
    NomeUsuario,
    GrupoUsuario
    )
AS $$

SELECT
    i.jsonb->>'hrid'  AS hrid,
    i.jsonb->>'title' AS title,
    to_char((i.jsonb->'metadata'->>'createdDate')::date, 'YYYY-MM-DD') AS data_criacao,
    (i.jsonb->'metadata'->>'createdDate')::timestamptz AS timestamp_criacao,
    u.id AS userid,
    u.jsonb->>'username' AS username,
    concat_ws(' ',
        u.jsonb->'personal'->>'firstName',
        u.jsonb->'personal'->>'lastName') AS usuario,
    g.desc AS GrupoUsuario
FROM folio_inventory.instance__ i
LEFT JOIN folio_users.users__ u
       ON u.id = (i.jsonb->'metadata'->>'createdByUserId')::uuid
      AND u.__current
LEFT JOIN folio_users.groups__t__ g
       ON g.id = (u.jsonb->>'patronGroup')::uuid
      AND g.__current
WHERE (i.jsonb->'metadata'->>'createdDate')::date BETWEEN start_date AND end_date
  AND i.__current
ORDER BY timestamp_criacao DESC, usuario

$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;


