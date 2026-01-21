# FFmpeg v360 Filter - Advanced Rig Mode

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Build Status](https://github.com/artryazanov/ffmpeg-v360-advanced/actions/workflows/build.yml/badge.svg)
![FFmpeg Version](https://img.shields.io/badge/FFmpeg-8.0.1%2B-blue)

An advanced extension of the standard FFmpeg `v360` filter, introducing **Rig Mode** for seamless stitching of multi-camera setups. This project provides a robust solution for transforming multiple directional video inputs into a cohesive 360° panoramic output with high-quality blending.

## Visualization

**From Input Rig to Equirectangular Panorama:**

<img src="docs/geometry_diagram.png" alt="Architecture Diagram" width="800" />

**Seamless Stitching Result:**

![Example Result](docs/example_result.gif)

*This video fragment was created by the [Source Engine Panorama Renderer](https://github.com/thegamerbay/source-panorama-renderer) project, which uses this advanced v360 implementation.*

## Mathematical Model

To ensure seamless stitching between camera views, we implement a **Weighted Inverse Projection** algorithm using **Hermite interpolation** with **Cubic Priority** for optimal ghosting reduction.

The blending weight is calculated in two steps:

1.  **Base Smoothness**: A base weight $W_{base}(t)$ is derived from the normalized distance $t$ to the edge of the field of view using Hermite interpolation:

    $$W_{base}(t) = t^2 \cdot (3 - 2t)$$

    Where $t \in [0, 1]$. This ensures $C^1$ continuity at the boundaries.

2.  **Center Priority**: To prioritize the highest quality pixels from the center of the lens and suppress edge artifacts, the final weight $W$ is cubed:

    $$W = (W_{base}(t))^3$$

This non-linear priority weighting significantly improves the visual coherence of the stitched panorama.

## Features

-   **Rig Mode (`input=tiles`)**: Accept an arbitrary number of inputs laid out in a grid (tiled) format.
-   **Priority Blending**: Smart blending that prioritizes "stronger" central pixels over edge pixels to reduce ghosting.
-   **High Fidelity**: Uses high-order interpolation methods for geometry remapping.
-   **Configurable**: Full control over Field of View (FOV), Yaw, Pitch, Roll, and Blend Width.

## Integration / Build Steps

This repository is designed as an extension patch for FFmpeg.

### Prerequisites
-   Linux environment or WSL (Windows Subsystem for Linux)
-   Dependencies: `build-essential`, `yasm`, `nasm`, `pkg-config`, `libx264-dev` (and other FFmpeg deps)

### 1. Build using the helper script (Recommended)
We provide a script to automate the cloning, patching, and building process.

```bash
./scripts/build_ffmpeg.sh
```

### 2. Manual Integration
If you prefer to integrate manually into your own FFmpeg source tree:

```bash
# 1. Clone FFmpeg
git clone https://github.com/FFmpeg/FFmpeg.git
cd FFmpeg
git checkout n8.0.1  # Recommended version

# 2. Apply the patch
# Assuming you are in the root of the FFmpeg repo and have this repo at ../ffmpeg-v360-advanced
git am ../ffmpeg-v360-advanced/patches/0001-Add-Rig-Mode-implementation.patch

# OR copy files manually
# cp ../ffmpeg-v360-advanced/src/vf_v360.c libavfilter/
# cp ../ffmpeg-v360-advanced/src/v360.h libavfilter/

# 3. Configure and Build
./configure --enable-filter=v360 --enable-gpl --enable-libx264
make -j$(nproc)
```

## Usage Example

Once built, you can use the `v360` filter with the new `input=tiles` option.

```bash
ffmpeg -i input_rig_tiled.mp4 -vf "v360=input=tiles:output=e:h_fov=60:v_fov=60:...:blend_width=0.1" output_panorama.mp4
```

*See source code comments for full parameter list.*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Original `v360` filter Copyright (c) 2019 Eugene Lyapustin.
Rig Mode implementation Copyright (c) 2026 Artem Ryazanov.
