#!/bin/bash
set -x

touch /tmp/init.log
exec > /tmp/init.log 2>&1

disk_dev=/dev/sda4
work_dir=/xinyu-work
chipyard_repo=https://github.com/ucb-bar/chipyard.git
conda=$work_dir/miniforge3/bin/conda
benchmarks=/xinyu-work/chipyard/.conda-env/riscv-tools/riscv64-unknown-elf/share/riscv-tests/benchmarks/
my boom=https://github.com/xinyu199/riscv-boom.git

# mount a filesystem
echo "Formatting $disk_dev, mounting to $work_dir"

sudo mkfs.ext4 $disk_dev
sudo mkdir $work_dir
sudo mount $disk_dev $work_dir

echo "Mounting successful, changing current work dir"

cd $work_dir
sudo chmod -R a+rw $work_dir

# install miniforge3
echo "Installing Miniforge3"

curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash Miniforge3-Linux-x86_64.sh -b -p $work_dir/miniforge3/

echo "Miniforge3 installed successfully"


# setup conda
echo "setup conda ...."

$conda install -n base conda-lock=1.4 -y
source $work_dir/miniforge3/etc/profile.d/conda.sh
$conda env list
source $work_dir/miniforge3/bin/activate base


# setup chipyard
# get chipyard
git clone https://github.com/ucb-bar/chipyard.git $work_dir/chipyard
cd $work_dir/chipyard
git checkout 1.10.0

# init
export PATH="$PATH:$work_dir/miniforge3/bin"
echo "$PATH"
source build-setup.sh riscv-tools -s 6 -s 7 -s 8 -s 9

# replace boom repo
git config --global --add safe.directory $work_dir/chipyard
rm -rf $work_dir/chipyard/generators/boom
git clone $my_boom $work_dir/chipyard/generators/boom
cd $work_dir/chipyard/generators/boom
git switch dev

$conda env list
source $work_dir/chipyard/env.sh
$conda env list

# test env
cd $work_dir/chipyard/sims/verilator
make -j CONFIG=MediumBoomConfig run-binary BINARY=$benchmarks/qsort.riscv LOADMEM=1

echo "success to test env"
