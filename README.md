
***

# Proving Ethereum Blocks with zkSync OS and Airbender

This guide explains how to generate cryptographic proofs for Ethereum blocks using `zksync-os` and `zksync-airbender`. 

Proving an Ethereum block is a 3-step process:
1. **Data Fetching:** Gathering necessary block information (transactions, execution traces, etc.).
2. **Witness Generation:** Formatting this information into a prover-compatible witness format.
3. **Proving:** Running the cryptographic prover (CPU or GPU) to generate the final proof.

---

## 📋 Prerequisites

- **Rust toolchain** installed.
- **Hardware:** If running on a GPU, you need a device with **at least 22GB of VRAM**.
- **Ethereum Node (Optional):** If you plan to fetch live blocks, you need an RPC endpoint to an **archive node** with the debug section enabled.
- The `zksync-os` repository cloned locally.

---

## 🛠️ Step 1: Witness Generation (`eth_runner`)

The `eth_runner` tool (located in `tests/instances/eth_runner` inside the `zksync-os` repo) is responsible for fetching data and generating the witness. 

It operates in two modes: `single-run` (local files) and `live-run` (RPC fetching). To generate a witness for the prover, use the `--witness-output-dir` flag.

First, create a directory to store the witness data:
```bash
mkdir -p /tmp/witness
```

*(Run the following commands from the root directory of the `zksync-os` repository).*

### Mode A: Single Run (Local Data)
Use this mode to run an example block already committed to the repository or downloaded locally in JSON format.

```bash
RUST_LOG=eth_runner=info cargo run -p eth_runner --release --features rig/no_print,rig/unlimited_native -- single-run --block-dir blocks/22244135/   --witness-output-dir /tmp/witness --randomized
```
> 💡 **Need more blocks?** You can find additional example blocks in the [ethereum-block-examples repository](https://github.com/antoniolocascio/ethereum-block-examples/tree/main/blocks).

### Mode B: Live Run (Fetch via RPC)
Use this mode to fetch block traces directly from an Ethereum archive node. It creates a local database (e.g., `../db`) to cache RPC information.

```bash
RUST_LOG=eth_runner=info cargo run -p eth_runner --release --features rig/no_print,rig/unlimited_native -- live-run \
  --start-block 19299000 \
  --end-block 19299005 \
  --endpoint <YOUR_ARCHIVE_NODE_RPC_ENDPOINT> \
  --db ../db \
  --witness-output-dir /tmp/witness
```

---

## 🚀 Step 2: Running the Prover (`zksync-airbender`)

Once the witness is generated, you need to use `zksync-airbender` to compute the proof.

1. Clone the Airbender repository (version `v0.3.0` is recommended):
   ```bash
   git clone https://github.com/matter-labs/zksync-airbender.git
   cd zksync-airbender
   git checkout v0.3.0
   ```
2. Navigate to the CLI tool directory:
   ```bash
   cd tools/cli
   ```
3. Create a directory for the final proof output:
   ```bash
   mkdir -p /tmp/output
   ```

> ⚠️ **Path Note:** The commands below assume your `zksync-os` and `zksync-airbender` folders share the same parent directory. Adjust the `--bin` path (`../../../zksync-os/zksync_os/evm_replay.bin`) if your setup differs.

### Option A: Proving with GPU (Recommended / Faster)
*Requires ≥ 22GB VRAM.*

```bash
CUDA_VISIBLE_DEVICES=0 cargo run -p cli --release --features gpu prove \
  --bin ../../../zksync-os/zksync_os/evm_replay.bin \
  --input-file /tmp/witness/22244135_witness \
  --until final-recursion \
  --output-dir /tmp/output \
  --gpu \
  --cycles 500000000
```

#### 🔧 Troubleshooting GPU Out of Memory (OOM)
To hide latency, Airbender uses an asynchronous allocator and overlaps CPU<->GPU transfers with computations. This pipelining requires dedicated memory allocations. 

If you encounter an Out of Memory (OOM) error, you can reduce the memory high-water mark by forcing the GPU to run in **synchronous mode**:

```bash
CUDA_LAUNCH_BLOCKING=1 CUDA_VISIBLE_DEVICES=0 cargo run -p cli --release --features gpu prove \
  --bin ../../../zksync-os/zksync_os/evm_replay.bin \
  --input-file /tmp/witness/19299001_witness \
  --until final-recursion \
  --output-dir /tmp/output \
  --gpu \
  --cycles 500000000
```

### Option B: Proving with CPU
If you don't have a compatible GPU, you can run the prover on your CPU (note: this will take significantly longer).

```bash 
cargo run -p cli --release prove \
  --bin ../../../zksync-os/zksync_os/evm_replay.bin \
  --input-file /tmp/witness/19299001_witness \
  --until final-recursion \
  --output-dir /tmp/output \
  --cycles 500000000
```

---

## ✅ Step 3: Verification

Once the prover finishes successfully, your final proof will be generated at:
📄 `/tmp/output/recursion_program_proof.json`

You can visually verify the validity of your generated proof by uploading this JSON file to the **[FRI Verifier](http://fri-verifier.vercel.app)**.

To verify locally, run following command inside zksync-airbender/tools/cli directory
```bash
    time cargo run --profile cli --features include_verifiers verify --proof ../../../tmp/output/19299000/reduced_proof_0.json
```