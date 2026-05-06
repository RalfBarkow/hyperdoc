package systems.dmx.hyperdoc.repair;

import systems.dmx.core.RelatedTopic;
import systems.dmx.core.Topic;
import systems.dmx.core.osgi.PluginActivator;
import systems.dmx.core.service.CoreService;

import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.osgi.framework.ServiceRegistration;
import org.osgi.service.event.EventAdmin;

import java.util.Dictionary;
import java.util.Hashtable;
import java.util.List;



/**
 * One-shot DMX-side maintenance command for the HyperDoc annotation carrier topic 936040.
 *
 * This deliberately uses the DMX internal initial-assignment API instead of the public
 * /workspaces/{workspaceId}/object/{objectId} REST route. The public route checks object WRITE first,
 * which is structurally blocked while the object has no workspace assignment yet.
 *
 * Deployment is inert with respect to the workspace assignment: bundle start registers bounded Gogo commands only. The
 * mutation requires a successful preview in the same bundle instance and then an explicit hyperdoc:repair936040
 * invocation with the confirmation token.
 */
public final class HyperdocInitialWorkspaceAssignmentRepair936040 extends PluginActivator {

    private static final String COMMAND_SCOPE = "hyperdoc";
    private static final String STATUS_COMMAND = "status936040";
    private static final String PREVIEW_COMMAND = "preview936040";
    private static final String REPAIR_COMMAND = "repair936040";
    private static final String CONFIRMATION_TOKEN =
        "I_UNDERSTAND_THIS_ASSIGNS_TOPIC_936040_TO_WORKSPACE_919815";

    private static final long TOPIC_ID = 936040L;
    private static final long WORKSPACE_ID = 919815L;
    private static final long TOPICMAP_ID = 919822L;

    private static final String EXPECTED_URI =
        "hyperdoc:mcp/workspace-annotation/" +
        "dom-relation-list-item-h1-lafont-1990-interaction-nets-h2-core-concepts-from-lafont-1990-" +
        "ul-2-item-3-an-active-alive-pair-is-two-agents-connected-by-principal-ports-to-dock-annotation";

    private static final String EXPECTED_TOPIC_TYPE_URI = "dmx.notes.note";
    private static final String EXPECTED_TOPIC_VALUE =
        "Annotation: An active/alive pair is two agents connected by principal ports.";
    private static final String EXPECTED_WORKSPACE_TYPE_URI = "dmx.workspaces.workspace";
    private static final String EXPECTED_WORKSPACE_VALUE = "context-window";

    private static final String TOPICMAP = "dmx.topicmaps.topicmap";
    private static final String TOPICMAP_CONTEXT = "dmx.topicmaps.topicmap_context";
    private static final String TOPICMAP_CONTENT = "dmx.topicmaps.topicmap_content";
    private static final String DEFAULT = "dmx.core.default";

    private BundleContext commandContext;
    private ServiceRegistration<?> commandRegistration;
    private volatile boolean initRan;
    private volatile boolean previewSucceeded;

    @Override
    public void start(BundleContext context) {
        super.start(context);
        commandContext = context;
        registerCommands(context);
    }

    @Override
    public void stop(BundleContext context) {
        unregisterCommands();
        commandContext = null;
        super.stop(context);
    }

    @Override
    public void init() {
        // DMX calls init() only after CoreService, EventAdmin, injected services, and dependencies are available.
        if (dmx == null) {
            throw new IllegalStateException("DMX plugin activation reached init() without CoreService");
        }
        initRan = true;
        System.out.println("HyperDoc repair 936040: DMX plugin init reached; CoreService is available");
    }

    @Override
    public void shutdown() {
        unregisterCommands();
        initRan = false;
        previewSucceeded = false;
    }

    @Override
    public void serviceArrived(Object service) {
        if (service instanceof CoreService) {
            System.out.println("HyperDoc repair 936040: CoreService arrived through DMX PluginActivator tracking");
        }
    }

    @Override
    public void serviceGone(Object service) {
        if (service instanceof CoreService) {
            previewSucceeded = false;
            System.out.println("HyperDoc repair 936040: CoreService went away; preview gate reset");
        }
    }

