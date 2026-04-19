# Build Container

### For building using docker
```bash
docker build -t zksync-vm .
```

### For building using apptainer
```bash
singularity build zksync-cont.sif singularity.def
```

# Create Volume for Cargo cache
Check if cargo-cache volume is created
```bash
docker volume ls
```
If not then create docker volume
```bash
docker volume create cargo-cache
```

# Run container
Run using following command
```bash
docker run --gpus all -it \
--name zksync \
-v $(pwd)/script.sh:/workspace/script.sh \
-v $(pwd)/tmp/:/workspace/tmp/ \
-v cargo-cache:/usr/local/cargo/registry \
zksync-vm /bin/bash
```

### For running using singularity
```bash
singularity exec --nv \
    --bind $(pwd)/script.sh:/workspace/script.sh:ro \   # read-only
    --bind $(pwd)/tmp/:/workspace/tmp/:rw \              # read-write
    my_container.sif /bin/bash /workspace/script.sh
```

# Build zksync-airbender
Build for gpu
```bash
cargo build -p cli --release --features gpu
```
