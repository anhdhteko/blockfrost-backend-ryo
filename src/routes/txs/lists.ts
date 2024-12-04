import { FastifyInstance, FastifyRequest } from 'fastify';

import { SQLQuery } from '../../sql/index.js';
import * as QueryTypes from '../../types/queries/tx.js';
import * as ResponseTypes from '../../types/openapi-wrapper.js';
import { getDbSync, gracefulRelease } from '../../utils/database.js';

function convertSnakeToCamelCase(rows: ResponseTypes.TxSimple[]) {
  return rows.map(row => {
    return {
      txHash: row.tx_hash,
      epochNum: row.epoch_num,
      blockHeight: row.block_height,
      blockTime: row.block_time,
      slot: row.slot,
      fees: row.fees,
      outputAmount: row.output_amount,
    };
  });
}

async function route(fastify: FastifyInstance) {
  fastify.route({
    url: '/txs',
    method: 'GET',
    schema: {},
    handler: async (request: FastifyRequest<QueryTypes.RequestTxsQueryParameters>, reply) => {
      const clientDbSync = await getDbSync(fastify);

      try {
        const offset = (request.query.page - 1) * request.query.pageSize;
        const { rows }: { rows: ResponseTypes.TxSimple[] } =
          await clientDbSync.query<QueryTypes.TxSimple>(SQLQuery.get('txs_list'), [
            request.query.pageSize,
            offset,
          ]);

        const query_total = await clientDbSync.query<QueryTypes.ResultFound>(
          SQLQuery.get('txs_list_count'),
        );

        const total = query_total.rows[0].result;

        return reply.send({
          code: 200,
          message: 'OK',
          data: {
            pagination: {
              page: request.query.page,
              pageSize: request.query.pageSize,
              total: total,
            },
            transactions: convertSnakeToCamelCase(rows),
          },
        });
      } catch (error) {
        gracefulRelease(clientDbSync);
        throw error;
      }
    },
  });
}

export default route;