    private void registerCommands(BundleContext context) {
        if (commandRegistration != null) {
            return;
        }
        Dictionary<String, Object> props = new Hashtable<>();
        props.put("osgi.command.scope", COMMAND_SCOPE);
        props.put("osgi.command.function", new String[] {STATUS_COMMAND, PREVIEW_COMMAND, REPAIR_COMMAND});
        commandRegistration = context.registerService(getClass().getName(), this, props);
        System.out.println("HyperDoc repair 936040: commands registered; deployment is inert until " +
            COMMAND_SCOPE + ":" + REPAIR_COMMAND + " is invoked with the confirmation token");
    }

    private void unregisterCommands() {
        if (commandRegistration != null) {
            commandRegistration.unregister();
            commandRegistration = null;
        }
    }

    public String status936040() {
        BundleContext context = activeBundleContext();
        boolean coreReference = serviceReferenceAvailable(context, CoreService.class.getName());
        boolean eventAdminReference = serviceReferenceAvailable(context, EventAdmin.class.getName());
        boolean directCoreLookup = dmx != null || lookupService(context, CoreService.class.getName()) != null;
        return "(:STATE :DMX-INITIAL-WORKSPACE-ASSIGNMENT-HELPER-STATUS" +
            " :BUNDLE-ID " + bundleIdLabel(context) +
            " :COMMAND-REGISTERED-P " + truth(commandRegistration != null) +
            " :INIT-RAN-P " + truth(initRan) +
            " :PLUGIN-ACTIVATOR-DMX-P " + truth(dmx != null) +
            " :CORE-SERVICE-REFERENCE-P " + truth(coreReference) +
            " :CORE-SERVICE-LOOKUP-P " + truth(directCoreLookup) +
            " :EVENTADMIN-REFERENCE-P " + truth(eventAdminReference) +
            " :NO-MUTATION-ON-ACTIVATION-P T" +
            " :PREVIEW-SUCCEEDED-P " + truth(previewSucceeded) +
            " :REPAIR-GATE :PREVIEW-THEN-EXACT-TOKEN)";
    }

    public String preview936040() {
        RepairState state = validatePreconditions();
        previewSucceeded = true;
        return state.summary("preview");
    }

    public String repair936040(String confirmationToken) {
        if (!CONFIRMATION_TOKEN.equals(confirmationToken)) {
            throw new IllegalArgumentException("Refusing repair: confirmation token mismatch. Expected " +
                CONFIRMATION_TOKEN);
        }
        if (!previewSucceeded) {
            throw new IllegalStateException("Refusing repair: run hyperdoc:" + PREVIEW_COMMAND +
                " successfully before invoking " + COMMAND_SCOPE + ":" + REPAIR_COMMAND);
        }

        RepairState state = validatePreconditions();
        if (state.beforeWorkspaceId == WORKSPACE_ID) {
            return state.summary("already-assigned");
        }
        if (state.beforeWorkspaceId != -1L) {
            throw new IllegalStateException("Topic " + TOPIC_ID + " is already assigned to workspace " +
                state.beforeWorkspaceId + ", refusing reassignment");
        }

        state.dmx.getPrivilegedAccess().assignToWorkspace(state.topic, WORKSPACE_ID);

        long afterWorkspaceId = state.dmx.getPrivilegedAccess().getAssignedWorkspaceId(TOPIC_ID);
        if (afterWorkspaceId != WORKSPACE_ID) {
            throw new IllegalStateException("Workspace readback mismatch after repair: expected " + WORKSPACE_ID +
                ", got " + afterWorkspaceId);
        }

        return state.withAfterWorkspaceId(afterWorkspaceId).summary("assigned");
    }

