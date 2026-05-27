The sequence of steps to increase the domain size and regenerate the entire proving pipeline. Follow the
  steps in order to ensure consistency from the base layer up to the final proof.

Make following code changes so the Rust circuit and module match the new domain size.

1) Change the domain constant in the circuit library

   - File: `zksync-airbender/circuit_defs/risc_v_cycles/src/lib.rs`
   - Find the constant declaration (around line 12):
     ```rust
     pub const DOMAIN_SIZE: usize = 1 << 23 // old domain size = 1 << 22;
     ```
2) Update the module-level configuration

   - File: `zksync-airbender/risc_v_simulator/src/cycle/mod.rs`
   - Search for constants `SUPPORT_LOAD_LESS_THAN_WORD` and set them to `true`

  ### Prerequisites:  
  You must use the nightly-2025-07-25 toolchain with the following components:
  ```bash
  cargo install cargo-binutils
  rustup target add riscv32i-unknown-none-elf --toolchain nightly-2025-07-25
rustup component add rust-src --toolchain nightly-2025-07-25
rustup component add llvm-tools-preview --toolchain nightly-2025-07-25
  ```

  ---
  #### Step 1: Modify the Domain Size
  Change the constant in the circuit definition.
   * File: zksync-airbender/circuit_defs/risc_v_cycles/src/lib.rs
   * Line 12: pub const DOMAIN_SIZE: usize = 1 << 23; (or your desired size).

  #### Step 2: Synchronize Circuit Layouts
  Update the internal Rust and CUDA source code for all circuits to match the new size.
  ```bash
   cd zksync-airbender
   bash recreate_verifiers.sh
  ```

  #### Step 3: Recompile the Verifier Binaries
  This builds the RISC-V programs that perform the recursive verification.
  ```bash
   cd tools/verifier
   # Ensure the nightly toolchain is used for this specific build
   rustup run nightly-2025-07-25 bash build.sh
  ```

  #### Step 4: Update Verification Keys (VKs)
  This generates the new .vk.json files based on the recompiled binaries.
  Note: We must provide the path to OpenSSL in your Conda environment.
  ```bash
   # Remain in tools/verifier
   LD_LIBRARY_PATH=/home/blockchain/24m0750/miniconda3/envs/venv/lib bash build_vk.sh
  ```

  #### Step 5: Rebuild the Main CLI Tool
  Recompile the prover to include the new binaries and keys.
  ```bash
   cd ../../  # Back to zksync-airbender root
   # Ensure your CUDA paths are exported before running this
   cargo build --release --bin cli --features gpu
  ```

  #### Step 6: Run the Benchmark
  Execute your proving script.
  ```bash
    sbatch script_prajna.sh
  ```

  ---

  Summary of what these steps achieve:
   1. Step 1-2: Tells the GPU Prover how to arrange the 2²³ execution trace.
   2. Step 3: Tells the Recursive Verifier how to verify 2²³ proofs.
   3. Step 4: Creates the Mathematical Identity (VK) for the new 2²³ circuits.
   4. Step 5: Links everything together into a single executable.
