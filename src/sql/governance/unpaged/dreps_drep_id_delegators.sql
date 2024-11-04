WITH current_epoch AS (
  SELECT b.epoch_no
  FROM block b
  ORDER BY b.id DESC
  LIMIT 1
),
-- This new CTE ensures that only active delegators are included by filtering out 
-- any addresses with a more recent stake_deregistration than stake_registration.
active_delegators AS (
  SELECT sa.view AS "address",
    dv.addr_id AS "address_id",
    dv.id AS "did"
  FROM delegation_vote dv
    JOIN drep_hash dh ON (dh.id = dv.drep_hash_id)
    JOIN stake_address sa ON (sa.id = dv.addr_id)
    JOIN stake_registration sr ON sr.addr_id = dv.addr_id
    LEFT JOIN stake_deregistration sd ON sd.addr_id = dv.addr_id
  WHERE (
      ($4::bytea IS NOT NULL AND dh.raw = $4) OR
      ($4 IS NULL AND dh.view = $5)
    )
    AND dv.id = (
      SELECT MAX(dv_inner.id)
      FROM delegation_vote dv_inner
      WHERE dv_inner.addr_id = dv.addr_id
    )
    AND sr.tx_id > COALESCE((SELECT MAX(sd_inner.tx_id) FROM stake_deregistration sd_inner WHERE sd_inner.addr_id = dv.addr_id), 0)
  GROUP BY sa.view, dv.drep_hash_id, dv.addr_id, dv.id
)
SELECT "address" AS "address",
  (
    (
      SELECT COALESCE(SUM(txo.value), 0)
      FROM tx_out txo
        LEFT JOIN tx_in txi ON (txo.tx_id = txi.tx_out_id)
        AND (txo.index = txi.tx_out_index)
      WHERE txi IS NULL
        AND txo.stake_address_id = address_id
    ) + (
      SELECT COALESCE(SUM(amount), 0)
      FROM reward r
      WHERE (r.addr_id = address_id)
        AND r.spendable_epoch <= (
          SELECT *
          FROM current_epoch
        )
    ) + (
      SELECT COALESCE(SUM(amount), 0)
      FROM reward_rest rr
      WHERE (rr.addr_id = address_id)
        AND rr.spendable_epoch <= (
          SELECT *
          FROM current_epoch
        )
    ) - (
      SELECT COALESCE(SUM(amount), 0)
      FROM withdrawal w
      WHERE (w.addr_id = address_id)
    )
  )::TEXT AS "amount" -- cast to TEXT to avoid number overflow
FROM 
  active_delegators
ORDER BY CASE
    WHEN LOWER($1) = 'desc' THEN did
  END DESC,
  CASE
    WHEN LOWER($1) <> 'desc'
    OR $1 IS NULL THEN did
  END ASC
