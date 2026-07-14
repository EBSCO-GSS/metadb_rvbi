--metadb:function consulta_local

DROP FUNCTION IF EXISTS consulta_local;

CREATE FUNCTION consulta_local(
    start_date    date DEFAULT '2020-01-01',
    end_date      date DEFAULT '2050-01-01',
    service_point text DEFAULT ''
)
RETURNS TABLE (
    "Data Empréstimo"  timestamptz,
    "Data Devolução"   timestamptz,
    "Código de Barras" text,
    "Cópia"            text,
    "Call Number"      text,
    "Título"           text,
    "Código PS"        text,
    "Nome PS"          text
)
AS $$
SELECT
    lt.loan_date,
    cl."date",
    clj.jsonb -> 'items' -> 0 ->> 'itemBarcode',
    it.copy_number,
    it.effective_shelving_order,
    ins.title,
    spt.code,
    spt.discovery_display_name
FROM folio_audit.circulation_logs__t__          cl
LEFT JOIN folio_audit.circulation_logs__        clj ON clj.id  = cl.id
                                                    AND clj.__current
LEFT JOIN folio_circulation.loan__t__           lt  ON lt.id   = (clj.jsonb -> 'items' -> 0 ->> 'loanId')::uuid
                                                    AND lt.__current
LEFT JOIN folio_inventory.item__t__             it  ON it.id   = (clj.jsonb -> 'items' -> 0 ->> 'itemId')::uuid
                                                    AND it.__current
LEFT JOIN folio_inventory.instance__t__         ins ON ins.id  = (clj.jsonb -> 'items' -> 0 ->> 'instanceId')::uuid
                                                    AND ins.__current
LEFT JOIN folio_inventory.service_point__t__    spt ON spt.id  = cl.service_point_id
                                                    AND spt.__current
WHERE cl.__current
  AND cl.action       = 'Checked in'
  AND cl.user_barcode IS NULL
  AND cl."date"::date BETWEEN start_date AND end_date
  AND (service_point  = '' OR spt.code LIKE '%' || service_point || '%')
ORDER BY cl."date" DESC
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;