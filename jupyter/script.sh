#!/usr/bin/env bash
#
# This file is managed by Ansible.
#
# template: /etc/ansible/roles/ood/templates/jupyter/script.sh.erb.j2
#


echo "Starting main script..."
echo "TTT - $(date)"

#
# Start Jupyter server
#

# # Create launcher wrapper
# echo "Creating launcher wrapper script..."
# (
# umask 077
# sed 's/^ \{2\}//' > "/home/yamanq/ondemand/data/sys/dashboard/batch_connect/sys/bc_osc_jupyter/form/output/e3f9bc60-6097-4421-9796-8e0321365c66/launch_wrapper.sh" << EOL
#   #!/usr/bin/env bash

#   # Log all output from this script
#   exec &>>"/home/yamanq/ondemand/data/sys/dashboard/batch_connect/sys/bc_osc_jupyter/form/output/e3f9bc60-6097-4421-9796-8e0321365c66/launch_wrapper.log"

#   # Load the required environment
#   module load \${MODULES}
#   module list

#   # Launch the original command
#   set -x
#   exec "\${@}"
# EOL
# )
# chmod 700 "/home/yamanq/ondemand/data/sys/dashboard/batch_connect/sys/bc_osc_jupyter/form/output/e3f9bc60-6097-4421-9796-8e0321365c66/launch_wrapper.sh"
echo "TTT - $(date)"

# Create custom Jupyter kernels
echo "Creating custom Jupyter kernels..."
export JUPYTER_PATH="${PWD}/share/jupyter"
echo "TTT - $(date)"

# Create user-created Conda env Jupyter kernels
echo "Creating custom Jupyter kernels from user-created Conda environments..."
for dir in "${HOME}/.conda/envs"/*/ "${HOME}/envs"/*/ ; do
  (
  umask 077
  set -e
  KERNEL_NAME="$(basename "${dir}")"
  KERNEL_PATH="~${dir#${HOME}}"
  [[ -x "${dir}bin/activate" ]] || exit 0
  echo "Creating kernel for ${dir}..."
  source "${dir}bin/activate" "${dir}"
  set -x
  if [[ "$(conda list -f --json ipykernel)" == "[]" ]]; then
    CONDA_PKGS_DIRS="$(mktemp -d)" conda install --yes --quiet --no-update-deps ipykernel
  fi
  python \
    -m ipykernel \
      install \
      --name "conda_${KERNEL_NAME}" \
      --display-name "${KERNEL_NAME} [${KERNEL_PATH}]" \
      --prefix "${PWD}"
  ) &
done
wait
echo "TTT - $(date)"

# Set working directory to notebook root directory
cd "${NOTEBOOK_ROOT}"

# Setup Jupyter environment
module use $MODULEPATH_ROOT/project/ondemand
module load python3.7-anaconda/2019.07
module list
echo "TTT - $(date)"

# List available kernels for debugging purposes
set -x
jupyter kernelspec list
{ set +x; } 2>/dev/null
echo "TTT - $(date)"

# Launch the Jupyter server
set -x
jupyter notebook --config="${CONFIG_FILE}"
