import { components, paths } from '@blockfrost/openapi';

// Health responses don't have standalone components in openapi package.
// We pick the types manually and add it to the exported OpenApiResponseTypes
export type Health = paths['/health']['get']['responses']['200']['content']['application/json'];
export type HealthClock =
  paths['/health/clock']['get']['responses']['200']['content']['application/json'];

export interface TxSimple {
  tx_hash: string;
  epoch_num: number;
  block_height: number;
  block_time: number;
  slot: number;
  fees: string;
  output_amount: string;
}

export type OpenApiResponseTypes = components['schemas'] & {
  health_content: Health;
  health_clock_content: HealthClock;
};