    private RepairState validatePreconditions() {
        CoreService core = requireCoreService();

        Topic topic = core.getTopic(TOPIC_ID);
        requireEquals("topic URI", EXPECTED_URI, topic.getUri());
        requireEquals("topic type URI", EXPECTED_TOPIC_TYPE_URI, topic.getTypeUri());
        requireEquals("topic value", EXPECTED_TOPIC_VALUE, topic.getSimpleValue().toString());

        Topic workspace = core.getTopic(WORKSPACE_ID);
        requireEquals("workspace type URI", EXPECTED_WORKSPACE_TYPE_URI, workspace.getTypeUri());
        requireEquals("workspace value", EXPECTED_WORKSPACE_VALUE, workspace.getSimpleValue().toString());

        long beforeWorkspaceId = core.getPrivilegedAccess().getAssignedWorkspaceId(TOPIC_ID);
        if (!topicmapContainsObject(core, TOPICMAP_ID, TOPIC_ID)) {
            throw new IllegalStateException("Topicmap " + TOPICMAP_ID + " does not contain topic " + TOPIC_ID);
        }
        return new RepairState(core, topic, beforeWorkspaceId, -1L);
    }

    private static boolean topicmapContainsObject(CoreService core, long topicmapId, long objectId) {
        List<RelatedTopic> topicmapTopics = core.getObject(objectId).getRelatedTopics(TOPICMAP_CONTEXT,
            TOPICMAP_CONTENT, DEFAULT, TOPICMAP);
        for (RelatedTopic topicmapTopic : topicmapTopics) {
            if (topicmapTopic.getId() == topicmapId) {
                return true;
            }
        }
        return false;
    }

    private CoreService requireCoreService() {
        if (dmx != null) {
            return dmx;
        }
        CoreService core = lookupService(activeBundleContext(), CoreService.class.getName());
        if (core != null) {
            return core;
        }
        throw new IllegalStateException("Required DMX core service is not available. " + status936040());
    }

    private static void requireEquals(String label, String expected, String actual) {
        if (!expected.equals(actual)) {
            throw new IllegalStateException(label + " mismatch: expected \"" + expected + "\", got \"" + actual +
                "\"");
        }
    }

    private BundleContext activeBundleContext() {
        return commandContext != null ? commandContext : getBundleContext();
    }

    private static boolean serviceReferenceAvailable(BundleContext context, String serviceName) {
        return context != null && context.getServiceReference(serviceName) != null;
    }

    @SuppressWarnings("unchecked")
    private static <T> T lookupService(BundleContext context, String serviceName) {
        if (context == null) {
            return null;
        }
        ServiceReference<?> ref = context.getServiceReference(serviceName);
        if (ref == null) {
            return null;
        }
        Object service = context.getService(ref);
        return service != null ? (T) service : null;
    }

    private static String bundleIdLabel(BundleContext context) {
        return context != null ? Long.toString(context.getBundle().getBundleId()) : "NIL";
    }

    private static String truth(boolean value) {
        return value ? "T" : "NIL";
    }

    private static final class RepairState {
        private final CoreService dmx;
        private final Topic topic;
        private final long beforeWorkspaceId;
        private final long afterWorkspaceId;

        private RepairState(CoreService dmx, Topic topic, long beforeWorkspaceId, long afterWorkspaceId) {
            this.dmx = dmx;
            this.topic = topic;
            this.beforeWorkspaceId = beforeWorkspaceId;
            this.afterWorkspaceId = afterWorkspaceId;
        }

        private RepairState withAfterWorkspaceId(long afterWorkspaceId) {
            return new RepairState(dmx, topic, beforeWorkspaceId, afterWorkspaceId);
        }

        private String summary(String state) {
            return "(:STATE :" + state.toUpperCase().replace('-', '_') +
                " :TOPIC-ID " + TOPIC_ID +
                " :WORKSPACE-ID " + workspaceIdLabel(afterWorkspaceId != -1L ? afterWorkspaceId : beforeWorkspaceId) +
                " :EXPECTED-WORKSPACE-ID " + WORKSPACE_ID +
                " :TOPICMAP-ID " + TOPICMAP_ID +
                " :TOPICMAP-PRESENT-P T" +
                " :TOPIC-URI \"" + topic.getUri() + "\"" +
                " :TOPIC-TYPE-URI \"" + topic.getTypeUri() + "\"" +
                " :TOPIC-VALUE \"" + topic.getSimpleValue() + "\"" +
                " :MUTATION-SURFACE :DMX_PRIVILEGED_ACCESS)";
        }

        private static String workspaceIdLabel(long workspaceId) {
            return workspaceId == -1L ? "NIL" : Long.toString(workspaceId);
        }
    }
}
