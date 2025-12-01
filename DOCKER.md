# Docker Setup for Weather Particle Simulator

This Docker container provides a complete environment for the weather-particle-simulator project with all required dependencies pre-installed.

> **Quick Start**: New to Docker? Check out [QUICKSTART_DOCKER.md](QUICKSTART_DOCKER.md) for a step-by-step guide!
>
> **Convenience**: Use the included [Makefile](Makefile) for easy commands like `make build`, `make run`, and `make verify`.

## Dependencies Included

- **Ubuntu 20.04** base image
- **C++11** compiler support
- **OpenCV 3.2.0** - Built from source with optimizations
- **Boost 1.62.0** - Full library installation
- **OpenSceneGraph 3.4.1** - 3D graphics toolkit
- **Python 3** with required packages (pexpect, numpy, opencv-python, pillow)

## Prerequisites

- Docker installed on your system ([Install Docker](https://docs.docker.com/get-docker/))
- Docker Compose (usually included with Docker Desktop)
- At least 10GB of free disk space for the image
- (Optional) NVIDIA Docker runtime for GPU support

## Building the Container

### Option 1: Using Docker directly

```bash
# Build the image (takes ~20-30 minutes on first build)
docker build -t weather-particle-simulator:latest .

# Verify the build
docker images | grep weather-particle-simulator
```

### Option 2: Using Docker Compose

```bash
# Build the image
docker-compose build

# Or build with no cache (clean build)
docker-compose build --no-cache
```

## Running the Container

### Interactive Shell

```bash
# Using Docker
docker run -it --rm \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  /bin/bash

# Using Docker Compose
docker-compose run --rm weather-simulator
```

### Running the Weather Particle Simulator

```bash
# Test that all dependencies are installed correctly
docker run -it --rm \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  bash -c "cd /workspace/3rdparty/weather-particle-simulator/lin_x64 && ./AHLSimulation"

# If successful, you'll see the simulator start. Type '0' and press Enter to exit.
```

### Running the Rain Rendering Project

```bash
# Using main script
docker run -it --rm \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  python3 main.py

# Using threaded version
docker run -it --rm \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  python3 main_threaded.py

# Using Docker Compose
docker-compose run --rm rain-rendering
```

## X11 Forwarding (for GUI applications on Linux)

If you need to run GUI applications (like the weather simulator with visualization):

```bash
# Allow Docker to access X server
xhost +local:docker

# Run with X11 forwarding
docker run -it --rm \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  bash

# When done, remove access
xhost -local:docker
```

Or use Docker Compose (X11 forwarding is already configured):

```bash
xhost +local:docker
docker-compose run --rm weather-simulator
xhost -local:docker
```

## Volume Mounts

The container is configured to mount the following directories:

- Current directory → `/workspace` (main project files)
- `./data` → `/workspace/data` (input/output data)
- `./config` → `/workspace/config` (configuration files)

All changes in these directories are persisted on your host machine.

## Troubleshooting

### Build Issues

**Problem**: Build fails with "unable to download boost/opencv/osg"
```bash
# Solution: Check your internet connection and retry
docker build --no-cache -t weather-particle-simulator:latest .
```

**Problem**: Out of disk space
```bash
# Clean up old Docker images and containers
docker system prune -a
```

### Runtime Issues

**Problem**: `./AHLSimulation` fails with library not found
```bash
# Solution: Check that libraries are correctly installed
docker run -it --rm weather-particle-simulator:latest ldconfig -p | grep -E "boost|opencv|osg"
```

**Problem**: Permission denied errors
```bash
# Solution: Run with your user ID
docker run -it --rm \
  -u $(id -u):$(id -g) \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  /bin/bash
```

**Problem**: X11 forwarding not working
```bash
# On Linux, ensure xhost is allowing connections
xhost +local:docker

# On macOS, install XQuartz and set DISPLAY
# export DISPLAY=host.docker.internal:0

# On Windows, use VcXsrv or Xming
```

## Advanced Usage

### Custom Python Dependencies

If you need additional Python packages:

```bash
# Enter the container
docker run -it --rm -v $(pwd):/workspace weather-particle-simulator:latest bash

# Install packages
pip3 install <package-name>
```

Or modify the Dockerfile and add packages to the `pip3 install` command.

### Multi-stage Builds

The Dockerfile uses a multi-stage build to reduce final image size:
- **Builder stage**: Compiles all dependencies from source
- **Runtime stage**: Contains only runtime libraries and binaries

### Debugging

```bash
# Enter the builder stage for debugging
docker build --target builder -t weather-particle-simulator:builder .
docker run -it --rm weather-particle-simulator:builder /bin/bash
```

## Performance Notes

- **Build time**: First build takes 20-30 minutes depending on your machine
- **Image size**: Final image is approximately 2-3GB
- **Build cache**: Subsequent builds are much faster if dependencies haven't changed
- **CPU usage**: Compilation uses all available cores (`-j$(nproc)`)

## Updating Dependencies

To update to different versions, modify the Dockerfile:

```dockerfile
# For OpenCV (change version in wget URL)
wget -q -O opencv.zip https://github.com/opencv/opencv/archive/X.Y.Z.zip

# For Boost (change version in URL and folder name)
wget -q https://sourceforge.net/projects/boost/files/boost/X.Y.Z/boost_X_Y_Z.tar.gz

# For OpenSceneGraph (change version in wget URL)
wget -q -O osg.zip https://github.com/openscenegraph/OpenSceneGraph/archive/OpenSceneGraph-X.Y.Z.zip
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Docker Build

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: recursive

      - name: Build Docker image
        run: docker build -t weather-particle-simulator:latest .

      - name: Test installation
        run: |
          docker run --rm weather-particle-simulator:latest \
            ldconfig -p | grep -E "boost|opencv|osg"
```

## License

This Dockerfile is provided as-is for building the weather-particle-simulator environment. Please refer to individual component licenses:
- Weather Particle Simulator: MIT License (Carnegie Mellon University)
- OpenCV: Apache 2.0 License
- Boost: Boost Software License
- OpenSceneGraph: OpenSceneGraph Public License (OSGPL)

## References

- [Weather Particle Simulator](https://github.com/astra-vision/weather-particle-simulator)
- [OpenCV Installation Guide](https://linuxize.com/post/how-to-install-opencv-on-ubuntu-18-04/)
- [Boost Installation](https://stackoverflow.com/questions/12578499/how-to-install-boost-on-ubuntu/41272796#41272796)
- [OpenSceneGraph Installation](https://vicrucann.github.io/tutorials/osg-linux-quick-install/)
