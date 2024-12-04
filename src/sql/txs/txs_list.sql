SELECT encode(tx.hash, 'hex')   AS "tx_hash",
        b.epoch_no              AS "epoch_num",
        block_no                AS "block_height",
        extract(
            epoch
            FROM b.time
        )::INTEGER              AS "block_time",
        b.slot_no               AS "slot",
        tx.fee::TEXT            AS "fees",        -- cast to TEXT to avoid number overflow
        tx.out_sum::TEXT        AS "total_output" -- cast to TEXT to avoid number overflow
FROM tx
        JOIN block b ON (tx.block_id = b.id)
ORDER BY tx.id DESC
LIMIT $1 OFFSET $2;
