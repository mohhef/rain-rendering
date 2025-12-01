#!/bin/bash
# Verification script for Docker container
# This script tests that all dependencies are correctly installed

echo "=========================================="
echo "Docker Container Verification Script"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[PASS]${NC} $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} $2"
        ((TESTS_FAILED++))
    fi
}

# Function to print info
print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

echo "1. Checking system information..."
print_info "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
print_info "Kernel: $(uname -r)"
print_info "Architecture: $(uname -m)"
echo ""

echo "2. Checking C++ compiler..."
if command -v g++ &> /dev/null; then
    VERSION=$(g++ --version | head -n1)
    print_result 0 "g++ found: $VERSION"

    # Check C++11 support
    echo "int main() { return 0; }" | g++ -std=c++11 -x c++ - -o /tmp/test 2>/dev/null
    print_result $? "C++11 support verified"
    rm -f /tmp/test
else
    print_result 1 "g++ not found"
fi
echo ""

echo "3. Checking Boost 1.62.0..."
if ldconfig -p | grep -q "libboost"; then
    BOOST_VERSION=$(cat /usr/local/include/boost/version.hpp 2>/dev/null | grep "BOOST_LIB_VERSION" | head -n1 || echo "Version file not found")
    print_result 0 "Boost libraries found"
    print_info "Version info: $BOOST_VERSION"

    # List some key boost libraries
    print_info "Available libraries:"
    ldconfig -p | grep "libboost" | head -n 5 | awk '{print "  - " $1}'
else
    print_result 1 "Boost libraries not found"
fi
echo ""

echo "4. Checking OpenCV 3.2.0..."
if ldconfig -p | grep -q "libopencv_core"; then
    print_result 0 "OpenCV libraries found"

    # Try to get version
    if command -v pkg-config &> /dev/null; then
        CV_VERSION=$(pkg-config --modversion opencv 2>/dev/null || echo "Unable to get version")
        print_info "OpenCV version: $CV_VERSION"
    fi

    # List some key opencv libraries
    print_info "Available libraries:"
    ldconfig -p | grep "libopencv" | head -n 5 | awk '{print "  - " $1}'

    # Test Python OpenCV
    if python3 -c "import cv2; print('OpenCV Python:', cv2.__version__)" 2>/dev/null; then
        print_result 0 "OpenCV Python bindings work"
    else
        print_result 1 "OpenCV Python bindings not working"
    fi
else
    print_result 1 "OpenCV libraries not found"
fi
echo ""

echo "5. Checking OpenSceneGraph 3.4.1..."
if ldconfig -p | grep -q "libosg"; then
    print_result 0 "OpenSceneGraph libraries found"

    # List some key OSG libraries
    print_info "Available libraries:"
    ldconfig -p | grep "libosg" | head -n 5 | awk '{print "  - " $1}'

    # Check for osgviewer
    if command -v osgviewer &> /dev/null; then
        OSG_VERSION=$(osgviewer --version 2>&1 | head -n1 || echo "Unable to get version")
        print_result 0 "osgviewer found"
        print_info "$OSG_VERSION"
    fi
else
    print_result 1 "OpenSceneGraph libraries not found"
fi
echo ""

echo "6. Checking Python environment..."
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    print_result 0 "Python3 found: $PY_VERSION"

    # Check required packages
    for package in numpy pexpect PIL cv2; do
        if python3 -c "import $package" 2>/dev/null; then
            print_result 0 "Python package '$package' installed"
        else
            print_result 1 "Python package '$package' NOT installed"
        fi
    done
else
    print_result 1 "Python3 not found"
fi
echo ""

echo "7. Checking Weather Particle Simulator binary..."
if [ -f "/workspace/3rdparty/weather-particle-simulator/lin_x64/AHLSimulation" ]; then
    print_result 0 "AHLSimulation binary found"

    # Check if executable
    if [ -x "/workspace/3rdparty/weather-particle-simulator/lin_x64/AHLSimulation" ]; then
        print_result 0 "AHLSimulation is executable"
    else
        print_result 1 "AHLSimulation is not executable"
    fi

    # Check library dependencies
    print_info "Checking binary dependencies..."
    if ldd /workspace/3rdparty/weather-particle-simulator/lin_x64/AHLSimulation | grep -q "not found"; then
        print_result 1 "Some library dependencies are missing:"
        ldd /workspace/3rdparty/weather-particle-simulator/lin_x64/AHLSimulation | grep "not found"
    else
        print_result 0 "All binary dependencies satisfied"
    fi
else
    print_result 1 "AHLSimulation binary not found"
    print_info "Make sure the project files are mounted to /workspace"
fi
echo ""

echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

echo "=========================================="
echo "Build Logs Location"
echo "=========================================="
if [ -f "/var/log/opencv-build/opencv-cmake-output.log" ]; then
    echo -e "${YELLOW}[INFO]${NC} OpenCV CMake output log: /var/log/opencv-build/opencv-cmake-output.log"
fi
if [ -f "/var/log/opencv-build/opencv-cmake-error.log" ]; then
    echo -e "${YELLOW}[INFO]${NC} OpenCV CMake error log: /var/log/opencv-build/opencv-cmake-error.log"
    if [ -s "/var/log/opencv-build/opencv-cmake-error.log" ]; then
        echo -e "${YELLOW}[WARNING]${NC} Error log is not empty - there may have been build issues"
    fi
fi
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Container is ready to use.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the errors above.${NC}"
    echo -e "${YELLOW}[TIP]${NC} Check build logs at /var/log/opencv-build/ for more details"
    exit 1
fi
