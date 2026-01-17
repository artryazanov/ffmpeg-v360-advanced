# FFmpeg v360 Filter "Rig Mode" Implementation

This project implements the **"Rig Mode" (TILES)** in the FFmpeg `v360` filter, enabling high-fidelity panoramic stitching from arbitrary multi-camera rigs. It transforms multiple directional square video inputs into a seamless panoramic output (e.g., Equirectangular), featuring dynamic input management and advanced geometric blending.

## Features

- **Dynamic Multi-Input Architecture**: Supports any number of input video streams (cameras).
- **Geometric Calibration**: Per-input Pitch and Yaw configuration via the `cam_angles` option.
- **Advanced Blending**: Weighted Inverse Projection using $C^2$-continuous Hermite interpolation (Smoothstep) for seam-free results.
- **Synchronization**: Integrated `AVFrameSync` to ensure frame-accurate processing of multiple streams.
- **High Bit-Depth Support**: Full support for 8-bit and 16-bit processing pipelines.

## Usage

### Command Line Example
To stitch a 4-camera rig (Front, Right, Back, Left) into an Equirectangular panorama:

```bash
ffmpeg \
 -i cam0.mp4 -i cam1.mp4 -i cam2.mp4 -i cam3.mp4 \
 -filter_complex "
    [0:v][1:v][2:v][3:v] v360=input=tiles:output=equirect:
    cam_angles='0 0 0 90 0 180 0 270':
    rig_fov=90:blend_width=0.05
 " \
 output_panorama.mp4
```

### Options

| Option | Description | Default | Range |
|--------|-------------|---------|-------|
| `input=tiles` | Activates the Rig Mode. | - | - |
| `cam_angles` | List of input camera angles in "Pitch Yaw" pairs (degrees). E.g., `'0 0 0 90'` for two cameras. | NULL | - |
| `rig_fov` | Field of View for the input rig cameras (degrees). Assumes square renders. | 90.0 | 1.0 - 360.0 |
| `blend_width` | Width of the soft-edge blending region (normalized 0.0 - 0.5). Controls seam softness. | 0.05 | 0.0 - 0.5 |

## Technical Implementation

### 1. Data Structures (`libavfilter/v360.h`)
The `V360Context` was extended to support:
- `nb_inputs`: Dynamic tracking of input count.
- `fs`: `FFFrameSync` context for synchronizing multiple streams.
- `input_rot`: Pre-calculated rotation matrices for efficient rendering.

### 2. Initialization & Lifecycle (`libavfilter/vf_v360.c`)
- **Dynamic Inputs**: The `init` function parses `cam_angles` and dynamically allocates input pads (`in0`, `in1`...) using FFmpeg's pad append functions.
- **FrameSync Integration**: The `activate` callback manages frame synchronization for the Rig mode, ensuring all inputs are locked before processing.
- **Configuration**: `config_output` pre-calculates inverse rotation matrices ($R_{total}^{-1} = R_x^T \cdot R_y^T$) to minimize per-pixel math.

### 3. Rendering Core (`remap_rig`)
The new rendering path bypasses fixed-function lookup tables to support dynamic 3D projection:
1.  **Inverse Mapping**: Iterates over every output pixel.
2.  **Global Vector**: Calculates the global 3D vector $\vec{V}_{global}$ for the output projection.
3.  **Multi-Camera Sampling**:
    -   Rotates $\vec{V}_{global}$ into each camera's local space.
    -   Projects to the 2D image plane.
    -   Computes blend weight using `smoothstep(distance)`.
4.  **Accumulation**: A weighted average of all valid samples produces the final pixel color.

## Blending Algorithm
To ensure "wonderful" visual quality, the filter uses a **Weighted Inverse Projection** with **Hermite Interpolation**:
- **Distance Calculation**: The distance $D$ of a pixel from the nearest edge of the input frame is calculated.
- **Smoothstep Weighting**: $W = t^2 \cdot (3 - 2t)$, where $t$ is the normalized distance within the `blend_width`.
- **Seamless Merge**: Weights are accumulated and normalized, ensuring smooth transitions even with vignetting or slight exposure differences.
