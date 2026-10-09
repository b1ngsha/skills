# Superseding design records

The disclosed branch of [`find-simplifications`](SKILL.md): how to retire a design record (ADR, design note, decision log) that a shipped simplification has overtaken. Reached only when the user asks to reduce the record set or the change being implemented obsoletes an owning record.

## Find the current owner

Shipped code, configuration, generated catalogs, package docs, newer records, and inbound links decide which record is current. Dates and titles are discovery hints, not proof.

## Classify the supersession

- **Full**: nothing the old record decided is still live.
- **Partial**: any surviving behavior, current contract, durable format, compatibility obligation, or independently current rejected alternative keeps it live. Rationale that can be transferred to the current owner does not by itself make supersession partial.

A record still marked proposed is never retired by this process. A rejected record stays only while the alternative it rejects still tempts someone; once it no longer prevents a plausible mistake, delete it.

## Retire a fully superseded record

1. Move every unique rationale, alternative, consequence, shipped verification evidence, and named coverage gap into the current owner. An inventory that only describes deleted implementation mechanics is not a decision fact and does not move.
2. Repair every inbound link.
3. Delete the record together with its counterparts — translations, index entries, consistency or sync records.
4. Search exact filenames, symbols, config keys, event names, and wire strings after the edit; a stale reference anywhere means step 2 or 3 is unfinished.

Keep partial supersessions cross-linked in both directions and current.

## Added-then-removed features

A feature that was added and later removed is the common full-supersession case. Let the removal record own the whole history only when all of these hold:

- The feature is absent from production code, configuration, schemas, durable or wire formats, migration, and compatibility behavior.
- No current documentation presents it as available.
- No test exercises it as supported behavior. Tests that enforce its absence may remain.

The removal record then preserves: why the feature originally existed, why that motivation stopped justifying it, the alternatives to full removal, the capability given up, the conditions for reintroduction, and the evidence that removal is complete. Old tests and implementation mechanics that verified only the deleted behavior are not current verification evidence.

## Keep the record when

- The removal covers only one transport, default, implementation, or presentation of a feature that otherwise survives.
- Persisted data or compatibility handling for the feature still exists.
- The removal record does not yet carry enough rationale to prevent accidental reintroduction. A current negative decision may legitimately need its own record even though the implementation it rejects is gone.
