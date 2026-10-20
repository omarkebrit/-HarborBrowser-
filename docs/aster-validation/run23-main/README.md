# Run 23 main UI checkpoint

[Run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), attempt 1, source `4557246b64453abb464844aa8ff4358e90107c5b`, records **15 passed, 1 failed, 0 skipped, 0 expected failures; 16 total**. The sole reported failure is missing `Fullscreen first-loop boundary rotation observed` (54.844 seconds). Its actual main-execution frames and timing must be reviewed from the final attachments before inferring playback behavior or equating it with preflight.

The original acceptance log records all four decoded MP4/HLS/iframe/blob attachment titles and their combined case pass (81.449s), ordinary fullscreen pass (73.988s), and 25-tab creation/relaunch/restoration pass (597.617s). Arabic RTL and large-text cases passed too. This checkpoint contains no screenshot or observation payloads.

[manifest.json](manifest.json) records exact hashes for the three complete unmodified originals and the full source log, which is not copied. Artifact `12261567596` is 491,164 bytes; archive CRC, source and official counts were verified. Required unit/preflight/main gates remain independent, and run 23 cannot publish an IPA after its failures. No signed-device or full-validation claim.
