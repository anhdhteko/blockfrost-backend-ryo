SELECT encode(tx.hash, 'hex')   AS "txHash",
        b.epoch_no              AS "epochNum",
        block_no                AS "blockHeight",
        extract(
            epoch
            FROM b.time
        )::INTEGER              AS "blockTime",
        b.slot_no               AS "slot",
        tx.fee::TEXT            AS "fees",        -- cast to TEXT to avoid number overflow
        tx.out_sum::TEXT        AS "totalOutput" -- cast to TEXT to avoid number overflow
FROM tx
        JOIN block b ON (tx.block_id = b.id)
ORDER BY tx.id DESC
LIMIT $1 OFFSET $2;
