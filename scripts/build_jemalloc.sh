#!/bin/bash
set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
JEMALLOC_SOURCE_DIR="${PROJECT_ROOT}/deps/jemalloc"
JEMALLOC_LIB_FILE="${JEMALLOC_SOURCE_DIR}/lib/libjemalloc.a"

echo -e "${BLUE}🧠 jemalloc Build Script${NC}"
echo -e "${BLUE}========================${NC}"

# Check if jemalloc source directory exists
if [ ! -d "${JEMALLOC_SOURCE_DIR}" ]; then
    echo -e "${RED}❌ Error: jemalloc source directory not found: ${JEMALLOC_SOURCE_DIR}${NC}"
    echo -e "${YELLOW}💡 Tip: Initialize git submodules: git submodule update --init --recursive${NC}"
    exit 1
fi

# Check if jemalloc static library already exists
if [ -f "${JEMALLOC_LIB_FILE}" ]; then
    echo -e "${GREEN}✅ jemalloc static library already exists: ${JEMALLOC_LIB_FILE}${NC}"
    echo -e "${YELLOW}📊 Library info:${NC}"
    ls -lh "${JEMALLOC_LIB_FILE}"
    echo -e "${GREEN}🚀 Skipping jemalloc build (already built)${NC}"
    exit 0
fi

echo -e "${YELLOW}🔨 Building jemalloc static library...${NC}"
echo -e "${BLUE}Source: ${JEMALLOC_SOURCE_DIR}${NC}"
echo -e "${BLUE}Target: ${JEMALLOC_LIB_FILE}${NC}"

# Navigate to jemalloc source directory
cd "${JEMALLOC_SOURCE_DIR}"

# Clean any previous build artifacts
echo -e "\n${GREEN}🧹 Cleaning previous build artifacts...${NC}"
if [ -f "Makefile" ]; then
    make distclean || true
fi

# Configure jemalloc with optimal settings for Catzilla
echo -e "\n${GREEN}⚙️  Configuring jemalloc...${NC}"
./autogen.sh \
    --enable-static \
    --disable-shared \
    --disable-doc \
    --disable-debug \
    --enable-prof \
    --enable-stats \
    --with-pic \
    --disable-initial-exec-tls

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error: jemalloc configuration failed${NC}"
    exit 1
fi

# Build jemalloc
echo -e "\n${GREEN}🔨 Building jemalloc (this may take a few minutes)...${NC}"
NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
make -j${NPROC}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error: jemalloc build failed${NC}"
    exit 1
fi

# Verify the static library was created
if [ ! -f "${JEMALLOC_LIB_FILE}" ]; then
    echo -e "${RED}❌ Error: jemalloc static library was not created: ${JEMALLOC_LIB_FILE}${NC}"
    echo -e "${YELLOW}🔍 Available files in lib/:${NC}"
    ls -la lib/ || echo "lib/ directory not found"
    exit 1
fi

# Success!
echo -e "\n${GREEN}✅ jemalloc build complete!${NC}"
echo -e "${YELLOW}📊 Library info:${NC}"
ls -lh "${JEMALLOC_LIB_FILE}"
echo -e "${GREEN}🚀 Ready for Catzilla build!${NC}"
