export SCRIPT_DIR=$(dirname "$(realpath "$0")")

HFS=/opt/hfs21.0.559

cmake -B $SCRIPT_DIR/build -DHOUDINI_ROOT=$HFS -Wno-dev