--metadb:function impressao_pedidos_orders

DROP FUNCTION IF EXISTS impressao_pedidos_orders;

CREATE FUNCTION impressao_pedidos_orders(
    start_date   date DEFAULT '2020-01-01',
    end_date     date DEFAULT '2050-01-01',
    supplier     text DEFAULT '',
    order_status text DEFAULT ''
)
RETURNS TABLE (
    po_number               text,
    workflow_status         text,
    approved                int,
    manual_po               int,
    order_type              text,
    date_ordered            timestamptz,
    approval_date           timestamptz,
    po_line_number          text,
    receipt_status          text,
    payment_status          text,
    receipt_date            timestamptz,
    publisher               text,
    title_or_package        text,
    edition                 text,
    is_package              int,
    currency                text,
    quantity_physical       int,
    list_unit_price         numeric,
    po_line_estimated_price numeric,
    issn_isbn               text
)
AS $$
SELECT
    po.po_number As "Nr Ordem",
    po.approved "Estado da ordem",
    po.workflow_status "Estado do processo",
    po.manual_po "Ordem Manual",
    po.order_type as "Tipologia",
    po.date_ordered "Data da ordem",
    po.approval_date "Data de Aprovação",
    pol.po_line_number "Nr Linha",
    pol.receipt_status "Estado de entrega",
    pol.payment_status as "Estado do pagamento",
    pol.receipt_date "Data Recepção",
    pol.publisher as "Editor",
    pol.title_or_package as "Titulo",
    pol.edition As "Edição",
    pol.is_package As "Pacote",
    polj.jsonb -> 'cost' ->> 'currency'                             AS "Moeda",
    (polj.jsonb -> 'cost' ->> 'quantityPhysical')::int              AS "Quantidade",
    (polj.jsonb -> 'cost' ->> 'listUnitPrice')::numeric             AS "Preço unitário",
    (polj.jsonb -> 'cost' ->> 'poLineEstimatedPrice')::numeric      AS "Total estimado",
    polj.jsonb -> 'details' -> 'productIds' -> 0 ->> 'productId'    AS "ISSN/ISBN"
FROM folio_orders.purchase_order__t__ po
LEFT JOIN folio_orders.po_line__t__             pol  ON pol.purchase_order_id = po.id
LEFT JOIN folio_orders.po_line__                polj ON polj.id = pol.id
                                                     AND polj.__current
LEFT JOIN folio_organizations.organizations__t__ org  ON org.id = po.vendor
                                                      AND org.__current
WHERE po.__current
  AND pol.__current
  AND po.date_ordered::date BETWEEN start_date AND end_date
  AND (order_status = '' OR po.approved LIKE '%' || order_status || '%' )
  AND (supplier     = '' OR org.name LIKE '%' || supplier || '%')
order by po.po_number desc
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;