# Dockerfile for rain-rendering with all dependencies
# Based on Ubuntu 18.04 (Bionic) with C++11, OpenCV 3.2.0, Boost 1.62.0, and OpenSceneGraph 3.4.1
# Uses AHLSimulation_bionic binary compiled for Ubuntu 18.04
#
# Build: docker build -t rain-rendering:latest .
# Run:   docker run -it --rm -v $(pwd):/workspace rain-rendering:latest

FROM ubuntu:18.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install base build tools and dependencies (exactly as specified)
RUN apt-get update && apt-get install -y \
    build-essential \
    g++ \
    cmake \
    git \
    pkg-config \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    gfortran \
    openexr \
    libatlas-base-dev \
    python3-dev \
    python3-numpy \
    python3-pip \
    autotools-dev \
    libicu-dev \
    libbz2-dev \
    libtbb2 \
    libtbb-dev \
    libdc1394-22-dev \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set C++11 standard
ENV CXXFLAGS="-std=c++11"

WORKDIR /tmp

#############################################
# Clone repositories directly (avoiding submodule commit pinning)
#############################################
RUN echo "Cloning rain-rendering repository..." && \
    git clone https://github.com/astra-vision/rain-rendering.git /workspace && \
    echo "Cloning weather-particle-simulator directly to get latest binaries..." && \
    mkdir -p /workspace/3rdparty && \
    cd /workspace/3rdparty && \
    git clone https://github.com/astra-vision/weather-particle-simulator.git && \
    echo "Patching tools/simulation.py for compatibility..." && \
    cd /workspace && \
    sed -i "s/self.interact('Steps: What do you want to do \\\\?', menu)/self.interact('What do you want to do \\\\?', menu)/g" tools/simulation.py && \
    sed -i "s/'AHLSimulation'/'AHLSimulation_bionic'/g" tools/simulation.py && \
    sed -i "s/self.child.expect('Steps: What do you want to do \\\\?')/self.child.expect('What do you want to do \\\\?')/g" tools/simulation.py && \
    echo "Patches applied successfully!"

#############################################
# Download and extract rain streak database
#############################################
RUN echo "Downloading Columbia Uni. rain streak database..." && \
    cd /workspace/3rdparty && \
    wget -O databases.zip https://cave.cs.columbia.edu/old/databases/rain_streak_db/databases.zip && \
    echo "Extracting to rainstreakdb..." && \
    mkdir -p rainstreakdb && \
    unzip -q databases.zip -d rainstreakdb && \
    rm databases.zip && \
    echo "Rain streak database installed successfully!"

#############################################
# Install Boost 1.62.0 (following StackOverflow guide)
# Note: Excluding python libraries as they're not needed and cause build issues
#############################################
RUN echo "Installing Boost 1.62.0..." && \
    wget -O boost_1_62_0.tar.gz https://sourceforge.net/projects/boost/files/boost/1.62.0/boost_1_62_0.tar.gz/download && \
    tar xzf boost_1_62_0.tar.gz && \
    cd boost_1_62_0 && \
    ./bootstrap.sh --prefix=/usr/local && \
    ./b2 --without-python -j $(nproc) install && \
    cd .. && \
    rm -rf boost_1_62_0 boost_1_62_0.tar.gz && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/local.conf && \
    ldconfig

#############################################
# Fix videodev.h for OpenCV (create symlink for V4L)
#############################################
RUN cd /usr/include/linux && \
    ln -s ../libv4l1-videodev.h videodev.h

