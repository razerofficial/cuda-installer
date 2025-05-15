## Requirements
- conda
- dialog (included in universe repo)

### Info
- currently only includes 11.8, 12.4, 12.6, 12.8 but other version can easily be added
- creates a conda environment for each selected cuda and python base
- uninstall script no longer needed, you can use `conda env remove -n ENVNAME` to remove the environments
- pip is recommended over conda to install tensor, and it comes with cuda 12.5

### Switching CUDA versions
- you should always deactivate the current environment using `conda deactivate` before switching to a new environment
- since we are using conda, you can use the usual `conda activate ENVNAME` to switch to a different version

### Possible issues
- pip will install its own subset of the cuda toolkit alongside tensorflow which can be different from the base cuda install which may cause issues within the environment