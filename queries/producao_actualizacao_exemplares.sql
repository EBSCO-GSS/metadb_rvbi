--metadb:function producao_actualizacao_exemplares
DROP FUNCTION IF EXISTS producao_actualizacao_exemplares;

CREATE FUNCTION producao_actualizacao_exemplares(
    start_date date DEFAULT '2000-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Usuario text,
    AnoMes text,
    Total text)
AS $$
SELECT 
    COALESCE(
        (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')),
        'TOTAL'
    ) AS Usuario,
    COALESCE(
        to_char(
            date_trunc('month', (i.jsonb->'metadata'->>'updatedDate')::date),
            'YYYY-MM'
        ),
        'SUBTOTAL'
    ) AS AnoMes,
    COUNT(DISTINCT i.id) AS Total
FROM folio_inventory.item__ i
LEFT JOIN folio_users.users__ u
       ON u.id = (i.jsonb->'metadata'->>'updatedByUserId')::uuid
WHERE (i.jsonb->'metadata'->>'updatedDate') IS NOT NULL
  AND (i.jsonb->'metadata'->>'updatedDate')::date BETWEEN start_date AND end_date
  AND u.__current
GROUP BY ROLLUP(
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')),
    to_char(
        date_trunc('month', (i.jsonb->'metadata'->>'updatedDate')::date),
        'YYYY-MM'
    )
)
ORDER BY 
    CASE WHEN (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) IS NULL THEN 2
         WHEN to_char(date_trunc('month', (i.jsonb->'metadata'->>'updatedDate')::date), 'YYYY-MM') IS NULL THEN 1
         ELSE 0 
    END,
    AnoMes DESC,
    Usuario;
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;


