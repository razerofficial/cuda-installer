#!/usr/bin/env bash
# SPDX-License-Identifier: MIT

# available versions
python_versions=( "3.9" "3.10" "3.11" "3.12" ) 
cuda_versions=( "11.8" "12.4" "12.6" "12.8" )
additional=( "PyTorch" "TensorFlow" "None" )

selected_python=""
selected_cuda=""
selected_additional=""
env_name=""

PYTHON_OPTIONS=()
CUDA_OPTIONS=()
ADDITIONAL_OPTIONS=()


trap ctrl_c INT
ctrl_c() {
    dialog --clear
    echo "Exiting..."
    exit 1
}

exitcheck() {
    if [ $? -ne 0 ]; then
        dialog --clear
        exit 1
    fi
}

spinner() {
    local pid=$1
    i=1
    sp="/-\|"
    echo -n ' '
    while ps a | awk '{print $1}' | grep -q "$pid"; do
        printf "\b%s" ${sp:i++%${#sp}:1}
        sleep .1
    done
    printf "\r    \b\b\b\b"
}

# build dialog option strings
i=1
for ver in "${python_versions[@]}"; do
    PYTHON_OPTIONS+=("$ver" "$i" 'off')
    ((i++))
done

i=1
for ver in "${cuda_versions[@]}"; do
    CUDA_OPTIONS+=("$ver" "$i" 'off')
    ((i++))
done

i=1
for pkg in "${additional[@]}"; do
    ADDITIONAL_OPTIONS+=("$pkg" "$i" 'off')
    ((i++))
done

col_size=$(tput cols)
box_x=$((col_size / 2 - 25))

selected=$(dialog \
                 --keep-window --begin 5 $((box_x)) --cr-wrap --infobox "CUDA Installer\n[Space] to select, [Enter] to confirm" 5 50 \
    --and-widget --keep-window --begin 8 $((box_x)) --no-cancel --no-ok --colors --radiolist 'Python Version' 12 50 4 "${PYTHON_OPTIONS[@]}" \
    --and-widget --keep-window --begin 15 $((box_x)) --no-cancel --no-ok --radiolist 'CUDA Version' 12 50 4 "${CUDA_OPTIONS[@]}" \
    --and-widget --keep-window --begin 22 $((box_x)) --radiolist 'Additional Packages' 10 50 4 "${ADDITIONAL_OPTIONS[@]}" \
    2>&1 >/dev/tty)
exitcheck
dialog --clear

# extract selected options
selected=$(echo "$selected" | tr -d "'")

selected_python=$(echo "$selected" | cut -f1)
selected_cuda=$(echo "$selected" | cut -f2)
selected_additional=$(echo "$selected" | cut -f3)

# reappend cuda version
if [ "${selected_cuda:0:2}" == "11" ]; then
    selected_cuda="$selected_cuda.0"
elif [ "${selected_cuda:0:2}" == "12" ]; then
    selected_cuda="$selected_cuda.1"
fi

if [ -z "$selected_python" ] || [ -z "$selected_cuda" ] || [ -z "$selected_additional" ]; then
    dialog --clear
    echo "Not enough selections made. Exiting"
    exit 1
fi

# Get environment name
env_name=$(dialog --begin 14 $((box_x)) --inputbox "Enter environment name:" 8 50 "" 2>&1 >/dev/tty)
exitcheck
if [[ -z "$env_name" || "$env_name" =~ ^[[:space:]]*$ ]]; then
    dialog --clear
    echo "No environment name provided. Exiting."
    exit 1
fi
dialog --clear

echo -e "Creating environment with the following parameters:\nPython: $selected_python\nCUDA: $selected_cuda\nAdditional packages: $selected_additional"
conda create --name "$env_name" -c "nvidia/label/cuda-$selected_cuda" cuda "python=$selected_python" -y > /dev/null &

conda_pid=$!
spinner $conda_pid
wait $conda_pid

exitcheck

if [ "$selected_additional" == "PyTorch" ]; then
    echo "Installing PyTorch..."
    install_version=$(echo "$selected_cuda" | sed 's/\.[0-9]*$//' | tr -d '.')
    conda run --name "$env_name" pip install torch torchvision torchaudio --index-url "https://download.pytorch.org/whl/cu$install_version" -q &

    torch_pid=$!
    spinner $torch_pid
    wait $torch_pid

    exitcheck

elif [ "$selected_additional" == "TensorFlow" ]; then
    echo "Installing TensorFlow..."
    conda run --name "$env_name" pip install 'tensorflow[and-cuda]' -q &

    tf_pid=$!
    spinner $tf_pid
    wait $tf_pid

    exitcheck
fi

BOLD='\033[1m'
CYAN='\033[36m'
RESET='\033[0m'
echo -e "Use ${BOLD}${CYAN}conda activate $env_name${RESET} to activate the environment."