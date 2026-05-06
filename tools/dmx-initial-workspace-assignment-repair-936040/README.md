# HyperDoc Initial Workspace Assignment Repair 936040

Status: superseded diagnostic artifact.

This bundle records the first standalone-helper attempt for assigning topic
`936040` to workspace `919815`. It is kept as source-level reconstruction
evidence, not as the recommended repair path.

The completed live repair was performed by a temporary command in the patched
DMX Workspaces bundle:

```java
WorkspacesPlugin._assignToWorkspace(topic, 919815L);
```

If this standalone helper is still installed in a DMX runtime, stop or uninstall
it before using the WorkspacesPlugin command. Do not keep two bundles registering
the same `hyperdoc:*936040` Gogo command names.

For the proven operator transcript and readback evidence, see:

```text
hyperdoc/DMX initial workspace assignment repair 936040 operator runbook.html
```

## Historical Purpose

This was a one-shot DMX-side maintenance bundle intended to assign topic
`936040` to workspace `919815` through DMX's privileged access API.

Deployment is inert with respect to the workspace assignment. The bundle is a
normal DMX plugin and registers bounded Gogo commands from `start()`, so the
operator can inspect lifecycle state even when DMX plugin activation has not
reached `init()`. It does not assign the workspace on bundle activation.

It is not a HyperDoc write-loop repair and it does not call the public REST
assignment route:

```text
PUT /workspaces/919815/object/936040
```

That public route checks object WRITE before assignment, which is structurally
blocked while topic `936040` has no workspace assignment.

## Internal Method

The standalone helper repair command attempted:

```java
dmx.getPrivilegedAccess().assignToWorkspace(topic, 919815L);
```

That method is declared by
`systems.dmx.core.service.accesscontrol.PrivilegedAccess` and implemented by
`systems.dmx.core.impl.PrivilegedAccessImpl`.

Observed result: the Gogo command surface and CoreService access eventually
worked, but the successful mutation did not come from this standalone helper.
The proven repair path was the WorkspacesPlugin-local initial-assignment helper,
`_assignToWorkspace(topic, 919815L)`, called from inside the already activated
Workspaces plugin.

## DMX Plugin Integration Pattern

The repair helper follows the same server-side pattern as normal DMX plugins:

- it extends `systems.dmx.core.osgi.PluginActivator`
- `PluginActivator` receives `CoreService` through DMX's plugin machinery and
  stores it in the protected `dmx` field via `setCoreService(CoreService)`
- the helper ships `src/main/resources/plugin.properties`, like normal DMX
  plugins, with explicit model version `0`
- the helper declares plugin dependencies on `systems.dmx.topicmaps` and
  `systems.dmx.workspaces`, so startup deployment waits for the normal DMX
  topicmap/workspace layer before activation
- the helper has no `@Inject` service fields, so `TopicmapsService` cannot block
  activation
- `PluginImpl.checkRequirementsForActivation()` invokes plugin activation, and
  therefore `init()`, only after `CoreService`, EventAdmin, injected services,
  and plugin dependencies are available
- the helper registers commands from `start(BundleContext)` for bounded
  diagnostics and command visibility
- command execution uses the protected `dmx` field set by `PluginActivator`, or
  a direct OSGi lookup for `systems.dmx.core.service.CoreService` if the command
  is invoked before plugin activation reaches `init()`
- topicmap membership is validated through CoreService-visible topicmap-context
  associations, mirroring the relevant `TopicmapsPlugin.getTopicmapTopics`
  relation shape without consuming `TopicmapsService`

Source pattern references in `dmx-platform`:

- `modules/dmx-core/src/main/java/systems/dmx/core/osgi/PluginActivator.java`
- `modules/dmx-core/src/main/java/systems/dmx/core/impl/PluginImpl.java`
- `modules/dmx-workspaces/src/main/java/systems/dmx/workspaces/WorkspacesPlugin.java`

## Preconditions

The bundle refuses to run unless all checks pass:

- topic id is exactly `936040`
- target workspace id is exactly `919815`
- required topicmap id is exactly `919822`
- topic URI is the expected deterministic HyperDoc workspace annotation URI
- topic type is `dmx.notes.note`
- topic value is `Annotation: An active/alive pair is two agents connected by principal ports.`
- workspace type is `dmx.workspaces.workspace`
- workspace value is `context-window`
- current workspace assignment is missing (`-1`)
- topicmap `919822` contains topic `936040`

## Build, If Preserving The Diagnostic Artifact

From the HyperDoc repo:

