import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.neo4j.graphdb.GraphDatabaseService;
import org.neo4j.graphdb.Node;
import org.neo4j.graphdb.NotFoundException;
import org.neo4j.graphdb.PropertyContainer;
import org.neo4j.graphdb.Relationship;
import org.neo4j.graphdb.Transaction;
import org.neo4j.kernel.EmbeddedGraphDatabase;
import org.neo4j.kernel.EmbeddedReadOnlyGraphDatabase;

/**
 * Offline HyperDoc/DMX Neo4j topic delete repair tool.
 *
 * Scope intentionally supported by this first version:
 *   - rsynced/offline DMX Neo4j store only
 *   - HyperDoc-owned workspace annotations only
 *   - workspace n/a topics only, meaning no workspace assignment association
 *     and no dmx.workspaces.workspace_id property on the topic
 *   - exact expected topic URI required for mutation
 *   - deletion closure limited to:
 *       primary topic
 *       topicmap-context association nodes in the expected topicmap
 *       dmx.core.composition association nodes where the primary topic is parent
 *       private dmx.notes.title / dmx.notes.text children of those compositions
 *
 * This is not a generic Neo4j node deleter. Unknown relationships or shared child
 * metadata cause refusal.
 *
 * Commands:
 *   report-topic <db-path> <topic-id>
 *   plan-delete-topic <db-path> <topic-id> <workspace-topicmap-id> <expected-uri>
 *   delete-topic <db-path> <topic-id> <workspace-topicmap-id> <expected-uri>
 *   force-detach-delete-topic <db-path> <topic-id> <expected-uri> I_UNDERSTAND_THIS_DETACH_DELETES_PRIMARY_TOPIC_ONLY
 *   plan-force-delete-orphan-assoc-nodes <db-path> <node-id-csv>
 *   force-delete-orphan-assoc-nodes <db-path> <node-id-csv> I_UNDERSTAND_THIS_DELETES_LISTED_ASSOCIATION_NODES
 *   report-workspace-na-candidates <db-path> <workspace-topicmap-id>
 *   delete-manifest <db-path> <manifest.tsv>
 *
 * Manifest TSV columns:
 *   topicId<TAB>workspaceTopicmapId<TAB>expectedOwnershipClass<TAB>expectedUri
 */
public class HyperdocNeo4jTopicDeleteTool {
  private static final String TOOL = "HyperdocNeo4jTopicDeleteTool";
  private static final String ANNOTATION_URI_PREFIX = "hyperdoc:mcp/workspace-annotation/";
  private static final String OWNERSHIP_ANNOTATION = "hyperdoc-workspace-annotation";
  private static final String TYPE_NOTE = "dmx.notes.note";
  private static final String TYPE_NOTE_TITLE = "dmx.notes.title";
  private static final String TYPE_NOTE_TEXT = "dmx.notes.text";
  private static final String TYPE_TOPICMAP_CONTEXT = "dmx.topicmaps.topicmap_context";
  private static final String TYPE_COMPOSITION = "dmx.core.composition";
  private static final String TYPE_ASSOCIATION = "dmx.core.association";
  private static final String TYPE_INSTANTIATION = "dmx.core.instantiation";
  private static final String TYPE_WORKSPACE_ASSIGNMENT = "dmx.workspaces.workspace_assignment";
  private static final String TYPE_WORKSPACE = "dmx.workspaces.workspace";

  private static String stringProp(PropertyContainer container, String key) {
    if (container == null || !container.hasProperty(key)) {
      return null;
    }
    Object value = container.getProperty(key);
    return value == null ? null : String.valueOf(value);
  }

  private static Long longProp(PropertyContainer container, String key) {
    if (container == null || !container.hasProperty(key)) {
      return null;
    }
    Object value = container.getProperty(key);
    if (value instanceof Number) {
      return Long.valueOf(((Number) value).longValue());
    }
    if (value == null) {
      return null;
    }
    try {
      return Long.valueOf(String.valueOf(value));
    } catch (NumberFormatException e) {
      return null;
    }
  }

  private static Boolean booleanProp(PropertyContainer container, String key) {
    if (container == null || !container.hasProperty(key)) {
      return null;
    }
    Object value = container.getProperty(key);
    if (value instanceof Boolean) {
      return (Boolean) value;
    }
    if (value == null) {
      return null;
    }
    return Boolean.valueOf(String.valueOf(value));
  }

  private static Object prop(PropertyContainer container, String key) {
    if (container == null || !container.hasProperty(key)) {
      return null;
    }
    return container.getProperty(key);
  }

  private static boolean relationshipType(Relationship relationship, String typeName) {
    return relationship != null
        && relationship.getType() != null
        && typeName.equals(relationship.getType().name());
  }

  private static boolean isType(Node node, String typeUri) {
    return node != null && typeUri.equals(stringProp(node, "typeUri"));
  }

  private static String ownershipClass(Node topicNode) {
    String uri = stringProp(topicNode, "uri");
    if (uri != null && uri.startsWith(ANNOTATION_URI_PREFIX)) {
      return OWNERSHIP_ANNOTATION;
    }
    return "foreign-or-unsupported";
  }

  private static String workspaceStatus(Node topicNode) {
    if (workspaceAssignmentForTopic(topicNode) != null) {
      return "assigned-by-association";
    }
    if (longProp(topicNode, "dmx.workspaces.workspace_id") != null) {
      return "assigned-by-property";
    }
    return "n/a";
  }

