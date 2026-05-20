import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.neo4j.graphdb.GraphDatabaseService;
import org.neo4j.graphdb.Node;
import org.neo4j.graphdb.PropertyContainer;
import org.neo4j.graphdb.Relationship;
import org.neo4j.graphdb.Transaction;
import org.neo4j.kernel.EmbeddedReadOnlyGraphDatabase;

/**
 * Read-only offline inventory for DMX topics with no workspace assignment.
 *
 * A topic is unassigned only when both assignment facts are absent:
 *   - no dmx.workspaces.workspace_id property on the topic node
 *   - no dmx.workspaces.workspace_assignment association connected to a workspace
 *
 * Topicmap placement is reported as evidence but never treated as workspace
 * assignment.
 */
public class HyperdocNeo4jUnassignedTopicsTool {
  private static final String TOOL = "HyperdocNeo4jUnassignedTopicsTool";
  private static final String TYPE_WORKSPACE_ASSIGNMENT = "dmx.workspaces.workspace_assignment";
  private static final String TYPE_WORKSPACE = "dmx.workspaces.workspace";
  private static final String TYPE_TOPICMAP_CONTEXT = "dmx.topicmaps.topicmap_context";
  private static final String ANNOTATION_URI_PREFIX = "hyperdoc:mcp/workspace-annotation/";

  private static class Options {
    String dbPath;
    Integer limit;
    Integer offset;
    Long topicmapId;
    String uriPrefix;
    String typeUri;
  }

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

