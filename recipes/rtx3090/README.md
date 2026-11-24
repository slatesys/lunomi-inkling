# Inkling-2-Mini on one RTX 3090: planned

The RTX 3090 (Ampere, sm_86, 24 GB) has neither FP4 nor FP8 tensor cores, and the engine in this repo targets
Blackwell (sm_120) only. Plan:

1. Baseline and tune on an engine that already runs the model on Ampere (vLLM, which unpacks FP4 weights on the fly).
2. Size memory carefully (about 19 GB of weights on a 24 GB card) and sweep speculative-draft settings for this card.
3. Optional and labelled as a quality trade: re-pack to a 4-bit integer format the 3090 runs natively, only if it
   passes the same quality gates as the 5090 recipe.
