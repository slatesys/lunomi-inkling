# Lunomi Inkling

The fastest single-user serving of [Inkling-2-Mini](https://huggingface.co/thinkingmachines/Inkling-2-Mini) we know of,
tuned per GPU, with output quality equal to the official serving.

**#1 on [LocalMaxxing](https://localmaxxing.com/en/models/thinkingmachines/Inkling-2-Mini)** for Inkling-2-Mini on one
RTX 5090 (verified runs):

| Prompt | Output tok/s | Time to first token | Prompt tok/s |
|---|---:|---:|---:|
| `code-v1` | **526.2** | **63.47 ms** | 3,824 |
| `reasoning-v1` | 481.0 | 65.68 ms | **4,464** |

Measured on a host-capped 400 W RTX 5090 (stock is 575 W), 262,144-token context, greedy.

## What is in this repo

- **The engine** (this tree): a C++/CUDA inference engine for NVIDIA Blackwell, with our kernel changes on top. Built
  from [Basalt](https://github.com/jesdga95/basalt) by Jesús Gulfo (MIT); see [Credits](#credits).
- **Recipes per GPU** in [`recipes/`](recipes/): exact pins, build and launch commands, quality results and the
  measured speed.

| GPU | Status | Recipe |
|---|---|---|
| RTX 5090 (32 GB, Blackwell) | Done: #1 on LocalMaxxing | [`recipes/rtx5090`](recipes/rtx5090/) |
| RTX 4090 (24 GB, Ada) | Planned | [`recipes/rtx4090`](recipes/rtx4090/) |
| RTX 3090 (24 GB, Ampere) | Planned | [`recipes/rtx3090`](recipes/rtx3090/) |

## Our changes

| Change | Effect | Quality |
|---|---|---|
| Small-tile router kernel for short prompts (`src/kernels/cuda/dense_ops.cu`) | Time to first token −3 ms on short prompts; long prompts unchanged | Lossless: greedy output byte-identical on 8 prompts up to 12K tokens |
| Dense Q8 linears: two output rows per block for 3-token verify windows (`src/kernels/cuda/native_mmvq.cu`) | Step time −1.8% on 3-token windows (the most common), −0.7% overall (RTX PRO 6000, 16,000+ windows) | Lossless: byte-identical, each row keeps its summation order |
| Serving settings (`--answer-room 0`, full 262K context) | The model's thinking is never cut short; no speed cost for the long context | Same as the official serving (see the recipe) |

Every change is lossless or labelled. Each is one commit on top of the pinned base, so it can be reviewed, reverted or
offered upstream on its own.

## Quick start (RTX 5090, Linux, CUDA 13)

```sh
git clone https://github.com/slatesys/lunomi-inkling && cd lunomi-inkling
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DBASALT_MODELS=inkling2
cmake --build build -j
pip install -r requirements.txt
recipes/rtx5090/convert.sh            # converts the official checkpoint into a model pack (19.6 GB)
recipes/rtx5090/serve.sh              # OpenAI-compatible server on 127.0.0.1:8080
```

Full details, quality results and the measurement protocol: [`recipes/rtx5090/README.md`](recipes/rtx5090/README.md).

## Credits

The engine is built from [Basalt](https://github.com/jesdga95/basalt) by Jesús Gulfo, MIT licensed, at commit
`b8702c7`. Its full history is kept in this repo and its licence is in [`LICENSE`](LICENSE), with third-party notices
in [`THIRD_PARTY_LICENSES`](THIRD_PARTY_LICENSES). The upstream README is kept as
[`UPSTREAM-README.md`](UPSTREAM-README.md). The binaries keep the upstream names (`bin/basalt`).

Follow us: [x.com/LunomiCloud](https://x.com/LunomiCloud).
