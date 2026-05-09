import re
import csv
import os
import glob

def parse_single_block_file(file_path):
    """Parses a single log file and returns a list of row dictionaries."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    block_data = []

    # 1. Extract Block ID from content (Running block: 19299000)
    # If not in content, fall back to the filename
    block_id_match = re.search(r"Running block: (\d+)", content)
    if block_id_match:
        block_id = block_id_match.group(1)
    else:
        # Fallback: extract digits from filename (e.g., "block_19299000.log" -> "19299000")
        filename = os.path.basename(file_path)
        block_id_match = re.search(r"(\d+)", filename)
        block_id = block_id_match.group(1) if block_id_match else filename

    # 2. Extract Total single_run execution (Witness time)
    # single_run_match = re.search(r"Total single_run execution took: ([\d\.]+\w+)", content)
    # single_run_time = single_run_match.group(1) if single_run_match else "N/A"

    # 3. Extract Total critical path
    critical_path_match = re.search(r"Total time on production critical path ([\d\.]+s)", content)
    critical_path_time = critical_path_match.group(1) if critical_path_match else "N/A"

    # 4. Extract all Proof Generation steps (Initial + Recursions)
    # This regex captures the time and the counts of basic/reduced/delegation proofs
    proof_pattern = re.compile(
        r"\*\*\*\* proofs generated in ([\d\.]+s) \*\*\*\*\n"
        r"Created (\d+) basic proofs, (\d+) reduced proofs, (\d+) reduced \(log23\) proofs and (\d+) delegation proofs\."
    )

    # 5. Extract block gas used
    gas_used_match = re.search(r"Block gas used: (\d+)", content)
    gas_used = gas_used_match.group(1)
    
    proof_matches = proof_pattern.findall(content)

    for i, match in enumerate(proof_matches):
        gen_time, basic, reduced, log23, delegation = match
        
        if i == 0:
            step_name = "Initial Proving"
        else:
            step_name = f"Recursion Level {i-1}"

        block_data.append({
            "Block ID": block_id,
            "Step": step_name,
            "Generation Time": gen_time,
            "Basic Proofs": basic,
            "Reduced Proofs": reduced,
            "Log23 Proofs": log23,
            "Delegation Proofs": delegation,
            "Gas used": gas_used,
            # "Witness Execution Time": single_run_time,
            "Total Critical Path": critical_path_time if i == len(proof_matches) - 1 else ""
        })

    return block_data

def process_all_files(input_directory, output_csv):
    
    files = []

    with os.scandir(input_directory) as entries:
        for entry in entries:
            if entry.is_dir() and entry.name != '22244135':
                path = entry.path + '/output.txt'
                files.append(path)
                
    if not files:
        print(f"No log files found in {input_directory}")
        return


    all_results = []
    for file_path in sorted(files):
        print(f"Processing: {file_path}")
        file_results = parse_single_block_file(file_path)
        all_results.extend(file_results)

    if all_results:
        keys = all_results[0].keys()
        with open(output_csv, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(all_results)
        print(f"\nSuccessfully wrote data for {len(files)} files to {output_csv}")
    else:
        print("No valid proof data found in the files.")

# --- Settings ---
# Update these paths to match your environment
INPUT_DIR = "./tmp/output"  # Folder containing your .log files
OUTPUT_FILE = "block_proof_metrics.csv"

if __name__ == "__main__":
    # Create dummy directory for example purposes if it doesn't exist
    if not os.path.exists(INPUT_DIR):
        print(f"Please create the directory '{INPUT_DIR}' and put your log files there.")
    else:
        process_all_files(INPUT_DIR, OUTPUT_FILE)