  private static List<Map<String, Object>> workspaceAssignmentsForTopic(Node topicNode) {
    List<Map<String, Object>> assignments = new ArrayList<Map<String, Object>>();
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
          report.put("topicRelationshipId", Long.valueOf(relationship.getId()));
          report.put("workspaceRelationshipId", Long.valueOf(assignmentRelationship.getId()));
          report.put("workspaceId", Long.valueOf(workspace.getId()));
          report.put("workspaceTitle", stringProp(workspace, "value"));
          report.put("workspaceUri", stringProp(workspace, "uri"));
          assignments.add(report);
        }
      }
    }
    return assignments;
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
      for (Relationship contextRelationship : context.getRelationships()) {
        if (!relationshipType(contextRelationship, "dmx.core.default")) {
          continue;
        }
        Node topicmap = contextRelationship.getOtherNode(context);
        Map<String, Object> entry = new LinkedHashMap<String, Object>();
        entry.put("topicmapId", Long.valueOf(topicmap.getId()));
        entry.put("contextAssocId", Long.valueOf(context.getId()));
        entry.put("contentRelationshipId", Long.valueOf(relationship.getId()));
        entry.put("topicmapRelationshipId", Long.valueOf(contextRelationship.getId()));
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

  private static List<Long> topicmapIds(List<Map<String, Object>> memberships) {
    List<Long> ids = new ArrayList<Long>();
    for (Map<String, Object> membership : memberships) {
      Object value = membership.get("topicmapId");
      if (value instanceof Number) {
        ids.add(Long.valueOf(((Number) value).longValue()));
      }
    }
    return ids;
  }

  private static boolean inTopicmap(List<Long> ids, Long topicmapId) {
    if (topicmapId == null) {
      return true;
    }
    for (Long id : ids) {
      if (id.longValue() == topicmapId.longValue()) {
        return true;
      }
    }
    return false;
  }

  private static String ownershipClass(Node topicNode) {
    String uri = stringProp(topicNode, "uri");
    if (uri != null && uri.startsWith(ANNOTATION_URI_PREFIX)) {
      return "hyperdoc-workspace-annotation";
    }
    return "foreign-or-unsupported";
  }

  private static String workspaceStatus(Node topicNode, Long propertyValue, List<Map<String, Object>> assignments) {
    boolean hasProperty = topicNode.hasProperty("dmx.workspaces.workspace_id");
    boolean hasAssociation = assignments != null && !assignments.isEmpty();
    if (hasProperty && hasAssociation) {
      Object assocValue = assignments.get(0).get("workspaceId");
      if (propertyValue != null && assocValue instanceof Number
          && propertyValue.longValue() != ((Number) assocValue).longValue()) {
        return "inconsistent";
      }
      return "assigned-by-property";
    }
    if (hasProperty) {
      return "assigned-by-property";
    }
    if (hasAssociation) {
      return "assigned-by-association";
    }
    return "unassigned";
  }

  private static boolean matchesFilters(Node node, Options options, List<Long> topicmapIds) {
    String uri = stringProp(node, "uri");
    String typeUri = stringProp(node, "typeUri");
    if (options.typeUri != null && !options.typeUri.equals(typeUri)) {
      return false;
    }
    if (options.uriPrefix != null && (uri == null || !uri.startsWith(options.uriPrefix))) {
      return false;
    }
    if (!inTopicmap(topicmapIds, options.topicmapId)) {
      return false;
    }
    return true;
  }

  private static Map<String, Object> topicRow(Node topicNode) {
    Long workspacePropertyValue = longProp(topicNode, "dmx.workspaces.workspace_id");
    List<Map<String, Object>> assignments = workspaceAssignmentsForTopic(topicNode);
    List<Map<String, Object>> memberships = topicmapMembershipsForTopic(topicNode);
    List<Long> topicmapIds = topicmapIds(memberships);
    String status = workspaceStatus(topicNode, workspacePropertyValue, assignments);

    Map<String, Object> evidence = new LinkedHashMap<String, Object>();
    evidence.put("workspacePropertyExists",
        Boolean.valueOf(topicNode.hasProperty("dmx.workspaces.workspace_id")));
    evidence.put("workspacePropertyValue", workspacePropertyValue);
    evidence.put("workspaceAssignmentExists",
        Boolean.valueOf(assignments != null && !assignments.isEmpty()));
    evidence.put("workspaceAssignments", assignments);
    evidence.put("topicmapMemberships", memberships);

    Map<String, Object> row = new LinkedHashMap<String, Object>();
    row.put("topicId", Long.valueOf(topicNode.getId()));
    row.put("uri", stringProp(topicNode, "uri"));
    row.put("typeUri", stringProp(topicNode, "typeUri"));
    row.put("value", stringProp(topicNode, "value"));
    row.put("workspaceId", workspacePropertyValue);
    row.put("workspaceStatus", status);
    row.put("topicmapIds", topicmapIds);
    row.put("topicmapMemberships", memberships);
    row.put("ownershipClass", ownershipClass(topicNode));
    row.put("evidence", evidence);
    return row;
  }

  private static void runReportUnassignedTopics(Options options) {
    GraphDatabaseService db = new EmbeddedReadOnlyGraphDatabase(options.dbPath);
    Transaction transaction = db.beginTx();
    try {
      List<Map<String, Object>> rows = new ArrayList<Map<String, Object>>();
      int skipped = options.offset == null ? 0 : options.offset.intValue();
      int seenUnassigned = 0;
      for (Node node : db.getAllNodes()) {
        if (stringProp(node, "typeUri") == null) {
          continue;
        }
        Map<String, Object> row = topicRow(node);
        if (!"unassigned".equals(row.get("workspaceStatus"))) {
          continue;
        }
        @SuppressWarnings("unchecked")
        List<Long> ids = (List<Long>) row.get("topicmapIds");
        if (!matchesFilters(node, options, ids)) {
          continue;
        }
        if (seenUnassigned++ < skipped) {
          continue;
        }
        rows.add(row);
        if (options.limit != null && rows.size() >= options.limit.intValue()) {
          break;
        }
      }
      Map<String, Object> report = new LinkedHashMap<String, Object>();
      report.put("tool", TOOL);
      report.put("command", "report-unassigned-topics");
      report.put("dbPath", options.dbPath);
      report.put("limit", options.limit);
      report.put("offset", options.offset);
      report.put("topicmapId", options.topicmapId);
      report.put("uriPrefix", options.uriPrefix);
      report.put("typeUri", options.typeUri);
      report.put("rowCount", Integer.valueOf(rows.size()));
      report.put("rows", rows);
      transaction.success();
      System.out.println(toJson(report));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static Options parseOptions(String[] args) {
    if (args.length < 2 || !"report-unassigned-topics".equals(args[0])) {
      throw new IllegalArgumentException(
          "usage: HyperdocNeo4jUnassignedTopicsTool report-unassigned-topics <db-path> "
          + "[--limit N] [--offset N] [--topicmap-id ID] [--uri-prefix PREFIX] [--type-uri URI]");
    }
    Options options = new Options();
    options.dbPath = args[1];
    for (int i = 2; i < args.length; i++) {
      String option = args[i];
      if ("--limit".equals(option)) {
        options.limit = Integer.valueOf(args[++i]);
      } else if ("--offset".equals(option)) {
        options.offset = Integer.valueOf(args[++i]);
      } else if ("--topicmap-id".equals(option)) {
        options.topicmapId = Long.valueOf(args[++i]);
      } else if ("--uri-prefix".equals(option)) {
        options.uriPrefix = args[++i];
      } else if ("--type-uri".equals(option)) {
        options.typeUri = args[++i];
      } else {
        throw new IllegalArgumentException("Unsupported option: " + option);
      }
    }
    return options;
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

  public static void main(String[] args) {
    Options options = parseOptions(args);
    runReportUnassignedTopics(options);
  }
}
