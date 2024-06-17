#!/bin/bash
#SBATCH --partition=RM
#SBATCH --time=6:00:00
#SBATCH --nodes=2
#SBATCH --job-name=pr
#SBATCH --output=pr.log
#SBATCH --mail-type=ALL

# Specify Conda location and environment to use
CONDA_DIR="/opt/packages/anaconda3/etc/profile.d/conda.sh"
CONDA_ENV="monsoon-pr"

# Specify where downloaded data should be stored
SCRIPTS_DIR="/ocean/projects/atm200007p/sferrett/Repos/monsoon-pr/scripts/"
DATA_DIR="/ocean/projects/atm200007p/sferrett/Repos/monsoon-pr/data/raw/models"

# Specify latitude and longitude ranges
LON_MIN=50.
LON_MAX=90.
LAT_MIN=0.
LAT_MAX=30.

# Specify models
MODELS=("untitled")

# Function to execute NCO commands in the background
download() {
    local url="$1"
    local filename=$(basename "$url")
    local command=("ncks" "-d" "lat,$LAT_MIN,$LAT_MAX" "-d" "lon,$LON_MIN,$LON_MAX" "$url" "$filename")   
    echo "Executing: ${command[*]}"
    "${command[@]}"
}

# Function to print failed downloads
print_failed_downloads() {
    for failed_download in "${FAILED_DOWNLOADS[@]}"; do
        echo"- $model\n"
    done
}

# Activate Conda environment
source "$CONDA_DIR"
module load anaconda3
if ! conda activate $CONDA_ENV; then
    echo "Error: Unable to activate Conda environment"
    exit 1
fi

# Navigate to where downloaded data will be stored
cd "$DATA_DIR"

# Iterate over models and OPEnDAP URLs to download data
for model in "${MODELS[@]}"; do
    echo "Downloading data for $model..."
    if [ -f "$SCRIPTS_DIR/$model.txt" ]; then
        while IFS= read -r url; do
            download "$url"
        done < "$SCRIPTS_DIR/$model.txt"
    else
        echo "Error: $SCRIPTS_DIR/$model.txt not found"
        exit 1
    fi
done

# Deactivate Conda environment
conda deactivate