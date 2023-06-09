# nebula-base

Base docker image for nebula worker is based on Debian Bullseye with Python 3.11

Contains media processing dependencies such as:

 - ffmpeg
 - libmxf / libbmx
 - MLT framework and melt

TODO:

 - GPU acceleration (nvenc/nvdec) for ffmpeg
 - Switch to Debian Bookworm as soon it seems stable
