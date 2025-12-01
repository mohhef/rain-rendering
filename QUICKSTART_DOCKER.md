# Docker Quick Start Guide

This guide will get you up and running with the Weather Particle Simulator Docker container in minutes.

## Prerequisites

- Docker installed ([Get Docker](https://docs.docker.com/get-docker/))
- At least 10GB free disk space
- 4GB+ RAM recommended

## Quick Start (3 steps)

### 1. Build the Container

```bash
# Option A: Using Makefile (recommended)
make build

# Option B: Using Docker directly
docker build -t weather-particle-simulator:latest .

# Option C: Using Docker Compose
docker-compose build
```

**Note**: First build takes 20-30 minutes as it compiles OpenCV, Boost, and OpenSceneGraph from source.

### 2. Verify Installation

```bash
# Using Makefile
make verify

# Using Docker directly
docker run -it --rm -v $(pwd):/workspace weather-particle-simulator:latest /workspace/scripts/verify_docker.sh
```

You should see output indicating all dependencies are correctly installed:
```
Tests passed: 15
Tests failed: 0
All tests passed! Container is ready to use.
```

### 3. Run the Simulator

```bash
# Test the weather particle simulator binary
make test-simulator

# Or run your Python scripts
make run

# Or get an interactive shell
make shell
```

## Common Use Cases

### Interactive Development

```bash
# Start a shell with your code mounted
make shell

# Inside the container, you can:
cd /workspace
python3 main_threaded.py
cd 3rdparty/weather-particle-simulator/lin_x64
./AHLSimulation
```

### Running Python Scripts

```bash
# Run the main script
docker run -it --rm \
  -v $(pwd):/workspace \
  weather-particle-simulator:latest \
  python3 main.py

# Or use the Makefile shortcut
make run
```

### With GUI Support (Linux only)

```bash
# Enable X11 forwarding
make x11-enable

# Run with GUI
make shell-x11

# Inside the container
cd 3rdparty/weather-particle-simulator/lin_x64
./AHLSimulation

# When done, disable X11
make x11-disable
```

## Makefile Commands

The included Makefile provides convenient shortcuts:

```bash
make help              # Show all available commands
make build             # Build the Docker image
make build-no-cache    # Clean build without cache
make shell             # Interactive bash shell
make run               # Run main_threaded.py
make verify            # Verify installation
make test-simulator    # Test the simulator binary
make clean             # Remove Docker image
make info              # Show image information
make ps                # Show running containers
```

## Docker Compose

If you prefer docker-compose:

```bash
# Build
docker-compose build

# Run interactive shell
docker-compose run --rm weather-simulator

# Run the main script
docker-compose run --rm rain-rendering
```

## Troubleshooting

### Build fails with download errors

```bash
# Check internet connection and retry with no cache
make build-no-cache
```

### "Permission denied" when running scripts

```bash
# Make sure scripts are executable
chmod +x scripts/*.sh
```

### Container can't find project files

```bash
# Make sure you're running from the project root directory
pwd  # Should show: .../rain-rendering

# Verify volume mount is working
docker run -it --rm -v $(pwd):/workspace weather-particle-simulator:latest ls -la /workspace
```

### Binary missing libraries

```bash
# Check library dependencies
docker run -it --rm -v $(pwd):/workspace weather-particle-simulator:latest \
  ldd /workspace/3rdparty/weather-particle-simulator/lin_x64/AHLSimulation
```

## Next Steps

- Read [DOCKER.md](DOCKER.md) for detailed documentation
- Check [README.md](README.md) for project documentation
- Review [docker-compose.yml](docker-compose.yml) for service configuration

## Architecture

The Dockerfile uses a multi-stage build:

1. **Builder Stage**: Compiles dependencies from source
   - Boost 1.62.0
   - OpenCV 3.2.0
   - OpenSceneGraph 3.4.1

2. **Runtime Stage**: Copies only needed libraries and binaries
   - Smaller final image (~2-3GB vs ~8GB)
   - Faster container startup

## Example Workflow

Here's a complete workflow example:

```bash
# 1. Clone repository and submodules
git clone <repository-url>
cd rain-rendering
git submodule update --init --recursive

# 2. Build container (one-time, ~30 minutes)
make build

# 3. Verify everything works
make verify

# 4. Test the simulator
make test-simulator
# Type '0' and Enter to exit

# 5. Run your Python code
make shell
# Inside container:
python3 main_threaded.py

# 6. Access results on host
# (Results are saved in ./data or ./output, visible on your host)
```

## Performance Tips

- **First build**: Use `make build` and let it run. Go grab coffee!
- **Rebuilding**: If you only change Python code, you don't need to rebuild
- **Cache**: Docker caches each layer. Builds after the first are much faster
- **Resources**: Allocate more CPU/RAM to Docker if builds are slow

## Getting Help

- `make help` - Show all Makefile commands
- Check [DOCKER.md](DOCKER.md) for detailed documentation
- Verify installation with `make verify`
- Check container logs: `docker logs <container-id>`

## Minimum System Requirements

- **OS**: Linux, macOS, or Windows with WSL2
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 10GB free space
- **CPU**: Multi-core recommended (for faster builds)

## Supported Platforms

- ✅ Ubuntu 18.04+
- ✅ Debian 10+
- ✅ macOS (Intel and Apple Silicon)
- ✅ Windows 10/11 with WSL2

---

**Ready to go?** Start with `make build` and you'll be running simulations in 30 minutes!
