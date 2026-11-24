# Inkling-2-Mini on one RTX 5090 (chat and coding, single user)

The fastest setup found on this card that keeps output quality equal to the official serving. Everything is built
from pinned sources, and the model pack is converted locally from the official checkpoint.

## Pins

| Part | Pin |
|---|---|
| Model | `thinkingmachines/Inkling-2-Mini` @ `7a67ae2314b44ef05c87fd1d4d311c58aaeb18f6` |
| Engine | this repo, branch `main` (Basalt `b8702c7` + our router kernel commit) |
| Toolchain | CUDA 13.0.88, GCC 13.3, CMake 4.4.5 (pip), Python 3.12, driver 620.70 |
| Card | RTX 5090 32 GB, **host power cap 400 W** (stock 575 W), Ryzen 9 7950X, 64 GB RAM |

## Build and run

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBASALT_MODELS=inkling2
cmake --build build -j
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

recipes/rtx5090/convert.sh     # 37 s -> 19.61 GB,
                               # SHA-256 0a469fe5e81658619defb1d4795abcacf8fd1717aa0260afedc96e854f21f558
recipes/rtx5090/serve.sh
```

- **Context 262,144 tokens**, fp16 KV, every expert on the card, 28.3 GiB of GPU memory. No speed cost against 8K
  (measured).
- **`--answer-room 0`** makes the server behave like vLLM and SGLang: it never cuts the model's thinking short. The
  default (`auto`) caps thinking at ¾ of `max_tokens` and forces it closed, which at small caps puts a ~65 ms pause
  mid-answer. Clients should give `max_tokens` room for thinking (a few thousand is plenty at the default effort).
- Kept at defaults on purpose: fp16 KV (int8/fp8 gave no speed here), draft window 8, prompt cache on.
- **Several users at once:** this build serves one request at a time by default. At 8 concurrent requests vLLM
  generated 1,096 tok/s total against 620 here; a batched setup is future work.

## Quality: measured, same as the official serving

Greedy, `reasoning_effort: low`, on this card. vLLM is the release's own serving path.

| Test | vLLM | This recipe | Items only one got right (ours / vLLM) |
|---|---:|---:|---|
| GSM8K, all 1,319 | 96.66% | 96.51% | 7 / 9 |
| HumanEval, all 164, code executed | 96.34% | 95.12% | 2 / 4 |

No statistically detectable difference. Raw totals: [`evals-summary.jsonl`](evals-summary.jsonl). Chat checks at
262K context: 3/3 needles at 58K, 117K and 235K tokens; tool call and tool-result round trip correct; multi-turn
reuses the cached prefix (9,477 of 9,544 tokens, turn 2 in 0.48 s).

Weights: experts are the release's own NVFP4/MXFP8 bits. Attention projections are Q8_0 of the bf16 weights and the
output head is rounded to Q8_0 at load (KLD 0.00297, top-1 97.83% against a bf16-dequantized reference). The task
results above are the check that matters.

## Speed on this card (400 W)

**LocalMaxxing protocol** (official `lmx` v0.1.66, canonical prompts, greedy, 256 output tokens, 1 warm-up +
3 timed, median). Submitted and verified:

| Run | Prompt | Output tok/s | TTFT | Prompt tok/s |
|---|---|---:|---:|---:|
| `cmwu64132000zox01hngcpwy0` | `code-v1` | **526.2** | **63.47 ms** | 3,824 |
| `cmwu640ro000wox0180bitp9c` | `reasoning-v1` | 481.0 | 65.68 ms | **4,464** |

Spread over 6 fresh server sessions with our kernel: `code-v1` 469.9–528.5 tok/s (median 492.3), TTFT 62.3–64.1 ms;
`reasoning-v1` 457.6–492.3 (median 483.8), TTFT 65.3–65.7 ms. Long prompts read at ~15,900 tok/s.

The router kernel: engine time to first token 32.8 → 29.7 ms at 28 tokens and 43.8 → 40.9 ms at 161 tokens
(controls on both sides), greedy output byte-identical.

## Known limits

- The card is power-capped at 400 W by the host, and decode runs at the cap. Other 5090s score ~5% higher on the same
  engine.
- Short-prompt time to first token has a floor: any prompt over ~16 tokens touches nearly all 128 experts in all 48
  layer visits, about 29 GB of reads, at least 17.5 ms at this card's bandwidth. We run at ~60% of that floor.