```sh
nix develop -c mvn \
  -f tools/dmx-initial-workspace-assignment-repair-936040/pom.xml \
  -Ddmx.deploy.disable=true \
  -DskipTests \
  package
```

The deploy flag is disabled so Maven does not copy the bundle into a local
`bundle-deploy` directory by accident.

Artifact:

```text
tools/dmx-initial-workspace-assignment-repair-936040/target/hyperdoc-initial-workspace-assignment-repair-936040-0.1.0-SNAPSHOT.jar
```

## Deploy, Historical Only

Do not deploy this helper for the completed repair. The following commands are
kept only to reconstruct the abandoned standalone-helper experiment.

Copy the built JAR to the running DMX installation's hot-deploy directory, or
install it through the Felix/Gogo shell.

Hot deploy example:

```sh
cp tools/dmx-initial-workspace-assignment-repair-936040/target/hyperdoc-initial-workspace-assignment-repair-936040-0.1.0-SNAPSHOT.jar \
  /path/to/dmx/bundle-deploy/
```

Gogo install example:

```text
g! install file:/absolute/path/to/hyperdoc-initial-workspace-assignment-repair-936040-0.1.0-SNAPSHOT.jar
g! start <bundle-id>
```

If an earlier version of this maintenance bundle is already installed, update
that bundle instead of installing a second copy:

```text
g! stop <bundle-id>
g! update <bundle-id> file:/absolute/path/to/hyperdoc-initial-workspace-assignment-repair-936040-0.1.0-SNAPSHOT.jar
g! start <bundle-id>
```

Starting the bundle starts DMX plugin service tracking. Command registration is
logged immediately for diagnostics and command visibility. It does not assign
the workspace.

## Initial Bundle Deployment Experiment

If late installation still reports no `CoreService`, stop using
`bundle-deploy/`. In DMX 5.3.5 that directory is handled by Felix FileInstall
and is a hot-deploy surface. The initial DMX runtime bundle set is the
distribution's `bundle/` directory, which Felix auto-deploys at VM startup via:

```properties
felix.auto.deploy.action = install,start
```

Deploy the helper through the same initial bundle path as normal DMX plugins:

1. Stop DMX.
2. Copy the JAR to the running installation's `bundle/` directory, next to
   `dmx-core-5.3.5.jar`, `dmx-topicmaps-5.3.5.jar`, and
   `dmx-workspaces-5.3.5.jar`.
3. Start DMX.
4. In Gogo, run:

```text
g! lb
g! inspect capability service <bundle-id>
g! hyperdoc:status936040
g! hyperdoc:preview936040
```

Expected status after a successful startup deployment:

```text
:CORE-SERVICE-REFERENCE-P T
:CORE-SERVICE-LOOKUP-P T
```

The helper declares dependencies on `systems.dmx.topicmaps` and
`systems.dmx.workspaces`, so its DMX plugin activation may wait until those
plugins are active. `status936040` remains safe and read-only.

If initial `bundle/` deployment still reports no `CoreService`, stop trying this
standalone Gogo bundle and move the one-shot command into an already activated
DMX plugin context, preferably `systems.dmx.workspaces.WorkspacesPlugin`.

## Trigger, Historical Only

Inspect lifecycle state without mutation:

```text
g! hyperdoc:status936040
```

Preview hard preconditions without mutation:

```text
g! hyperdoc:preview936040
```

The historical exact-token repair command was:

```text
g! hyperdoc:repair936040 I_UNDERSTAND_THIS_ASSIGNS_TOPIC_936040_TO_WORKSPACE_919815
```

Do not use this standalone helper as the repair surface after the Workspaces
plugin proof has been recorded. The exact-token command remains documented only
to explain the abandoned path.

Had this standalone helper been used, its only mutation would have been the
privileged initial workspace assignment:

```java
dmx.getPrivilegedAccess().assignToWorkspace(topic, 919815L);
```

No topic upsert, topicmap placement, HyperDoc full continuation, DMX journal
write, REST assignment route, credential handling, or direct Neo4j mutation was
part of the standalone-helper design.

## Historical Verification Contract

The verification contract for the abandoned standalone helper was the same as
the final WorkspacesPlugin repair proof:

```text
GET /workspaces/object/936040
GET /topicmaps/object/936040
GET /core/topic/936040?children=true
GET /core/topic/uri/<encoded-deterministic-uri>?children=true
```

Expected results:

- workspace readback returns workspace `919815` / `context-window`
- topicmap readback still includes topicmap `919822`
- core topic readback still returns id `936040`, type `dmx.notes.note`, and the
  deterministic HyperDoc annotation URI
- URI lookup returns id `936040`, proving no duplicate topic was created
