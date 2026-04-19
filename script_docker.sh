#!/bin/bash

set -e


BLOCKS=(22244135 19299000 19299001 19299002 19299003 19299004 19299005)

PWD=$(pwd)
ZKSYNC_OS_ETH_RUNNER_DIR="$PWD/zksync-os/tests/instances/eth_runner"
ZKSYNC_AIRBENDER_CLI_DIR="$PWD/zksync-airbender/tools/cli"
TMP_DIR="$PWD/tmp"
WITNESS_DIR="$TMP_DIR/witness"
OUTPUT_DIR="$TMP_DIR/output"
CSV_FILE="$TMP_DIR/metrics.csv"

if [ -d "$TMP_DIR" ]; then
    rm -rf "$WITNESS_DIR"
    rm -rf "$OUTPUT_DIR"
fi

mkdir -p "$WITNESS_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Block Number,Witness Time(s),Proof Time(s),Combined Time(s),Proof Critical Time(s)" > "$CSV_FILE"

echo "Starting proof generation for ${BLOCKS[@]} blocks..."
echo ""

for block_number in "${BLOCKS[@]}"; do

    cd $ZKSYNC_OS_ETH_RUNNER_DIR

    echo "Processing block: $block_number"

    echo "[$block_number] Generating witness..."

    WITNESS_START_TIME=$(date +%s)

    eth_runner=info cargo run -p eth_runner --release --features rig/no_print,rig/unlimited_native -- single-run \
        --block-dir blocks/$block_number/ \
        --witness-output-dir $WITNESS_DIR \
        --randomized > /dev/null

    WITNESS_END_TIME=$(date +%s)
    WITNESS_DURATION=$((WITNESS_END_TIME - WITNESS_START_TIME))
    echo "[$block_number] Witness generated! Took $WITNESS_DURATION secs"
    echo ""

    echo "[$block_number] Generating proof..."

    BLOCK_OUTPUT_DIR="$OUTPUT_DIR/$block_number"
    mkdir -p "$BLOCK_OUTPUT_DIR"

    cd $ZKSYNC_AIRBENDER_CLI_DIR

    PROOF_START_TIME=$(date +%s)

    CRITICAL_PROOF_TIME=$(cargo run -p cli --release --features gpu prove \
          --bin ../../../zksync-os/zksync_os/evm_replay.bin \
          --input-file $WITNESS_DIR/${block_number}_witness \
          --until final-recursion \
          --output-dir $BLOCK_OUTPUT_DIR \
          --gpu \
          --cycles 500000000 2>&1 | grep "Total time on production critical path" | tail -1 | sed -E 's/.* ([0-9.]+)s.*/\1/')

    # cargo run -p cli --release --features gpu prove \
    #       --bin ../../../zksync-os/zksync_os/evm_replay.bin \
    #       --input-file $WITNESS_DIR/${block_number}_witness \
    #       --until final-recursion \
    #       --output-dir $BLOCK_OUTPUT_DIR \
    #       --gpu \
    #       --cycles 500000000

    PROOF_END_TIME=$(date +%s)
    PROOF_DURATION=$((PROOF_END_TIME - PROOF_START_TIME))

    COMBINED_DURATION=$((PROOF_DURATION + WITNESS_DURATION))

    echo "[$block_number] Proof generated! Took $PROOF_DURATION secs"
    echo ""

    echo "$block_number,$WITNESS_DURATION,$PROOF_DURATION,$COMBINED_DURATION,$CRITICAL_PROOF_TIME" >> "$CSV_FILE"

    sleep 5
    break
done
