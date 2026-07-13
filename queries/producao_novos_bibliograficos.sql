--metadb:function producao_novos_bibliograficos

DROP FUNCTION IF EXISTS producao_novos_bibliograficos;

CREATE FUNCTION producao_novos_bibliograficos(
    start_date date DEFAULT '2020-01-01',
    end_date date DEFAULT '2050-01-01'
)
RETURNS TABLE(
    Usuario text,
    Ano_Mes text,
    Total text)
AS $$
SELECT 
    COALESCE(
        (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')),
        'TOTAL'
    ) AS Usuario,
    COALESCE(
        to_char(
            date_trunc('month', (i.jsonb->'metadata'->>'createdDate')::date),
            'YYYY-MM'
        ),
        'SUBTOTAL'
    ) AS Ano_Mes,
    COUNT(*) AS Total
FROM folio_inventory.instance__ i
LEFT JOIN folio_users.users__ u
       ON u.id = (i.jsonb->'metadata'->>'createdByUserId')::uuid
WHERE (i.jsonb->'metadata'->>'createdDate')::date BETWEEN start_date AND end_date
  AND i.__current 
  AND u.__current 
GROUP BY ROLLUP(
    (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')),
    to_char(
        date_trunc('month', (i.jsonb->'metadata'->>'createdDate')::date),
        'YYYY-MM'
    )
)
ORDER BY 
    CASE WHEN (u.jsonb->'personal'->>'firstName' || ' ' || (u.jsonb->'personal'->>'lastName')) IS NULL THEN 2
         WHEN to_char(date_trunc('month', (i.jsonb->'metadata'->>'createdDate')::date), 'YYYY-MM') IS NULL THEN 1
         ELSE 0 
    END,
    Ano_Mes DESC,
    Usuario;
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;


