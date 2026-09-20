# OBS Studio Legacy NVENC Fix for Arch & Manjaro Linux

A standalone build script to fix `outdated_driver` / `obs_nvenc_h264_tex not found` errors in **OBS Studio 32.x** on Arch Linux and Manjaro for older NVIDIA GPUs (Pascal / Maxwell, e.g., GTX 1050, 1060, 1070, 1080, 960M, 970, 980).

---

## 🔍 The Problem

* Arch Linux and Manjaro recently updated `ffnvcodec-headers` to **SDK 13.1**, and FFmpeg / OBS packages require NVIDIA driver version **610.00+**.
* Legacy GeForce cards (GTX 900 & 1000 series) are on the **570.xx / 580.xx** driver series, which only provides **NVENC SDK 13.0**.
* On launch, OBS Studio performs a driver check (`nvenc_check`), flags the driver as `outdated_driver`, and disables NVENC entirely. This causes Twitch Enhanced Broadcasting and hardware NVENC recording to fail.
* Furthermore, Arch's transition to `mbedtls 4` causes compile-time errors unless explicitly linked against `mbedtls3`.

## 💡 The Solution

This script automates:
1. Installing the required development packages (`swig`, `vulkan-headers`, `nlohmann-json`, `mbedtls3`, etc.).
2. Installing **`nv-codec-headers` version 13.0.19.1** to match the 570/580 driver.
3. Patching CMake paths for **MbedTLS 3**.
4. Compiling and installing OBS Studio natively for your system.

---

## 🚀 Usage

### 1. Clone this repository
```bash
git clone https://github.com/<your-username>/obs-legacy-nvenc-arch.git
cd obs-legacy-nvenc-arch
chmod +x build-obs-nvenc-legacy.sh