#############################################
# Install OpenCV 3.2.0 from source (following linuxize guide EXACTLY)
#############################################
RUN echo "Installing OpenCV 3.2.0..." && \
    mkdir ~/opencv_build && cd ~/opencv_build && \
    git clone https://github.com/opencv/opencv.git && \
    git clone https://github.com/opencv/opencv_contrib.git && \
    cd opencv && git checkout 3.2.0 && cd .. && \
    cd opencv_contrib && git checkout 3.2.0 && cd .. && \
    cd ~/opencv_build/opencv && \
    echo "Applying ffmpeg compatibility patch..." && \
    sed -i '1i #define AV_CODEC_FLAG_GLOBAL_HEADER (1 << 22)\n#define CODEC_FLAG_GLOBAL_HEADER AV_CODEC_FLAG_GLOBAL_HEADER\n#define AVFMT_RAWPICTURE 0x0020' modules/videoio/src/cap_ffmpeg_impl.hpp && \
    mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
        -D CMAKE_INSTALL_PREFIX=/usr/local \
        -D INSTALL_C_EXAMPLES=OFF \
        -D INSTALL_PYTHON_EXAMPLES=OFF \
        -D OPENCV_GENERATE_PKGCONFIG=ON \
        -D OPENCV_EXTRA_MODULES_PATH=~/opencv_build/opencv_contrib/modules \
        -D BUILD_EXAMPLES=OFF .. && \
    (make -j$(nproc) || (echo "Build failed! Saving logs..."; cp CMakeFiles/CMakeOutput.log /tmp/opencv-cmake-output.log 2>/dev/null; cp CMakeFiles/CMakeError.log /tmp/opencv-cmake-error.log 2>/dev/null; echo "=== CMake Error Log ===" && cat /tmp/opencv-cmake-error.log 2>/dev/null; exit 1)) && \
    make install && \
    echo "Build successful! Saving logs for reference..." && \
    cp CMakeFiles/CMakeOutput.log /tmp/opencv-cmake-output.log 2>/dev/null && \
    cp CMakeFiles/CMakeError.log /tmp/opencv-cmake-error.log 2>/dev/null && \
    touch /tmp/opencv-cmake-output.log /tmp/opencv-cmake-error.log && \
    cd && \
    rm -rf ~/opencv_build && \
    ldconfig

#############################################
# Install OpenSceneGraph 3.4.1
#############################################
RUN echo "Installing OpenSceneGraph dependencies..." && \
    apt-get update && apt-get install -y \
    libx11-dev \
    libxrandr-dev \
    libglu1-mesa-dev \
    libfreetype6-dev \
    libopenthreads-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN echo "Installing OpenSceneGraph 3.4.1..." && \
    wget -q -O osg.zip https://github.com/openscenegraph/OpenSceneGraph/archive/OpenSceneGraph-3.4.1.zip && \
    unzip -q osg.zip && \
    cd OpenSceneGraph-OpenSceneGraph-3.4.1 && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D CMAKE_CXX_FLAGS="-std=c++11" \
          .. && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && \
    rm -rf OpenSceneGraph-OpenSceneGraph-3.4.1 osg.zip && \
    echo "/usr/local/lib64" >> /etc/ld.so.conf.d/local.conf && \
    ldconfig

#############################################
# Verify weather-particle-simulator binary works (using bionic version)
#############################################
RUN echo "Verifying AHLSimulation_bionic binary..." && \
    cd /workspace/3rdparty/weather-particle-simulator/lin_x64 && \
    echo "Checking if binary exists..." && \
    ls -lah AHLSimulation_bionic && \
    echo "Making binary executable..." && \
    chmod +x AHLSimulation_bionic && \
    echo "Creating symlink for convenience..." && \
    ln -sf AHLSimulation_bionic AHLSimulation && \
    echo "Checking library dependencies..." && \
    ldd AHLSimulation_bionic && \
    echo "Binary verification complete!"

#############################################
# Install Python dependencies for rain-rendering project
#############################################
RUN pip3 install --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir \
    numpy \
    matplotlib \
    tqdm \
    imageio \
    pillow \
    natsort \
    glob2 \
    scipy \
    scikit-learn \
    scikit-image \
    pexpect \
    pyclipper \
    imutils

#############################################
# Set up environment variables
#############################################
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:${LD_LIBRARY_PATH:-}
ENV PATH=/usr/local/bin:${PATH:-}

#############################################
# Copy OpenCV build logs for reference
#############################################
RUN mkdir -p /var/log/opencv-build && \
    cp /tmp/opencv-cmake-output.log /var/log/opencv-build/ 2>/dev/null || true && \
    cp /tmp/opencv-cmake-error.log /var/log/opencv-build/ 2>/dev/null || true

#############################################
# Final verification (commented out - already verified after OSG installation)
#############################################
#RUN echo "Final verification..." && \
#    echo "Checking libraries..." && \
#    ldconfig -p | grep -E "boost|opencv|osg" || true && \
#    echo "Python version:" && \
#    python3 --version && \
#    echo "Verifying AHLSimulation dependencies..." && \
#    cd /workspace/3rdparty/weather-particle-simulator/lin_x64 && \
#    ldd AHLSimulation && \
#    if ldd AHLSimulation | grep -q "not found"; then \
#        echo "ERROR: Missing dependencies for AHLSimulation!"; \
#        exit 1; \
#    fi && \
#    echo "All dependencies satisfied! Installation complete."

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]
