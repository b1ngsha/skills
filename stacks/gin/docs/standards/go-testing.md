# Go Testing Standard

A behaviour is asserted once, at the layer that owns it. Before adding a
test, name the owner. Before keeping a test, ask: if this file disappeared,
would any bug become uncaught? When another layer already catches it, delete
this copy. When nothing catches it, move the assertion to the owner.

## Owners

| Layer | Owns |
| --- | --- |
| The package that decides the rule | Business rules, state transitions, validation |
| The package that talks to a database | SQL translation and constraint outcomes, against a real database |
| The HTTP handler | Routing, decoding, and status mapping, with the inner service fabricated |

Put the assertion in the owner's file. A status code belongs beside the
handler that writes it. A unique-constraint outcome belongs beside the code
that maps that constraint.

## Shape

**Hard.**

- A handler test calls the handler with an `httptest` request. It fabricates
  the service result. It does not open a database to prove a status code.
- A rule test calls the function that owns the rule. It does not boot Gin to
  prove a validation.
- A test name states the behaviour: `TestHealthz` reports liveness, not
  `TestHandler`.

**Judgement.** Two tests that fail on the same bug are one test too many.
Keep the one at the owning layer.
