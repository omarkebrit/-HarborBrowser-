These media files are original test assets generated for this project, with no external video or audio content.

`video.mp4` is a six-second 160×90 H.264 Constrained Baseline video, 12 fps, with a 440 Hz mono AAC-LC audio track. The HLS playlist contains the same elementary streams, divided into three MPEG-TS segments. Both transports therefore exercise a real audio and video decoder.

Regeneration (FFmpeg):

```sh
ffmpeg -f lavfi -i testsrc2=size=160x90:rate=12 -f lavfi -i sine=frequency=440:sample_rate=44100 -t 6 -c:v libx264 -profile:v baseline -pix_fmt yuv420p -g 24 -c:a aac -b:a 48k -movflags +faststart video.mp4
ffmpeg -i video.mp4 -c copy -hls_time 2 -hls_playlist_type vod -hls_segment_filename segment%02d.ts playlist.m3u8
```

The acceptance server provides HEAD, byte ranges, MIME types and attachment responses. XCUITest controls the installed app and taps HTML controls through the genuine browser. JavaScript status labels are derived from decoded dimensions, displayed video frames, elapsed playback time and the player's paused state. They are fixture diagnostics, not substitutes for the browser engine.
