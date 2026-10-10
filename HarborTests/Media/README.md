These are original, synthesized six-second playback fixtures: an H.264 baseline
test pattern and an AAC 440 Hz tone. No external video content is included.
The committed MP4 is base64-encoded in ../video.b64; this directory contains
the same tracks remuxed into a deterministic HLS VOD playlist. CI needs only
Python to serve them, with no ffmpeg installation or network dependency.

To regenerate with ffmpeg:

```sh
ffmpeg -f lavfi -i 'testsrc2=size=160x90:rate=12:duration=6' \
  -f lavfi -i 'sine=frequency=440:sample_rate=44100:duration=6' \
  -c:v libx264 -profile:v baseline -level:v 3.0 -pix_fmt yuv420p \
  -crf 34 -g 24 -keyint_min 24 -sc_threshold 0 \
  -c:a aac -b:a 24k -ar 44100 -ac 1 -movflags +faststart \
  -shortest /tmp/harbor-video-fixture.mp4
python3 -c "import base64,pathlib; pathlib.Path('HarborTests/video.b64').write_text(base64.b64encode(pathlib.Path('/tmp/harbor-video-fixture.mp4').read_bytes()).decode() + '\\n')"
ffmpeg -i /tmp/harbor-video-fixture.mp4 -c copy -hls_time 2 \
  -hls_list_size 0 -hls_playlist_type vod \
  -hls_segment_filename HarborTests/Media/segment%02d.ts \
  HarborTests/Media/playlist.m3u8
```
