# Structured Game Content

Store authored structured game content here when needed. Document its schema, owning subsystem, and validation in the relevant spec. Keep test-only inputs in `tests/` and generated scratch output in ignored artifact buckets.

The only gameplay data so far is the weather profiles.

`weather/` holds one `WeatherProfile` per weather (see `specs/weather.md`). Adding a `.tres` there adds a weather to the round's roll.
