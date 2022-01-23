import requests
from typing import List


GRAPH_ENDPOINT = "https://api.thegraph.com/subgraphs/name/convex-community/curve-factory-volume"


def get_transactions_for_event(
    event,
    block_start: int,
    block_end: int
) -> List[int]:

    event_filter = event.createFilter(
        fromBlock=block_start,
        toBlock=block_end
    )
    return [
        transfer['blockNumber'] for transfer in event_filter.get_all_entries()
    ]


def get_pool_tx_block_numbers(
        pool_address: str,
        start_block: int,
        stop_block: int,
        step: int = 5000
) -> List[int]:
    pool_address = pool_address.lower()
    blocks = range(start_block, stop_block, step)
    print(f'Going through {len(blocks)} ranges ...')
    all_tx_blocks = []

    for block in blocks:

        block_gte = block
        block_lt = block + step

        print(f'Querying between {block_gte}: {block_lt}.')

        query = f"""
            {{
              swapEvents(
                where: {{
                  pool: "{pool_address}"
                  block_gte: {block_gte}
                  block_lte: {block_lt}
                }}
              ) {{
                block
              }}
            }}
            """

        r = requests.post(GRAPH_ENDPOINT, json={'query': query})
        data_swaps = dict(r.json())['data']['swapEvents']

        query = f"""
            {{
              liquidityEvents(
                where: {{
                  poolAddress: "{pool_address}"
                  block_gt: 13330310
                  block_lte: 14036340
                }}
              ) {{
                block
              }}
            }}
            """

        r = requests.post(GRAPH_ENDPOINT, json={'query': query})
        data_liquidity = dict(r.json())['data']['liquidityEvents']

        data = data_swaps + data_liquidity

        if not data:
            print('reached end!')
            break

        if len(data) > 1000:
            print(
                f"Warning! Txes between {block_gte}:{block_lt} exceeds 1000!")

        all_tx_blocks.extend([int(tx['block']) for tx in data])
        print(f'Total txes: {len(all_tx_blocks)}')

    return all_tx_blocks
