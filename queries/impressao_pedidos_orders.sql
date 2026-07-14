--metadb:function impressao_pedidos_orders

DROP FUNCTION IF EXISTS impressao_pedidos_orders;

CREATE FUNCTION impressao_pedidos_orders(
    start_date   date DEFAULT '2020-01-01',
    end_date     date DEFAULT '2050-01-01',
    supplier     text DEFAULT '',
    order_status text DEFAULT ''
)
RETURNS TABLE (
    "Nr Ordem"           text,
    "Aprovado"           boolean,
    "Estado do Processo" text,
    "Ordem Manual"       boolean,
    "Tipologia"          text,
    "Data da Ordem"      timestamptz,
    "Data de Aprovação"  timestamptz,
    "Nr Linha"           text,
    "Estado de Entrega"  text,
    "Estado Pagamento"   text,
    "Data de Recepção"   timestamptz,
    "Editor"             text,
    "Título"             text,
    "Edição"             text,
    "Pacote"             boolean,
    "Moeda"              text,
    "Quantidade"         int,
    "Preço Unitário"     numeric,
    "Desconto"     numeric,
    "Total Estimado"     numeric,
    "ISSN/ISBN"          text
)
AS $$
SELECT
    po.po_number,
    po.approved,
    po.workflow_status,
    po.manual_po,
    po.order_type,
    po.date_ordered,
    po.approval_date,
    pol.po_line_number,
    pol.receipt_status,
    pol.payment_status,
    pol.receipt_date,
    pol.publisher,
    pol.title_or_package,
    pol.edition,
    pol.is_package,
    polj.jsonb -> 'cost' ->> 'currency',
    (polj.jsonb -> 'cost' ->> 'quantityPhysical')::int,
    (polj.jsonb -> 'cost' ->> 'listUnitPrice')::numeric,
    (polj.jsonb -> 'cost' ->> 'discount')::numeric,

    (polj.jsonb -> 'cost' ->> 'poLineEstimatedPrice')::numeric,
    polj.jsonb -> 'details' -> 'productIds' -> 0 ->> 'productId'
FROM folio_orders.purchase_order__t__ po
LEFT JOIN folio_orders.po_line__t__              pol  ON pol.purchase_order_id = po.id
LEFT JOIN folio_orders.po_line__                 polj ON polj.id = pol.id
                                                      AND polj.__current
LEFT JOIN folio_organizations.organizations__t__ org  ON org.id = po.vendor
                                                      AND org.__current
WHERE po.__current
  AND pol.__current
  AND po.date_ordered::date BETWEEN start_date AND end_date
  AND (order_status = '' OR po.workflow_status LIKE '%' || order_status || '%')
  AND (supplier     = '' OR org.name           LIKE '%' || supplier    || '%')
ORDER BY po.po_number DESC, pol.po_line_number
$$
LANGUAGE SQL
STABLE
PARALLEL SAFE;