#!/bin/bash

set -e
set -x

# Define variables
#BGENIX_URL="https://enkre.net/cgi-bin/code/bgen/zip/78cf9c9636/BGEN-78cf9c9636.zip"
#BGENIX_ZIP="BGEN-78cf9c9636.zip"
echo "Using Boost version:"
ls ${PREFIX}/lib/libboost_system*

BGENIX_DIR="BGEN-78cf9c9636"

cp -r /gstore/data/humgenet/projects/jerome/bioconda-recipes/recipes/BGEN-78cf9c9636 .

#echo "Downloading bgenix from ${BGENIX_URL}..."
#wget ${BGENIX_URL} -O ${BGENIX_ZIP}

#echo "Extracting ${BGENIX_ZIP}..."
#unzip ${BGENIX_ZIP}

#echo "Entering directory ${BGENIX_DIR}..."
cd ${BGENIX_DIR}

#sed -i -e "s/-std=c++14/-std=c++17/" -e "s/'-Wno-c++11-long-long',//g" wscript

grep FLAGS wscript 

export CFLAGS="${CFLAGS} -O3 -march=native -mtune=native -flto -ffast-math -I${PREFIX}/include -I${PREFIX}/include/boost"
export CXXFLAGS="${CXXFLAGS} -O3 -std=c++14 -march=native -mtune=native -flto -ffast-math -I${PREFIX}/include -I${PREFIX}/include/boost"
export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib -flto"

# Configure, build, and install with waf
./waf configure build install \
      --prefix=${PREFIX} \
      --bindir=${PREFIX}/bin \
      --libdir=${PREFIX}/lib \
      --jobs=${CPU_COUNT}

#cp build/libbgen.a ${PREFIX}/lib

cd ..
#rm -rf ${BGENIX_DIR} ${BGENIX_ZIP}

echo "bgenix installation completed successfully."

echo "Using Boost version:"
ls ${PREFIX}/lib/libboost_system*

if [ "$(uname)" = "Darwin" ]; then
  # LDFLAGS fix: https://github.com/AnacondaRecipes/intel_repack-feedstock/issues/8
  export LDFLAGS="-Wl,-pie -Wl,-headerpad_max_install_names -Wl,-rpath,$PREFIX/lib -L$PREFIX/lib"
else
  export LDFLAGS="-L$PREFIX/lib"
  export MKL_THREADING_LAYER="GNU"
fi
# https://bioconda.github.io/troubleshooting.html#zlib-errors
export CFLAGS="-I$PREFIX/include -I${PREFIX}/include/boost"
export CPATH=${PREFIX}/include

mkdir -p build

cmake \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
  -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native -mtune=native -flto -ffast-math" \
  -DCMAKE_C_FLAGS_RELEASE="-O3 -march=native -mtune=native -flto -ffast-math" \
  -S "${SRC_DIR}" \
  -B build

make  -C build -j4 regenie
make  -C build install

# bash test/test_conda.sh --path "${SRC_DIR}"
