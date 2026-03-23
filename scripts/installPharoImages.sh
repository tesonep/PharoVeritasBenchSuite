#########

# This script fully automates the downloading and the installion of different veritas benchs in different pharo images. Perfect for using in a server.

# This example shows just to download and install Phaor images.
# The scripts copies one image per project, install its corresponding baseline and if necessary makes some preprocessing.
# For example for the DataFrame banchmark we need th datasets, meaning the csv files. This script takes the file that comes by default, the smallest one, and puts it into the image directory which is the right place to put. If you want the bigger datasets you need to generate them using the python file present in the code. Chech in src.
# For the Microdowm image it download the spec book from another repo and then moves the folder.


# Variables
BASE_DIR="baseimage"
BASE_IMAGE_FILE="$BASE_DIR/Pharo.image"
PHARO_CMD="$BASE_DIR/pharo"

# Functions
install_veritas_for() {
  local image_path="$1"
  local veritas_bench="$2"
  "$PHARO_CMD" --headless "$image_path" metacello install "github://jordanmontt/PharoVeritasBenchSuite:main" "$veritas_bench"


  echo; echo; echo
  echo "Installed Veritas $veritas_bench for image $image_path"
}

setup_base_image() {
  mkdir -p baseimage
  cd baseimage || return 1
  wget --quiet -O - get.pharo.org/140+vm | bash
  cd - > /dev/null || return 1

  echo; echo; echo
  echo "Baseimage downloaded"
}

######

# Download baseimage
setup_base_image

############
# Cormas
mkdir -p cormas

# save image and copy sources file
"$PHARO_CMD" --headless "$BASE_IMAGE_FILE" save ../cormas/cormas
cp "$BASE_DIR"/*.sources ./cormas/

# install dependencies
install_veritas_for ./cormas/cormas.image BaselineOfVeritasCormas

############
# HoneyGinger
mkdir -p hg

# save image and copy sources file
"$PHARO_CMD" --headless "$BASE_IMAGE_FILE" save ../hg/hg
cp "$BASE_DIR"/*.sources ./hg/

# install dependencies
install_veritas_for ./hg/hg.image BaselineOfVeritasHoneyGinger

############
# Microdown
mkdir -p micro

# save image and copy sources file
"$PHARO_CMD" --headless "$BASE_IMAGE_FILE" save ../micro/micro
cp "$BASE_DIR"/*.sources ./micro/

# install dependencies
install_veritas_for ./micro/micro.image BaselineOfVeritasMicrodown

# download Spec2 book
TMP_CLONE_DIR=$(mktemp -d)
git clone --depth=1 https://github.com/SquareBracketAssociates/BuildingApplicationWithSpec2.git "$TMP_CLONE_DIR"
mv "$TMP_CLONE_DIR" ./micro/Spec2Book
echo; echo; echo
echo "Spec2Book downloaded"


############
# DataFrame
mkdir -p df

# save image and copy sources file
"$PHARO_CMD" --headless "$BASE_IMAGE_FILE" save ../df/df
cp "$BASE_DIR"/*.sources ./df/

# install dependencies
install_veritas_for ./df/df.image BaselineOfVeritasDataFrame

# move tiny_dataset.csv to the root of df/
mv ./df/pharo-local/iceberg/jordanmontt/PharoVeritasBenchSuite/src/Veritas-DataFrame/tiny_dataset.csv ./df/
echo; echo; echo
echo "dataset copied"

