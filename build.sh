#!/bin/bash

# DOWNLOAD CODEQL CLI BINARIES v2.2.6 and CODEQL v1.25.0
mkdir codeql-home
pushd codeql-home

wget https://github.com/github/codeql-cli-binaries/releases/download/v2.3.4/codeql-linux64.zip
unzip codeql-linux64.zip

cp "$GITHUB_WORKSPACE/codeql-proxy" codeql/codeql-proxy
chmod +x codeql/codeql-proxy

git clone https://github.com/github/codeql.git codeql-stdlib
pushd codeql-stdlib
git checkout v1.26.0
popd
popd
pwd

echo 'Hello!'
echo $GITHUB_WORKSPACE
cd $GITHUB_WORKSPACE
mkdir -p codeql-runner

# SETUP CODEQL RUNNER
wget https://github.com/github/codeql-action/releases/latest/download/codeql-runner-linux
chmod +x codeql-runner-linux

./codeql-runner-linux init \
  --checkout-path "$GITHUB_WORKSPACE" \
  --repository "$GITHUB_REPO" \
  --github-url https://github.com \
  --github-auth "$GITHUB_TOKEN" \
  --languages cpp \
  --codeql-path $GITHUB_WORKSPACE/codeql-home/codeql/codeql
  --source-root="$GITHUB_WORKSPACE"

source codeql-runner/codeql-env.sh

# BUILD CARLA
# cd "$GITHUB_WORKSPACE/$REPOSITORY_MATRIX_ENTRY"
cd "$GITHUB_WORKSPACE"

echo 'what is UE4_ROOT'
export UE4_ROOT=~/UnrealEngine_4.24
echo $UE4_ROOT

pip3 install distro
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-8/bin/clang++ 180 &&
sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-8/bin/clang 180

# Get the CARLA assets
cd /actions-runner/_work/carla/carla
./Update.sh
# builds CARLA and creates a packaged version for distribution.
echo "Build CARLA and create a packaged version for distribution."
make PythonAPI
make launch

./codeql-runner-linux analyze \
  --repository "$GITHUB_REPO" \
  --github-url https://github.com \
  --github-auth "$GITHUB_TOKEN" \
  --commit "$GITHUB_SHA" \
  --ref "$GITHUB_REF"

$GITHUB_WORKSPACE/codeql-home/codeql/codeql database bundle -o "codeql-runner/carla-$GITHUB_SHA-cpp.zip" -m brutal --name "carla-$GITHUB_SHA-cpp" codeql-runner/codeql_databases/cpp

