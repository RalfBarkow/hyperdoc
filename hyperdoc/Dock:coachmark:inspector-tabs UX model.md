# Dock/coachmark/inspector-tabs UX model 

[…] The missing piece was exactly that the state model was still being treated as design prose instead of as an inspectable/editable object with implementation evidence.

Use this revised Codex handover prompt:

```text
You are working in ~/workspace/hyperdoc on the current feature branch. Follow AGENTS.md and the established repo conventions. Use nix develop as the authoritative environment for validation. Commit work periodically during implementation, not only at the end. Use plain-text Conventional Commits. Stage only the intended slice.

Task: implement the Dock/coachmark/inspector-tabs UX model discussed in the handover, and make it real in code, tests, and durable documentation.

Additional requirement added in this revision

The Dock/coachmark state model must not exist only implicitly in code or prose. Add a real inspectable/editable view for the state model itself, and link its claims to the implementing source code through claim-code relations.

Core design to implement

1. Treat the inspector tabs as the durable base chrome.
2. Treat the Dock as a coachmark-governed progressive enhancement layer over inspector-tab capabilities, not as a separate permanent toolbar with its own conceptual model.
3. The Dock may appear in order to:
   - introduce a newly relevant gesture or function,
   - expose an active partial interaction,
   - surface guidance when a capability has become newly available,
   - reappear for rediscovery/help on demand.
4. When the Dock recedes, the same capability must remain available in a lighter form. Do not remove the function when the chrome disappears.
5. Degrade chrome, not capability.
6. When the capability is Connect, keep the Touch-Fahrplan-first wording durable: use `Lay route` as the preferred user-facing label, treat topics as stations, treat associations as routes between stations, and keep the route itself first-class.

Required UX model

Implement a small explicit state model for pane-local dock presentation. The exact names can differ, but the semantics must be clear and inspectable. The model should cover at least:

- latent:
  no expanded Dock guidance; pane looks like normal inspector chrome, with compact access to the capability still present
- introduction:
  Dock appears because a capability has become newly relevant and needs teaching
- active:
  Dock remains visible because the user is mid-gesture or mid-flow and stateful controls matter
- mastered/degraded:
  Dock retracts to a lighter form after use/dismissal, but the same capability remains accessible
- rediscovery:
  user can bring the fuller dock/coachmark layer back explicitly, e.g. via help or a compact affordance

This state must not be decorative. Visibility changes should encode something meaningful: newly relevant, active, needs explanation, or safe to recede.

New state-model view requirement

Implement a view for the state model so it can be inspected and edited as a first-class HyperDoc object rather than remaining only in prose or code.

That view should make the following visible in an inspectable way:
- states
- transitions
- entry conditions / triggers
- exit conditions
- degraded/compact representation rules
- which capabilities participate in the model, at least Connect, Annotation, Touch-Fahrplan entry, and DMX handoff/traversal entry where applicable
- for route-authoring surfaces, the conceptual label (`Lay route`) and the underlying mechanic (`drag-to-connect` or `two-tap route-laying`)
- links to the relevant source code implementing each claim

The state-model view should be good enough that a user can answer questions like:
- why is the Dock visible right now?
- why did it recede?
- how does Lay route / Connect differ between introduction and active states?
- what compact affordance remains after degradation?
- where in the code is this rule implemented?

If the current infrastructure already has a suitable relation/view mechanism, extend it. If not, add the narrowest coherent implementation that makes the state model inspectable and editable without introducing a parallel documentation-only dead end.

Claim-code relation requirement

The state model should be linked to source code through claim-code relations.

At minimum:
- each major UX claim in the state-model surface should link to concrete implementing code paths
- the relation should make it possible to navigate from a claim to the relevant functions/files/tests
- durable docs about the Dock/coachmark model should also point to the implementation evidence, not just prose
- where appropriate, include tests as part of the evidence chain

Do not leave the state model as an ungrounded design note. Make it inspectably connected to the implementation.

Route-laying-specific requirements

Implement Connect according to this progressive-enhancement model, but keep the
Touch-Fahrplan route metaphor as the durable conceptual layer.

- First encounter or newly relevant encounter:
  Dock/coachmark may expand and explain `Lay route`.
- Active route-laying gesture:
  the expanded presentation must show task state such as source selected, next expected step, clear/cancel, and state inspection if useful.
- After repeated use or dismissal:
  the expanded presentation may recede, but `Lay route` / Connect must still be available in compact form.
- Help/rediscovery:
  the richer teaching layer must be recoverable on demand.

Use `drag-to-connect` only for low-level mechanic descriptions and
`two-tap route-laying` for the non-drag fallback. Do not use plain `swipe` as
the canonical term.

Do not leave permanent onboarding prose in steady-state chrome. Explanatory
copy is appropriate in introduction mode, not as always-visible toolbar text.

Touch-Fahrplan and DMX requirements

Do not model Touch-Fahrplan and DMX as competing permanent toolbar identities.

Implement them within the same progressive-enhancement grammar:

- the Dock/coachmark layer may introduce the newly relevant possibility,
- the richer route-specific or traversal UI belongs in the pane body or in its own proper surface,
- capability introduction belongs to the coachmark/dock layer,
- full route/traversal UI belongs to the relevant content surface.

In other words:
- the Dock introduces and exposes,
- the pane body hosts the richer route/traversal workflow.

Preserve the DMX mapping that the authored route is itself first-class and that
participant roles such as `player1` and `player2` remain available where they
matter.

Make sure Touch-Fahrplan tiles and DMX-related affordances fit this model instead of reading as unrelated parallel toolbars.

Annotation requirement

Treat Annotation as a sibling capability in the same system. It should participate in the same presentation logic as Connect and Inspect, rather than remaining a disconnected special case.

Implementation constraints

- Preserve current capabilities; do not regress existing gestures just to simplify chrome.
- Prefer narrow, inspectable state transitions over hidden heuristics.
- If there is already a pane-local state object or slot state suitable for this, extend it rather than scattering flags ad hoc.
- Keep the chrome semantically consistent across panes.
- Avoid provider names as permanent dock identity if they are really contextual body-level workflows.
- Avoid a steady-state strip that simultaneously behaves as toolbar, status bar, onboarding prose, and help text.
- The state-model view must be maintained from the same conceptual source of truth as the implementation, or at least tightly enough linked that drift is inspectable.

What to change

Audit and update the relevant code paths for:
- inspector tab chrome / pane chrome,
- current Dock rendering and visibility rules,
- Connect state UI and help/coachmark behavior,
- compact affordances when the expanded Dock recedes,
- Touch-Fahrplan presentation and entry points,
- DMX-related affordances or handoff points,
- Annotation participation in the same model,
- any JS/CSS needed to support the new behavior,
- durable HyperDoc documentation for the UX model,
- the new state-model view and its claim-code links.

Please find and update the existing implementation points instead of creating duplicate parallel mechanisms. Keep the boundary coherent.

Documentation slice to add or update

Add or update durable HyperDoc pages/topics so the repo documents:
- Dock as progressive enhancement of inspector tabs,
- coachmark state transitions and why they exist,
- the rule “degrade chrome, not capability”,
- how Connect, Annotation, Touch-Fahrplan, and DMX fit into the same UX grammar,
- where the editable/inspectable state model lives,
- how the claim-code relation grounds the state model in source.

Prefer editing canonical existing pages in place if the title already exists. Reuse exact titles where appropriate to avoid duplicate topics.

Tests and validation

Add or update narrow automated coverage for the new behavior. Cover at least:
- introduction vs active vs degraded presentation semantics,
- Connect still accessible after dock degradation,
- active Connect state shows task-state UI,
- steady-state chrome does not retain full onboarding prose,
- Touch-Fahrplan/DMX presentation does not regress into competing toolbar identity,
- the state-model view resolves to real implementation evidence,
- claim-code links or evidence paths stay valid for the documented claims.

Use the repo’s existing Playwright and/or Lisp test surfaces where appropriate.

Run authoritative validation through nix develop. Use the narrowest validation that still proves the change.

Deliverable format

At the end, report back with:
1. surface answer: what changed conceptually and in the live UX
2. artifact answer: exact files changed, exact tests run, exact results
3. process trace: expectation, observed reality, root cause, fix
4. commit hashes and messages for each coherent slice
5. the exact state-model view/object added or updated, and how its claim-code relations map to source files/tests

Do not stop at a design memo. Implement the code, tests, claim-code relations, state-model view, and durable docs.
```

I also exported the revised handover as HTML here: [codex-dock-coachmark-handover-v2.html](sandbox:/mnt/data/codex-dock-coachmark-handover-v2.html)

One more design constraint I would keep in mind for Codex: the editable state-model view should not become a second, disconnected model. It should either drive the implementation or be tightly evidence-linked enough that drift is visible immediately.
