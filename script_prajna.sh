#!/bin/bash
#SBATCH --job-name=zksync-single-run
#SBATCH --qos=dgx
#SBATCH --partition=dgx
#SBATCH --nodes=1
#SBATCH --gres=gpu:8
#SBATCH --mem=128G
#SBATCH --ntasks-per-node=64
#SBATCH --output=logs/%j.out
#SBATCH --error=logs/%j.err
#SBATCH --time=00:40:00
#SBATCH --exclusive

cd /home/blockchain/24m0750/work/zksync
source ~/miniconda3/etc/profile.d/conda.sh

conda activate /home/blockchain/24m0750/work/zksync/venv

./script_docker.sh
