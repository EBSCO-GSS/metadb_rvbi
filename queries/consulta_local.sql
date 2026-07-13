--metadb:function consulta_local

DROP FUNCTION IF EXISTS consulta_local;

CREATE FUNCTION consulta_local(
    start_date    date DEFAULT '2020-01-01',
    end_date      date DEFAULT '2050-01-01',
    service_point text DEFAULT ''
)
RETURNS TABLE (
    loan_date                timestamptz,
    return_date              timestamptz,
    barcode                  text,
    copy_number              text,
    effective_shelving_order text,
    title                    text,
    code                     text,
    discovery_display_name   text
)
AS $$
SELECT
    lt.loan_date as "Data empréstimo",
    lt.return_date as "Data devolução",
    it.barcode as "Código barras",
    it.copy_number  as "Cópia",
    it.effective_shelving_order  as "Call number",
    it2.title  as "Título",
    spt.code  as "Código PS",
    spt.discovery_display_name  as "Nome PS"
FROM folio_circulation.loan__t__                lt
LEFT JOIN  folio_inventory.item__t__            it  ON it.id  = lt.item_id
                                                    AND it.__current
INNER JOIN folio_inventory.holdings_record__t__ hrt ON hrt.id = it.holdings_record_id
                                                    AND hrt.__current
INNER JOIN folio_inventory.instance__t__        it2 ON it2.id = hrt.instance_id
                                                    AND it2.__current
LEFT JOIN  folio_inventory.service_point__t__   spt ON spt.id = lt.checkin_service_point_id
                                                    AND spt.__current
WHERE lt.__current
  AND lt.user_id IS NULL
  AND lt.action IN ('checkedin', 'closedLoan')
  AND lt.loan_date::date BETWEEN start_date AND end_date
  AND (service_point = '' OR spt.code ILIKE '%' || service_point || '%')
ORDER BY lt.loan_date DESC, it.barcode
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;