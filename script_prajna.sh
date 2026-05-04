#!/bin/bash
#SBATCH --job-name=zksync-single-run
#SBATCH --qos=a40
#SBATCH --partition=a40
#SBATCH --nodes=1
#SBATCH --gres=gpu:2
#SBATCH --mem=64G
#SBATCH --ntasks-per-node=64
#SBATCH --output=logs/%j.out
#SBATCH --error=logs/%j.err
#SBATCH --time=00:40:00

cd /home/blockchain/24m0750/work/zksync-experiments
source ~/miniconda3/etc/profile.d/conda.sh

conda activate venv

export CUDA_HOME=$CONDA_PREFIX
export CUDA_PATH=$CONDA_PREFIX
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib:$CONDA_PREFIX/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=$CONDA_PREFIX/lib:$CONDA_PREFIX/lib:$LIBRARY_PATH

./script_docker.sh