  private static Map<String, Object> workspaceAssignmentForTopic(Node topicNode) {
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.parent")) {
        continue;
      }
      Node assignment = relationship.getOtherNode(topicNode);
      if (!TYPE_WORKSPACE_ASSIGNMENT.equals(stringProp(assignment, "typeUri"))) {
        continue;
      }
      for (Relationship assignmentRelationship : assignment.getRelationships()) {
        if (!relationshipType(assignmentRelationship, "dmx.core.child")) {
          continue;
        }
        Node workspace = assignmentRelationship.getOtherNode(assignment);
        if (TYPE_WORKSPACE.equals(stringProp(workspace, "typeUri"))) {
          Map<String, Object> report = new LinkedHashMap<String, Object>();
          report.put("assignmentAssocId", Long.valueOf(assignment.getId()));
          report.put("workspaceId", Long.valueOf(workspace.getId()));
          report.put("workspaceTitle", stringProp(workspace, "value"));
          report.put("workspaceUri", stringProp(workspace, "uri"));
          return report;
        }
      }
    }
    return null;
  }

  private static List<Map<String, Object>> topicmapMembershipsForTopic(Node topicNode) {
    List<Map<String, Object>> memberships = new ArrayList<Map<String, Object>>();
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.topicmaps.topicmap_content")) {
        continue;
      }
      Node context = relationship.getOtherNode(topicNode);
      if (!TYPE_TOPICMAP_CONTEXT.equals(stringProp(context, "typeUri"))) {
        continue;
      }
      List<Long> topicmapIds = topicmapIdsForContext(context);
      for (Long topicmapId : topicmapIds) {
        Map<String, Object> entry = new LinkedHashMap<String, Object>();
        entry.put("topicmapId", topicmapId);
        entry.put("contextAssocId", Long.valueOf(context.getId()));
        entry.put("contentTopicId", Long.valueOf(topicNode.getId()));
        entry.put("x", prop(context, "dmx.topicmaps.x"));
        entry.put("y", prop(context, "dmx.topicmaps.y"));
        entry.put("visibility", prop(context, "dmx.topicmaps.visibility"));
        entry.put("pinned", prop(context, "dmx.topicmaps.pinned"));
        entry.put("shortX", prop(context, "x"));
        entry.put("shortY", prop(context, "y"));
        entry.put("shortVisibility", prop(context, "visibility"));
        entry.put("shortPinned", prop(context, "pinned"));
        memberships.add(entry);
      }
    }
    return memberships;
  }

  private static List<Long> topicmapIdsForContext(Node context) {
    List<Long> ids = new ArrayList<Long>();
    for (Relationship relationship : context.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.default")) {
        continue;
      }
      Node topicmap = relationship.getOtherNode(context);
      ids.add(Long.valueOf(topicmap.getId()));
    }
    return ids;
  }

  private static boolean hasMembershipInTopicmap(Node topicNode, long workspaceTopicmapId) {
    for (Map<String, Object> membership : topicmapMembershipsForTopic(topicNode)) {
      Object id = membership.get("topicmapId");
      if (id instanceof Number && ((Number) id).longValue() == workspaceTopicmapId) {
        return true;
      }
    }
    return false;
  }

  private static String noteTextForTopic(Node topicNode) {
    String direct = stringProp(topicNode, "dmx.notes.text");
    if (direct != null) {
      return direct;
    }
    for (Node child : childTopicsOf(topicNode)) {
      if (TYPE_NOTE_TEXT.equals(stringProp(child, "typeUri"))) {
        return stringProp(child, "value");
      }
    }
    return null;
  }

  private static String noteTitleForTopic(Node topicNode) {
    String direct = stringProp(topicNode, "dmx.notes.title");
    if (direct != null) {
      return direct;
    }
    for (Node child : childTopicsOf(topicNode)) {
      if (TYPE_NOTE_TITLE.equals(stringProp(child, "typeUri"))) {
        return stringProp(child, "value");
      }
    }
    return stringProp(topicNode, "value");
  }

  private static List<Node> childTopicsOf(Node parentTopic) {
    List<Node> children = new ArrayList<Node>();
    for (Relationship relationship : parentTopic.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.parent")) {
        continue;
      }
      Node composition = relationship.getOtherNode(parentTopic);
      if (!TYPE_COMPOSITION.equals(stringProp(composition, "typeUri"))) {
        continue;
      }
      for (Relationship compositionRelationship : composition.getRelationships()) {
        if (!relationshipType(compositionRelationship, "dmx.core.child")) {
          continue;
        }
        Node child = compositionRelationship.getOtherNode(composition);
        children.add(child);
      }
    }
    return children;
  }

  private static boolean supportedAnnotationEnvelope(Node topicNode, long workspaceTopicmapId, String expectedUri) {
    if (!OWNERSHIP_ANNOTATION.equals(ownershipClass(topicNode))) {
      return false;
    }
    if (!TYPE_NOTE.equals(stringProp(topicNode, "typeUri"))) {
      return false;
    }
    String noteText = noteTextForTopic(topicNode);
    if (noteText == null) {
      return false;
    }
    if (!containsJsonString(noteText, "storageMode", "compatibility-note-carrier")) {
      return false;
    }
    if (!containsJsonString(noteText, "carrierTypeUri", TYPE_NOTE)) {
      return false;
    }
    if (!containsJsonString(noteText, "nativeTypeUri", "hyperdoc.annotation")) {
      return false;
    }
    if (!containsJsonLong(noteText, "workspaceTopicmapId", workspaceTopicmapId)) {
      return false;
    }
    String actualUri = stringProp(topicNode, "uri");
    if (expectedUri != null && !expectedUri.equals(actualUri)) {
      return false;
    }
    if (actualUri == null || noteText.indexOf(actualUri) < 0) {
      return false;
    }
    return true;
  }

  private static boolean containsJsonString(String text, String key, String value) {
    if (text == null) {
      return false;
    }
    Pattern pattern = Pattern.compile("\\\"" + Pattern.quote(key) + "\\\"\\s*:\\s*\\\"" + Pattern.quote(value) + "\\\"");
    return pattern.matcher(text).find();
  }

  private static boolean containsJsonLong(String text, String key, long value) {
    if (text == null) {
      return false;
    }
    Pattern pattern = Pattern.compile("\\\"" + Pattern.quote(key) + "\\\"\\s*:\\s*" + Long.toString(value) + "(?![0-9])");
    return pattern.matcher(text).find();
  }

  private static Map<String, Object> topicReport(Node topicNode, Long workspaceTopicmapId, String expectedUri) {
    Map<String, Object> report = new LinkedHashMap<String, Object>();
    String ownership = ownershipClass(topicNode);
    String actualUri = stringProp(topicNode, "uri");
    String workspace = workspaceStatus(topicNode);
    boolean topicmapMatches = workspaceTopicmapId == null || hasMembershipInTopicmap(topicNode, workspaceTopicmapId.longValue());
    boolean supported = workspaceTopicmapId != null
        && expectedUri != null
        && expectedUri.equals(actualUri)
        && "n/a".equals(workspace)
        && topicmapMatches
        && supportedAnnotationEnvelope(topicNode, workspaceTopicmapId.longValue(), expectedUri);

    report.put("topicId", Long.valueOf(topicNode.getId()));
    report.put("exists", Boolean.TRUE);
    report.put("typeUri", stringProp(topicNode, "typeUri"));
    report.put("uri", actualUri);
    report.put("value", stringProp(topicNode, "value"));
    report.put("title", noteTitleForTopic(topicNode));
    report.put("workspaceIdProperty", longProp(topicNode, "dmx.workspaces.workspace_id"));
    report.put("workspaceAssignment", workspaceAssignmentForTopic(topicNode));
    report.put("workspaceStatus", workspace);
    report.put("topicmapMemberships", topicmapMembershipsForTopic(topicNode));
    report.put("ownershipClass", ownership);
    report.put("expectedTopicmapId", workspaceTopicmapId);
    report.put("expectedUri", expectedUri);
    report.put("topicmapMatches", Boolean.valueOf(topicmapMatches));
    report.put("supportedDeleteShape", Boolean.valueOf(supported));
    report.put("refusalReasons", refusalReasons(topicNode, workspaceTopicmapId, expectedUri));
    return report;
  }

  private static List<String> refusalReasons(Node topicNode, Long workspaceTopicmapId, String expectedUri) {
    List<String> reasons = new ArrayList<String>();
    String actualUri = stringProp(topicNode, "uri");
    if (!OWNERSHIP_ANNOTATION.equals(ownershipClass(topicNode))) {
      reasons.add("ownership class is not " + OWNERSHIP_ANNOTATION);
    }
    if (!TYPE_NOTE.equals(stringProp(topicNode, "typeUri"))) {
      reasons.add("topic typeUri is not " + TYPE_NOTE);
    }
    if (!"n/a".equals(workspaceStatus(topicNode))) {
      reasons.add("topic has workspace assignment or workspace id property");
    }
    if (workspaceTopicmapId == null) {
      reasons.add("workspaceTopicmapId is required");
    } else if (!hasMembershipInTopicmap(topicNode, workspaceTopicmapId.longValue())) {
      reasons.add("topic is not placed in expected topicmap " + workspaceTopicmapId);
    }
    if (expectedUri == null) {
      reasons.add("expected URI is required for mutation planning");
    } else if (!expectedUri.equals(actualUri)) {
      reasons.add("expected URI does not match actual topic URI");
    }
    if (workspaceTopicmapId != null && expectedUri != null
        && !supportedAnnotationEnvelope(topicNode, workspaceTopicmapId.longValue(), expectedUri)) {
      reasons.add("annotation note-carrier envelope is not the supported HyperDoc annotation shape");
    }
    return reasons;
  }

  private static Map<String, Object> missingTopicReport(long topicId) {
    Map<String, Object> report = new LinkedHashMap<String, Object>();
    report.put("topicId", Long.valueOf(topicId));
    report.put("exists", Boolean.FALSE);
    report.put("supportedDeleteShape", Boolean.FALSE);
    List<String> reasons = new ArrayList<String>();
    reasons.add("topic does not exist");
    report.put("refusalReasons", reasons);
    return report;
  }

  private static DeletePlan buildDeletePlan(Node topicNode, long workspaceTopicmapId, String expectedUri) {
    DeletePlan plan = new DeletePlan(topicNode.getId());
    plan.workspaceTopicmapId = workspaceTopicmapId;
    plan.expectedUri = expectedUri;

    if (!expectedUri.equals(stringProp(topicNode, "uri"))) {
      plan.refuse("expected URI does not match actual topic URI");
    }
    if (!OWNERSHIP_ANNOTATION.equals(ownershipClass(topicNode))) {
      plan.refuse("ownership class is not " + OWNERSHIP_ANNOTATION);
    }
    if (!"n/a".equals(workspaceStatus(topicNode))) {
      plan.refuse("topic has workspace assignment or workspace id property");
    }
    if (!hasMembershipInTopicmap(topicNode, workspaceTopicmapId)) {
      plan.refuse("topic is not placed in expected topicmap " + workspaceTopicmapId);
    }
    if (!supportedAnnotationEnvelope(topicNode, workspaceTopicmapId, expectedUri)) {
      plan.refuse("annotation note-carrier envelope is not the supported HyperDoc annotation shape");
    }

    plan.addNode(topicNode, "primary-topic");

    // Topicmap contexts for the expected workspace topicmap.
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.topicmaps.topicmap_content")) {
        continue;
      }
      Node context = relationship.getOtherNode(topicNode);
      if (!TYPE_TOPICMAP_CONTEXT.equals(stringProp(context, "typeUri"))) {
        plan.refuse("topicmap_content relationship points to non-topicmap-context node " + context.getId());
        continue;
      }
      if (!topicmapIdsForContext(context).contains(Long.valueOf(workspaceTopicmapId))) {
        plan.refuse("topicmap-context " + context.getId() + " is not in expected topicmap " + workspaceTopicmapId);
        continue;
      }
      validateTopicmapContextClosure(context, topicNode, workspaceTopicmapId, plan);
      plan.addNode(context, "topicmap-context");
      for (Relationship contextRelationship : context.getRelationships()) {
        plan.addRelationship(contextRelationship);
      }
    }

    // Compositions where the target topic is the parent. These contain note title/text children.
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.parent")) {
        continue;
      }
      Node association = relationship.getOtherNode(topicNode);
      String associationType = stringProp(association, "typeUri");
      if (TYPE_WORKSPACE_ASSIGNMENT.equals(associationType)) {
        plan.refuse("workspace assignment association is present: " + association.getId());
        continue;
      }
      if (!TYPE_COMPOSITION.equals(associationType)) {
        plan.refuse("dmx.core.parent relationship points to unsupported association node "
            + association.getId() + " typeUri=" + associationType);
        continue;
      }
      validateCompositionClosure(association, topicNode, plan);
      plan.addNode(association, "composition");
      for (Relationship compositionRelationship : association.getRelationships()) {
        plan.addRelationship(compositionRelationship);
        if (relationshipType(compositionRelationship, "dmx.core.child")) {
          Node child = compositionRelationship.getOtherNode(association);
          if (isPrivateNoteCarrierChild(child, association, plan)) {
            plan.addNode(child, "private-note-child");
            for (Relationship childRelationship : child.getRelationships()) {
              plan.addRelationship(childRelationship);
            }
          }
        }
      }
    }

    // Topic relationships must all be explained by the closure. Any leftover edge is an external reference.
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!plan.relationships.contains(relationship)) {
        plan.refuse("unsupported external or unclassified relationship on primary topic: rel="
            + relationship.getId() + " type=" + relationship.getType().name()
            + " otherNode=" + relationship.getOtherNode(topicNode).getId());
      }
    }

    validateClosedClosure(plan);
    return plan;
  }

  private static void validateTopicmapContextClosure(Node context, Node topicNode, long workspaceTopicmapId, DeletePlan plan) {
    int contentEdges = 0;
    int defaultEdges = 0;
    for (Relationship relationship : context.getRelationships()) {
      if (relationshipType(relationship, "dmx.topicmaps.topicmap_content")) {
        Node other = relationship.getOtherNode(context);
        contentEdges++;
        if (other.getId() != topicNode.getId()) {
          plan.refuse("topicmap-context " + context.getId() + " content edge points to unexpected node " + other.getId());
        }
      } else if (relationshipType(relationship, "dmx.core.default")) {
        Node other = relationship.getOtherNode(context);
        defaultEdges++;
        if (other.getId() != workspaceTopicmapId) {
          plan.refuse("topicmap-context " + context.getId() + " default edge points to unexpected topicmap " + other.getId());
        }
      } else {
        plan.refuse("topicmap-context " + context.getId() + " has unsupported relationship "
            + relationship.getId() + " type=" + relationship.getType().name());
      }
    }
    if (contentEdges != 1) {
      plan.refuse("topicmap-context " + context.getId() + " has " + contentEdges + " content edges; expected 1");
    }
    if (defaultEdges != 1) {
      plan.refuse("topicmap-context " + context.getId() + " has " + defaultEdges + " default edges; expected 1");
    }
  }

  private static void validateCompositionClosure(Node composition, Node parentTopic, DeletePlan plan) {
    int parentEdges = 0;
    int childEdges = 0;
    for (Relationship relationship : composition.getRelationships()) {
      if (relationshipType(relationship, "dmx.core.parent")) {
        Node other = relationship.getOtherNode(composition);
        parentEdges++;
        if (other.getId() != parentTopic.getId()) {
          plan.refuse("composition " + composition.getId() + " parent edge points to unexpected node " + other.getId());
        }
      } else if (relationshipType(relationship, "dmx.core.child")) {
        Node child = relationship.getOtherNode(composition);
        childEdges++;
        if (!isSupportedPrivateChildType(child)) {
          plan.refuse("composition " + composition.getId() + " child " + child.getId()
              + " has unsupported typeUri=" + stringProp(child, "typeUri"));
        }
      } else {
        plan.refuse("composition " + composition.getId() + " has unsupported relationship "
            + relationship.getId() + " type=" + relationship.getType().name());
      }
    }
    if (parentEdges != 1) {
      plan.refuse("composition " + composition.getId() + " has " + parentEdges + " parent edges; expected 1");
    }
    if (childEdges < 1) {
      plan.refuse("composition " + composition.getId() + " has no child edge");
    }
  }

  private static boolean isSupportedPrivateChildType(Node child) {
    String typeUri = stringProp(child, "typeUri");
    return TYPE_NOTE_TITLE.equals(typeUri) || TYPE_NOTE_TEXT.equals(typeUri);
  }

  private static boolean isPrivateNoteCarrierChild(Node child, Node owningComposition, DeletePlan plan) {
    if (!isSupportedPrivateChildType(child)) {
      return false;
    }
    for (Relationship relationship : child.getRelationships()) {
      Node other = relationship.getOtherNode(child);
      if (other.getId() == owningComposition.getId()
          && relationshipType(relationship, "dmx.core.child")) {
        continue;
      }
      plan.refuse("private note child " + child.getId() + " is shared or externally referenced by rel="
          + relationship.getId() + " type=" + relationship.getType().name()
          + " otherNode=" + other.getId());
      return false;
    }
    return true;
  }

  private static void validateClosedClosure(DeletePlan plan) {
    for (Node node : plan.nodes) {
      for (Relationship relationship : node.getRelationships()) {
        if (!plan.relationships.contains(relationship)) {
          plan.refuse("closure node " + node.getId() + " has relationship outside deletion closure: rel="
              + relationship.getId() + " type=" + relationship.getType().name()
              + " otherNode=" + relationship.getOtherNode(node).getId());
        }
      }
    }
  }

  private static Map<String, Object> planReport(DeletePlan plan) {
    Map<String, Object> report = new LinkedHashMap<String, Object>();
    report.put("operation", "offline-neo4j-topic-delete");
    report.put("topicId", Long.valueOf(plan.topicId));
    report.put("workspaceTopicmapId", Long.valueOf(plan.workspaceTopicmapId));
    report.put("expectedUri", plan.expectedUri);
    report.put("status", plan.refusalReasons.isEmpty() ? "deletable" : "refused");
    report.put("refusalReasons", plan.refusalReasons);
    report.put("nodeCount", Integer.valueOf(plan.nodes.size()));
    report.put("relationshipCount", Integer.valueOf(plan.relationships.size()));
    report.put("nodes", plan.nodeReports());
    report.put("relationships", plan.relationshipReports());
    return report;
  }

  private static void runReportTopic(String dbPath, long topicId) {
    GraphDatabaseService db = new EmbeddedReadOnlyGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "report-topic");
      result.put("dbPath", dbPath);
      result.put("topicId", Long.valueOf(topicId));
      try {
        Node topic = db.getNodeById(topicId);
        result.put("topic", topicReport(topic, null, null));
      } catch (NotFoundException e) {
        result.put("topic", missingTopicReport(topicId));
      }
      transaction.success();
      System.out.println(toJson(result));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static void runPlanDeleteTopic(String dbPath, long topicId, long workspaceTopicmapId, String expectedUri) {
    GraphDatabaseService db = new EmbeddedReadOnlyGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "plan-delete-topic");
      result.put("dbPath", dbPath);
      result.put("topicId", Long.valueOf(topicId));
      try {
        Node topic = db.getNodeById(topicId);
        result.put("topic", topicReport(topic, Long.valueOf(workspaceTopicmapId), expectedUri));
        result.put("plan", planReport(buildDeletePlan(topic, workspaceTopicmapId, expectedUri)));
      } catch (NotFoundException e) {
        result.put("topic", missingTopicReport(topicId));
      }
      transaction.success();
      System.out.println(toJson(result));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static void runDeleteTopic(String dbPath, long topicId, long workspaceTopicmapId, String expectedUri) {
    GraphDatabaseService db = new EmbeddedGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "delete-topic");
      result.put("dbPath", dbPath);
      result.put("topicId", Long.valueOf(topicId));
      result.put("workspaceTopicmapId", Long.valueOf(workspaceTopicmapId));
      result.put("expectedUri", expectedUri);
      try {
        Node topic = db.getNodeById(topicId);
        DeletePlan plan = buildDeletePlan(topic, workspaceTopicmapId, expectedUri);
        result.put("plan", planReport(plan));
        if (!plan.refusalReasons.isEmpty()) {
          result.put("status", "refused");
          transaction.success();
          System.out.println(toJson(result));
          return;
        }

        List<Map<String, Object>> relationshipReports = plan.relationshipReports();
        List<Map<String, Object>> nodeReports = plan.nodeReports();
        for (Relationship relationship : new ArrayList<Relationship>(plan.relationships)) {
          relationship.delete();
        }
        for (Node node : new ArrayList<Node>(plan.nodes)) {
          node.delete();
        }
        result.put("status", "deleted");
        result.put("deletedRelationships", relationshipReports);
        result.put("deletedNodes", nodeReports);
        transaction.success();
        System.out.println(toJson(result));
      } catch (NotFoundException e) {
        result.put("status", "missing");
        result.put("topic", missingTopicReport(topicId));
        transaction.success();
        System.out.println(toJson(result));
      }
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }


  private static Map<String, Object> relationshipReport(Relationship relationship) {
    Map<String, Object> report = new LinkedHashMap<String, Object>();
    report.put("id", Long.valueOf(relationship.getId()));
    report.put("type", relationship.getType().name());
    report.put("startNodeId", Long.valueOf(relationship.getStartNode().getId()));
    report.put("endNodeId", Long.valueOf(relationship.getEndNode().getId()));
    return report;
  }

  private static List<Map<String, Object>> incidentRelationshipReports(Node node) {
    List<Map<String, Object>> reports = new ArrayList<Map<String, Object>>();
    for (Relationship relationship : node.getRelationships()) {
      Map<String, Object> report = relationshipReport(relationship);
      Node other = relationship.getOtherNode(node);
      report.put("otherNodeId", Long.valueOf(other.getId()));
      report.put("otherTypeUri", stringProp(other, "typeUri"));
      report.put("otherUri", stringProp(other, "uri"));
      report.put("otherValue", stringProp(other, "value"));
      reports.add(report);
    }
    return reports;
  }

  private static void runForceDetachDeleteTopic(String dbPath, long topicId, String expectedUri, String confirmation) {
    String requiredConfirmation = "I_UNDERSTAND_THIS_DETACH_DELETES_PRIMARY_TOPIC_ONLY";
    GraphDatabaseService db = new EmbeddedGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "force-detach-delete-topic");
      result.put("dbPath", dbPath);
      result.put("topicId", Long.valueOf(topicId));
      result.put("expectedUri", expectedUri);
      result.put("mode", "emergency-detach-delete-primary-topic-only");
      result.put("warning", "This deletes every relationship incident on the primary topic and then deletes only the primary topic node. It intentionally does not prove or clean the broader DMX semantic closure. Orphan association/context nodes may remain.");

      if (!requiredConfirmation.equals(confirmation)) {
        result.put("status", "refused");
        List<String> reasons = new ArrayList<String>();
        reasons.add("confirmation token mismatch; required: " + requiredConfirmation);
        result.put("refusalReasons", reasons);
        transaction.success();
        System.out.println(toJson(result));
        return;
      }

      try {
        Node topic = db.getNodeById(topicId);
        Map<String, Object> before = topicReport(topic, null, expectedUri);
        result.put("topicBefore", before);

        List<String> reasons = new ArrayList<String>();
        String actualUri = stringProp(topic, "uri");
        if (actualUri == null || !actualUri.equals(expectedUri)) {
          reasons.add("expected URI does not match actual URI");
        }
        if (!OWNERSHIP_ANNOTATION.equals(ownershipClass(topic))) {
          reasons.add("topic is not a HyperDoc workspace annotation");
        }
        if (!TYPE_NOTE.equals(stringProp(topic, "typeUri"))) {
          reasons.add("topic type is not dmx.notes.note");
        }
        if (!"n/a".equals(workspaceStatus(topic))) {
          reasons.add("workspace status is not n/a");
        }

        List<Relationship> incident = new ArrayList<Relationship>();
        for (Relationship relationship : topic.getRelationships()) {
          incident.add(relationship);
        }
        List<Map<String, Object>> relationshipReports = incidentRelationshipReports(topic);
        result.put("detachedRelationshipCount", Integer.valueOf(incident.size()));
        result.put("detachedRelationships", relationshipReports);
        result.put("deletedNode", before);

        if (!reasons.isEmpty()) {
          result.put("status", "refused");
          result.put("refusalReasons", reasons);
          transaction.success();
          System.out.println(toJson(result));
          return;
        }

        for (Relationship relationship : incident) {
          relationship.delete();
        }
        topic.delete();
        result.put("status", "deleted-primary-topic-only");
        result.put("postcondition", "primary topic node was deleted after detaching all incident relationships; related association/context/composition/child nodes were not deleted by this emergency command");
        transaction.success();
        System.out.println(toJson(result));
      } catch (NotFoundException e) {
        result.put("status", "missing");
        result.put("topic", missingTopicReport(topicId));
        transaction.success();
        System.out.println(toJson(result));
      }
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }


  private static List<Long> parseIdCsv(String csv) {
    List<Long> ids = new ArrayList<Long>();
    if (csv == null || csv.trim().isEmpty()) {
      return ids;
    }
    String[] parts = csv.split(",");
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i].trim();
      if (!part.isEmpty()) {
        ids.add(Long.valueOf(Long.parseLong(part)));
      }
    }
    return ids;
  }

  private static boolean isAllowedOrphanAssociationDeleteTarget(Node node) {
    String typeUri = stringProp(node, "typeUri");
    return TYPE_TOPICMAP_CONTEXT.equals(typeUri)
        || TYPE_COMPOSITION.equals(typeUri)
        || TYPE_ASSOCIATION.equals(typeUri)
        || TYPE_INSTANTIATION.equals(typeUri);
  }

  private static Map<String, Object> nodeBriefReport(Node node) {
    Map<String, Object> report = new LinkedHashMap<String, Object>();
    report.put("id", Long.valueOf(node.getId()));
    report.put("typeUri", stringProp(node, "typeUri"));
    report.put("uri", stringProp(node, "uri"));
    report.put("value", stringProp(node, "value"));
    report.put("relationshipCount", Integer.valueOf(countRelationships(node)));
    return report;
  }

  private static int countRelationships(Node node) {
    int count = 0;
    for (Relationship ignored : node.getRelationships()) {
      count++;
    }
    return count;
  }

  private static void collectInstantiationsForOrphanAssoc(Node node, LinkedHashSet<Node> nodes) {
    for (Relationship relationship : node.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.instance")) {
        continue;
      }
      Node other = relationship.getOtherNode(node);
      if (TYPE_INSTANTIATION.equals(stringProp(other, "typeUri"))) {
        nodes.add(other);
      }
    }
  }

  private static Map<String, Object> planForceDeleteOrphanAssocNodes(GraphDatabaseService db, List<Long> ids) {
    Map<String, Object> plan = new LinkedHashMap<String, Object>();
    List<String> refusalReasons = new ArrayList<String>();
    LinkedHashSet<Node> nodes = new LinkedHashSet<Node>();
    LinkedHashSet<Relationship> relationships = new LinkedHashSet<Relationship>();
    List<Map<String, Object>> requested = new ArrayList<Map<String, Object>>();

    for (Long id : ids) {
      Map<String, Object> request = new LinkedHashMap<String, Object>();
      request.put("id", id);
      try {
        Node node = db.getNodeById(id.longValue());
        request.put("exists", Boolean.TRUE);
        request.put("node", nodeBriefReport(node));
        if (!isAllowedOrphanAssociationDeleteTarget(node)) {
          refusalReasons.add("node " + id + " has unsupported typeUri=" + stringProp(node, "typeUri"));
        } else {
          nodes.add(node);
          collectInstantiationsForOrphanAssoc(node, nodes);
        }
      } catch (NotFoundException e) {
        request.put("exists", Boolean.FALSE);
        refusalReasons.add("node " + id + " does not exist");
      }
      requested.add(request);
    }

    for (Node node : nodes) {
      for (Relationship relationship : node.getRelationships()) {
        relationships.add(relationship);
      }
    }

    List<Map<String, Object>> nodeReports = new ArrayList<Map<String, Object>>();
    for (Node node : nodes) {
      nodeReports.add(nodeBriefReport(node));
    }
    List<Map<String, Object>> relationshipReports = new ArrayList<Map<String, Object>>();
    for (Relationship relationship : relationships) {
      relationshipReports.add(relationshipReport(relationship));
    }

    plan.put("operation", "force-delete-orphan-assoc-nodes");
    plan.put("status", refusalReasons.isEmpty() ? "deletable" : "refused");
    plan.put("refusalReasons", refusalReasons);
    plan.put("requestedNodes", requested);
    plan.put("nodeCount", Integer.valueOf(nodes.size()));
    plan.put("relationshipCount", Integer.valueOf(relationships.size()));
    plan.put("nodes", nodeReports);
    plan.put("relationships", relationshipReports);
    plan.put("warning", "Emergency cleanup for association/context/composition nodes orphaned by force-detach-delete-topic. Deletes listed association-like nodes and their incident relationships; also deletes directly attached dmx.core.instantiation helper nodes.");
    return plan;
  }

  private static void runPlanForceDeleteOrphanAssocNodes(String dbPath, String csv) {
    GraphDatabaseService db = new EmbeddedReadOnlyGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      List<Long> ids = parseIdCsv(csv);
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "plan-force-delete-orphan-assoc-nodes");
      result.put("dbPath", dbPath);
      result.put("requestedIds", ids);
      result.put("plan", planForceDeleteOrphanAssocNodes(db, ids));
      transaction.success();
      System.out.println(toJson(result));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static void runForceDeleteOrphanAssocNodes(String dbPath, String csv, String confirmation) {
    String requiredConfirmation = "I_UNDERSTAND_THIS_DELETES_LISTED_ASSOCIATION_NODES";
    GraphDatabaseService db = new EmbeddedGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      List<Long> ids = parseIdCsv(csv);
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "force-delete-orphan-assoc-nodes");
      result.put("dbPath", dbPath);
      result.put("requestedIds", ids);
      result.put("mode", "emergency-delete-listed-association-like-nodes");
      result.put("warning", "This deletes the listed association/context/composition nodes and their incident relationships. It is intended only after force-detach-delete-topic leaves one-player associations that break DMX topicmap fetches.");

      if (!requiredConfirmation.equals(confirmation)) {
        result.put("status", "refused");
        List<String> reasons = new ArrayList<String>();
        reasons.add("confirmation token mismatch; required: " + requiredConfirmation);
        result.put("refusalReasons", reasons);
        transaction.success();
        System.out.println(toJson(result));
        return;
      }

      Map<String, Object> plan = planForceDeleteOrphanAssocNodes(db, ids);
      result.put("plan", plan);
      if (!"deletable".equals(String.valueOf(plan.get("status")))) {
        result.put("status", "refused");
        result.put("refusalReasons", plan.get("refusalReasons"));
        transaction.success();
        System.out.println(toJson(result));
        return;
      }

      LinkedHashSet<Node> nodes = new LinkedHashSet<Node>();
      LinkedHashSet<Relationship> relationships = new LinkedHashSet<Relationship>();
      for (Long id : ids) {
        Node node = db.getNodeById(id.longValue());
        nodes.add(node);
        collectInstantiationsForOrphanAssoc(node, nodes);
      }
      for (Node node : nodes) {
        for (Relationship relationship : node.getRelationships()) {
          relationships.add(relationship);
        }
      }
      List<Map<String, Object>> relationshipReports = new ArrayList<Map<String, Object>>();
      for (Relationship relationship : relationships) {
        relationshipReports.add(relationshipReport(relationship));
      }
      List<Map<String, Object>> nodeReports = new ArrayList<Map<String, Object>>();
      for (Node node : nodes) {
        nodeReports.add(nodeBriefReport(node));
      }

      for (Relationship relationship : new ArrayList<Relationship>(relationships)) {
        relationship.delete();
      }
      for (Node node : new ArrayList<Node>(nodes)) {
        node.delete();
      }
      result.put("status", "deleted-orphan-association-nodes");
      result.put("deletedRelationships", relationshipReports);
      result.put("deletedNodes", nodeReports);
      result.put("postcondition", "listed orphan association-like nodes and directly attached instantiation helper nodes were deleted; ordinary topics/workspaces/topicmaps were not deletion targets");
      transaction.success();
      System.out.println(toJson(result));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static void runReportWorkspaceNaCandidates(String dbPath, long workspaceTopicmapId) {
    GraphDatabaseService db = new EmbeddedReadOnlyGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      List<Map<String, Object>> candidates = new ArrayList<Map<String, Object>>();
      for (Node node : db.getAllNodes()) {
        if (!OWNERSHIP_ANNOTATION.equals(ownershipClass(node))) {
          continue;
        }
        if (!"n/a".equals(workspaceStatus(node))) {
          continue;
        }
        if (!hasMembershipInTopicmap(node, workspaceTopicmapId)) {
          continue;
        }
        String uri = stringProp(node, "uri");
        if (!supportedAnnotationEnvelope(node, workspaceTopicmapId, uri)) {
          continue;
        }
        Map<String, Object> candidate = new LinkedHashMap<String, Object>();
        candidate.put("topicId", Long.valueOf(node.getId()));
        candidate.put("expectedTopicmapId", Long.valueOf(workspaceTopicmapId));
        candidate.put("expectedOwnershipClass", OWNERSHIP_ANNOTATION);
        candidate.put("expectedUri", uri);
        candidate.put("typeUri", stringProp(node, "typeUri"));
        candidate.put("title", noteTitleForTopic(node));
        candidate.put("topicmapMemberships", topicmapMembershipsForTopic(node));
        candidates.add(candidate);
      }
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", TOOL);
      result.put("command", "report-workspace-na-candidates");
      result.put("dbPath", dbPath);
      result.put("workspaceTopicmapId", Long.valueOf(workspaceTopicmapId));
      result.put("candidateCount", Integer.valueOf(candidates.size()));
      result.put("candidates", candidates);
      transaction.success();
      System.out.println(toJson(result));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static void runDeleteManifest(String dbPath, String manifestPath) throws IOException {
    List<Map<String, Object>> rows = readManifest(manifestPath);
    GraphDatabaseService db = new EmbeddedGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      List<Map<String, Object>> rowResults = new ArrayList<Map<String, Object>>();
      List<DeletePlan> plans = new ArrayList<DeletePlan>();
      boolean refused = false;

      // Phase 1: build every plan without mutating. The manifest command is all-or-nothing.
      for (Map<String, Object> row : rows) {
        long topicId = ((Long) row.get("topicId")).longValue();
        long topicmapId = ((Long) row.get("workspaceTopicmapId")).longValue();
        String expectedOwnershipClass = String.valueOf(row.get("expectedOwnershipClass"));
        String expectedUri = String.valueOf(row.get("expectedUri"));
        Map<String, Object> result = new LinkedHashMap<String, Object>();
        result.put("topicId", Long.valueOf(topicId));
        result.put("workspaceTopicmapId", Long.valueOf(topicmapId));
        result.put("expectedUri", expectedUri);
        try {
          Node topic = db.getNodeById(topicId);
          if (!OWNERSHIP_ANNOTATION.equals(expectedOwnershipClass)) {
            result.put("status", "refused");
            List<String> reasons = new ArrayList<String>();
            reasons.add("manifest expectedOwnershipClass is not supported: " + expectedOwnershipClass);
            result.put("refusalReasons", reasons);
            refused = true;
          } else {
            DeletePlan plan = buildDeletePlan(topic, topicmapId, expectedUri);
            plans.add(plan);
            result.put("plan", planReport(plan));
            if (!plan.refusalReasons.isEmpty()) {
              result.put("status", "refused");
              refused = true;
            } else {
              result.put("status", "planned");
            }
          }
        } catch (NotFoundException e) {
          result.put("status", "missing");
          refused = true;
        }
        rowResults.add(result);
      }

      Map<String, Object> output = new LinkedHashMap<String, Object>();
      output.put("tool", TOOL);
      output.put("command", "delete-manifest");
      output.put("dbPath", dbPath);
      output.put("manifestPath", manifestPath);

      if (refused) {
        output.put("status", "refused");
        output.put("message", "manifest delete is all-or-nothing; no mutation was performed because at least one row was refused or missing");
        output.put("results", rowResults);
        transaction.success();
        System.out.println(toJson(output));
        return;
      }

      List<Map<String, Object>> deleteResults = new ArrayList<Map<String, Object>>();
      for (DeletePlan plan : plans) {
        Map<String, Object> deleteResult = new LinkedHashMap<String, Object>();
        deleteResult.put("topicId", Long.valueOf(plan.topicId));
        deleteResult.put("workspaceTopicmapId", Long.valueOf(plan.workspaceTopicmapId));
        deleteResult.put("expectedUri", plan.expectedUri);
        deleteResult.put("deletedRelationships", plan.relationshipReports());
        deleteResult.put("deletedNodes", plan.nodeReports());
        for (Relationship relationship : new ArrayList<Relationship>(plan.relationships)) {
          relationship.delete();
        }
        for (Node node : new ArrayList<Node>(plan.nodes)) {
          node.delete();
        }
        deleteResult.put("status", "deleted");
        deleteResults.add(deleteResult);
      }

      output.put("status", "deleted");
      output.put("plannedRows", rowResults);
      output.put("results", deleteResults);
      transaction.success();
      System.out.println(toJson(output));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static List<Map<String, Object>> readManifest(String manifestPath) throws IOException {
    List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
    BufferedReader reader = new BufferedReader(new FileReader(manifestPath));
    try {
      String line;
      int lineNumber = 0;
      while ((line = reader.readLine()) != null) {
        lineNumber++;
        line = line.trim();
        if (line.length() == 0 || line.startsWith("#")) {
          continue;
        }
        if (lineNumber == 1 && line.startsWith("topicId\t")) {
          continue;
        }
        String[] columns = line.split("\t", -1);
        if (columns.length < 4) {
          throw new IllegalArgumentException("Manifest line " + lineNumber
              + " needs 4 tab-separated columns: topicId workspaceTopicmapId expectedOwnershipClass expectedUri");
        }
        Map<String, Object> row = new LinkedHashMap<String, Object>();
        row.put("topicId", Long.valueOf(columns[0]));
        row.put("workspaceTopicmapId", Long.valueOf(columns[1]));
        row.put("expectedOwnershipClass", columns[2]);
        row.put("expectedUri", columns[3]);
        rows.add(row);
      }
    } finally {
      reader.close();
    }
    return rows;
  }

  private static class DeletePlan {
    final long topicId;
    long workspaceTopicmapId;
    String expectedUri;
    final LinkedHashSet<Node> nodes = new LinkedHashSet<Node>();
    final LinkedHashSet<Relationship> relationships = new LinkedHashSet<Relationship>();
    final Map<Long, String> nodeRoles = new LinkedHashMap<Long, String>();
    final List<String> refusalReasons = new ArrayList<String>();

    DeletePlan(long topicId) {
      this.topicId = topicId;
    }

    void addNode(Node node, String role) {
      nodes.add(node);
      if (!nodeRoles.containsKey(Long.valueOf(node.getId()))) {
        nodeRoles.put(Long.valueOf(node.getId()), role);
      }
    }

    void addRelationship(Relationship relationship) {
      relationships.add(relationship);
    }

    void refuse(String reason) {
      if (!refusalReasons.contains(reason)) {
        refusalReasons.add(reason);
      }
    }

    List<Map<String, Object>> nodeReports() {
      List<Map<String, Object>> reports = new ArrayList<Map<String, Object>>();
      for (Node node : nodes) {
        Map<String, Object> report = new LinkedHashMap<String, Object>();
        report.put("id", Long.valueOf(node.getId()));
        report.put("role", nodeRoles.get(Long.valueOf(node.getId())));
        report.put("typeUri", stringProp(node, "typeUri"));
        report.put("uri", stringProp(node, "uri"));
        report.put("value", stringProp(node, "value"));
        reports.add(report);
      }
      return reports;
    }

    List<Map<String, Object>> relationshipReports() {
      List<Map<String, Object>> reports = new ArrayList<Map<String, Object>>();
      for (Relationship relationship : relationships) {
        Map<String, Object> report = new LinkedHashMap<String, Object>();
        report.put("id", Long.valueOf(relationship.getId()));
        report.put("type", relationship.getType().name());
        report.put("startNodeId", Long.valueOf(relationship.getStartNode().getId()));
        report.put("endNodeId", Long.valueOf(relationship.getEndNode().getId()));
        reports.add(report);
      }
      return reports;
    }
  }

  private static void appendJson(StringBuilder builder, Object value) {
    if (value == null) {
      builder.append("null");
    } else if (value instanceof String) {
      builder.append('"');
      builder.append(escapeJson((String) value));
      builder.append('"');
    } else if (value instanceof Number || value instanceof Boolean) {
      builder.append(String.valueOf(value));
    } else if (value instanceof Map) {
      builder.append('{');
      Iterator<?> iterator = ((Map<?, ?>) value).entrySet().iterator();
      boolean first = true;
      while (iterator.hasNext()) {
        Map.Entry<?, ?> entry = (Map.Entry<?, ?>) iterator.next();
        if (!first) {
          builder.append(',');
        }
        first = false;
        appendJson(builder, String.valueOf(entry.getKey()));
        builder.append(':');
        appendJson(builder, entry.getValue());
      }
      builder.append('}');
    } else if (value instanceof Iterable) {
      builder.append('[');
      boolean first = true;
      for (Object element : (Iterable<?>) value) {
        if (!first) {
          builder.append(',');
        }
        first = false;
        appendJson(builder, element);
      }
      builder.append(']');
    } else {
      appendJson(builder, String.valueOf(value));
    }
  }

  private static String escapeJson(String string) {
    StringBuilder builder = new StringBuilder();
    for (int i = 0; i < string.length(); i++) {
      char ch = string.charAt(i);
      switch (ch) {
        case '"':
          builder.append("\\\"");
          break;
        case '\\':
          builder.append("\\\\");
          break;
        case '\b':
          builder.append("\\b");
          break;
        case '\f':
          builder.append("\\f");
          break;
        case '\n':
          builder.append("\\n");
          break;
        case '\r':
          builder.append("\\r");
          break;
        case '\t':
          builder.append("\\t");
          break;
        default:
          if (ch < 0x20) {
            builder.append(String.format("\\u%04x", Integer.valueOf(ch)));
          } else {
            builder.append(ch);
          }
      }
    }
    return builder.toString();
  }

  private static String toJson(Object value) {
    StringBuilder builder = new StringBuilder();
    appendJson(builder, value);
    return builder.toString();
  }

  private static void usage() {
    throw new IllegalArgumentException(
        "usage: " + TOOL + " report-topic <db-path> <topic-id> | "
        + "plan-delete-topic <db-path> <topic-id> <workspace-topicmap-id> <expected-uri> | "
        + "delete-topic <db-path> <topic-id> <workspace-topicmap-id> <expected-uri> | "
        + "force-detach-delete-topic <db-path> <topic-id> <expected-uri> I_UNDERSTAND_THIS_DETACH_DELETES_PRIMARY_TOPIC_ONLY | "
        + "plan-force-delete-orphan-assoc-nodes <db-path> <node-id-csv> | "
        + "force-delete-orphan-assoc-nodes <db-path> <node-id-csv> I_UNDERSTAND_THIS_DELETES_LISTED_ASSOCIATION_NODES | "
        + "report-workspace-na-candidates <db-path> <workspace-topicmap-id> | "
        + "delete-manifest <db-path> <manifest.tsv>");
  }

  public static void main(String[] args) throws Exception {
    if (args.length < 1) {
      usage();
    }
    String command = args[0];
    if ("report-topic".equals(command)) {
      if (args.length != 3) {
        usage();
      }
      runReportTopic(args[1], Long.parseLong(args[2]));
      return;
    }
    if ("plan-delete-topic".equals(command)) {
      if (args.length != 5) {
        usage();
      }
      runPlanDeleteTopic(args[1], Long.parseLong(args[2]), Long.parseLong(args[3]), args[4]);
      return;
    }
    if ("delete-topic".equals(command)) {
      if (args.length != 5) {
        usage();
      }
      runDeleteTopic(args[1], Long.parseLong(args[2]), Long.parseLong(args[3]), args[4]);
      return;
    }
    if ("force-detach-delete-topic".equals(command)) {
      if (args.length != 5) {
        usage();
      }
      runForceDetachDeleteTopic(args[1], Long.parseLong(args[2]), args[3], args[4]);
      return;
    }
    if ("plan-force-delete-orphan-assoc-nodes".equals(command)) {
      if (args.length != 3) {
        usage();
      }
      runPlanForceDeleteOrphanAssocNodes(args[1], args[2]);
      return;
    }
    if ("force-delete-orphan-assoc-nodes".equals(command)) {
      if (args.length != 4) {
        usage();
      }
      runForceDeleteOrphanAssocNodes(args[1], args[2], args[3]);
      return;
    }
    if ("report-workspace-na-candidates".equals(command)) {
      if (args.length != 3) {
        usage();
      }
      runReportWorkspaceNaCandidates(args[1], Long.parseLong(args[2]));
      return;
    }
    if ("delete-manifest".equals(command)) {
      if (args.length != 3) {
        usage();
      }
      runDeleteManifest(args[1], args[2]);
      return;
    }
    throw new IllegalArgumentException("Unsupported command: " + command);
  }
}
