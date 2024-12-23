WITH queried_epoch AS (
  SELECT no AS "epoch_no"
  FROM epoch e
  ORDER BY e.no DESC
  LIMIT 1
)
SELECT dh.view AS "drep_id",
  encode(dh.raw, 'hex') AS "hex",
  COALESCE(dd.amount, 0)::TEXT AS "amount",
  -- TODO ???
  (
    CASE
      WHEN dr.deposit >= 0 THEN true
      ELSE false
    END
  ) AS "active",
  (
    CASE
      WHEN dr.deposit >= 0 THEN (
        SELECT b.epoch_no
        FROM block b
        WHERE b.id = (
            SELECT tx.block_id
            FROM tx
            WHERE tx.id = (dr.tx_id)
          )
      )
      ELSE NULL
    END
  ) AS "active_epoch",
  dh.has_script AS "has_script"
FROM drep_hash dh
  LEFT JOIN drep_registration dr ON (dh.id = dr.drep_hash_id) --TODO voting power
  LEFT JOIN drep_distr dd ON (
    dh.id = dd.hash_id
    AND dd.epoch_no = (
      SELECT *
      FROM queried_epoch
    )
  )
WHERE (
    ($1::bytea IS NOT NULL AND dh.raw = $1) OR
    ($1 IS NULL AND dh.view = $2)
  ) AND dh.has_script = $3
ORDER BY (tx_id, cert_index) DESC
LIMIT 1