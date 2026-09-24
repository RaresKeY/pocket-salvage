# Creation Tools

Reserve this directory for one-shot utilities that create or transform project material. Tools are not shipped runtime logic and are not the test suite. Document each tool's input, output, dependencies, repeatability, and provenance alongside it when added.

Prototype and orchestrate in Python; use native code for measured bottlenecks. Follow local execution boundaries. Generated output belongs in its owning source area or an appropriate ignored artifact bucket.

No creation tools exist yet. The former `tools/check` verification entry point now lives at [tests/check](../tests/check).
