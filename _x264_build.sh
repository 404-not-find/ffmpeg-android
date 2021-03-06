#!/bin/bash
. _settings.sh $*

pushd x264
X264_API="$(grep '#define X264_BUILD' < x264.h | sed 's/^.* \([1-9][0-9]*\).*$/\1/')"
echo -e "\n\n** BUILD STARTED: x264-v${X264_API} for ${1} **"

# --disable-asm disable
# Must exclude the option for arm64-v8a.
# The option is Used by configure, config.mak and Makefile files to define AS and to compile required *.S assembly files;
# Otherwise will have undefined references e.g. x264_8_pixel_sad_16x16_neon if --disable-asm is spefified
# However must include the option for x86 and x86_64;
# Otherwise have relocate text, requires dynamic R_X86_64_PC32 etc when use in aTalk

DISASM=""
if [[ $1 =~ x86.* ]]; then
   DISASM="--disable-asm"
fi

# --bit-depth not valid for v152
BITDEPTH="--bit-depth=all"
if [[ X264_API -le 152 ]]; then
  BITDEPTH=""
fi

make clean
./configure \
  --prefix=${PREFIX} \
  --includedir=${PREFIX}/include/x264 \
  --cross-prefix=${CROSS_PREFIX} \
  --sysroot=${NDK_SYSROOT} \
  --extra-cflags="-isystem ${NDK_SYSROOT}/usr/include/${NDK_ABIARCH} -isystem ${NDK_SYSROOT}/usr/include" \
  --host=${HOST} \
  --enable-pic \
  --enable-static \
  --enable-shared \
  --disable-opencl \
  --disable-thread \
  ${BITDEPTH} \
  ${DISASM} \
  --disable-cli || exit 1

make -j${HOST_NUM_CORES} install || exit 1
popd

pushd ${PREFIX}/lib
if [[ -f libx264.so.$X264_API ]]; then
  mv libx264.so.${X264_API} libx264_${X264_API}.so
  sed -i "s/libx264.so.${X264_API}/libx264_${X264_API}.so/g" libx264_${X264_API}.so
  rm libx264.so
  ln -f -s libx264_${X264_API}.so libx264.so
fi
popd

echo -e "** BUILD COMPLETED: x264-v${X264_API} for ${1} **\n"
