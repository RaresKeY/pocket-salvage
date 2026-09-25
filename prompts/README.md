# Prompt Records

- [source/](source/README.md) preserves originating user directives verbatim.
- [image/](image/README.md) holds one Markdown file per exact image-generation or edit prompt, created only after an actual request is sent.

Keep record metadata outside the exact prompt block. Each generation record identifies its purpose, input reference paths, output paths, tool/settings known at the time, and selection status. Save each revision separately; never reconstruct an exact prompt from memory or silently replace an earlier record.

When generation begins, keep a compact `prompts/image_inventory.jsonl`: one record per output with `prompt_path`, `input_paths`, `output_path`, `purpose`, and `status` (`candidate`, `selected`, or `rejected`). Use project-relative paths and link selected decisions from `design/`. Preserve useful candidates and non-reproducible provenance; temporary reproducible outputs follow [artifact retention](../artifacts/README.md).

[`image_inventory.jsonl`](image_inventory.jsonl) lists the Bitwright scrapyard outputs, one line per frame. Illustrative prompts in `examples/` are not generation records.
