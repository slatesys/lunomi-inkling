# Inkling-2-Mini on one RTX 4090: planned

The RTX 4090 (Ada, sm_89, 24 GB) has FP8 tensor cores but no FP4, and the engine in this repo targets Blackwell
(sm_120) only. Plan:

1. Baseline and tune on an engine that already runs the model on Ada (vLLM, which unpacks FP4 weights on the fly).
2. Profile, then write our own kernels where they pay: grouped expert GEMMs that unpack FP4 to FP8 and use the
   4090's FP8 hardware.
3. Same quality gates as the 5090 recipe (full GSM8K, executed HumanEval, long-context needles) before any number
   counts.
