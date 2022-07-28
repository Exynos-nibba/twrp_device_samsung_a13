# Buildbot script for CircleCI
# coded by bruh™ aka Exynos-nigg

MANIFEST_LINK=https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git
BRANCH=twrp-12.1
DEVICE_CODENAME=a13
GITHUB_USER=Exynos-nibba
WORK_DIR=$(pwd)/TWRP-${DEVICE_CODENAME}
JOBS=$(nproc)
SPACE=$(df -h)
RAM=$(free mem -h)
build_cores=$(($JOBS + 2))

# Check CI specs!
echo "Checking specs!"
echo "CPU cores = ${JOBS}"
echo "Space available = ${SPACE}"
echo "RAM available = ${RAM}"
sleep 5

# Set up git!
echo ""
echo "Setting up git!"
git config --global user.name ${GITHUB_USER}
git config --global user.email ${GITHUB_EMAIL}
git config --global color.ui true

# randomize and fix sync thread number, according to available cpu thread count
SYNC_THREAD=$(grep -c ^processor /proc/cpuinfo)          # Default CPU Thread Count
if [[ $(echo ${JOBS}) -le 2 ]]; then SYNC_THREAD=$(shuf -i 10-15 -n 1)        # If CPU Thread >= 2, Sync Thread 5~7
elif [[ $(echo ${JOBS}) -le 8 ]]; then SYNC_THREAD=$(shuf -i 12-16 -n 1)    # If CPU Thread >= 8, Sync Thread 12~16
elif [[ $(echo ${JOBS}) -le 36 ]]; then SYNC_THREAD=$(shuf -i 30-36 -n 1)   # If CPU Thread >= 36, Sync Thread 30~36
fi

# make directories
echo ""
echo "Setting work directories!"
mkdir ${WORK_DIR} && cd ${WORK_DIR}

# set up rom repo
echo ""
echo "Syncing rom repo!"
repo init --depth=1 -u ${MANIFEST_LINK} -b ${BRANCH}
repo sync -j${SYNC_THREAD} --force-sync

# clone device sources
echo ""
echo "Cloning device sources!"

# Device tree
git clone -b twrp-12.1 https://github.com/Exynos-nibba/twrp_device_samsung_a13.git device/samsung/a13

# Kernel source 
# 

# extra dependencie for building dtbo
# git clone -b lineage-19.1 https://github.com/LineageOS/android_hardware_samsung.git hardware/samsung

# Start building!
echo ""
echo "Starting build!"
export ALLOW_MISSING_DEPENDENCIES=true
. build/envsetup.sh && lunch twrp_${DEVICE_CODENAME}-eng && make recoveryimage -j${build_cores}

# copy final product to another folder
echo ""
echo "Copying final product to another dir!"
mkdir ~/output

if [ -e ${WORK_DIR}/out/target/product/*/recovery.img ]; then
        echo ""
        echo "Done baking!"
        echo "Build will be uploaded in the artifacts section in CircleCI! =) "
        echo ""
	cp ${WORK_DIR}/out/target/product/*/*.tar ~/output/
        cp ${WORK_DIR}/out/target/product/*/*.zip ~/output/
        cp ${WORK_DIR}/out/target/product/*/recovery.img ~/output/
else
	echo ""
	echo "Recovery didnt build successfully!"
	echo "No recovery.img in out dir"
fi;


