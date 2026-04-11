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
import org.neo4j.kernel.EmbeddedGraphDatabase;
import org.neo4j.kernel.EmbeddedReadOnlyGraphDatabase;

public class HyperdocNeo4jDuplicateUsernameTool {
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
    return Long.valueOf(String.valueOf(value));
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

  private static boolean relationshipType(Relationship relationship, String typeName) {
    return relationship != null
        && relationship.getType() != null
        && typeName.equals(relationship.getType().name());
  }

  private static Map<String, Object> workspaceAssignmentForTopic(Node topicNode) {
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.parent")) {
        continue;
      }
      Node assignment = relationship.getOtherNode(topicNode);
      if (!"dmx.workspaces.workspace_assignment".equals(stringProp(assignment, "typeUri"))) {
        continue;
      }
      for (Relationship assignmentRelationship : assignment.getRelationships()) {
        if (!relationshipType(assignmentRelationship, "dmx.core.child")) {
          continue;
        }
        Node workspace = assignmentRelationship.getOtherNode(assignment);
        if ("dmx.workspaces.workspace".equals(stringProp(workspace, "typeUri"))) {
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

  private static List<Map<String, Object>> configDefaultsForTopic(Node topicNode) {
    List<Map<String, Object>> defaults = new ArrayList<Map<String, Object>>();
    for (Relationship relationship : topicNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.config.configurable")) {
        continue;
      }
      Node configuration = relationship.getOtherNode(topicNode);
      if (!"dmx.config.configuration".equals(stringProp(configuration, "typeUri"))) {
        continue;
      }
      for (Relationship configurationRelationship : configuration.getRelationships()) {
        if (!relationshipType(configurationRelationship, "dmx.core.default")) {
          continue;
        }
        Node defaultTopic = configurationRelationship.getOtherNode(configuration);
        Map<String, Object> entry = new LinkedHashMap<String, Object>();
        entry.put("configurationId", Long.valueOf(configuration.getId()));
        entry.put("defaultTopicId", Long.valueOf(defaultTopic.getId()));
        entry.put("defaultTypeUri", stringProp(defaultTopic, "typeUri"));
        entry.put("defaultValue", defaultTopic.hasProperty("value")
            ? defaultTopic.getProperty("value")
            : null);
        defaults.add(entry);
      }
    }
    return defaults;
  }

  private static Map<String, Object> passwordTopicForUserAccount(Node userAccountNode) {
    for (Relationship relationship : userAccountNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.parent")) {
        continue;
      }
      Node composition = relationship.getOtherNode(userAccountNode);
      if (!"dmx.core.composition".equals(stringProp(composition, "typeUri"))) {
        continue;
      }
      for (Relationship compositionRelationship : composition.getRelationships()) {
        if (!relationshipType(compositionRelationship, "dmx.core.child")) {
          continue;
        }
        Node child = compositionRelationship.getOtherNode(composition);
        if ("dmx.accesscontrol.password".equals(stringProp(child, "typeUri"))) {
          Map<String, Object> report = new LinkedHashMap<String, Object>();
          report.put("passwordTopicId", Long.valueOf(child.getId()));
          report.put("hasSalt", booleanProp(child, "dmx.accesscontrol.salt") != null
              || child.hasProperty("dmx.accesscontrol.salt"));
          report.put("created", longProp(child, "dmx.timestamps.created"));
          report.put("modified", longProp(child, "dmx.timestamps.modified"));
          return report;
        }
      }
    }
    return null;
  }

  private static List<Map<String, Object>> userAccountsForUsername(Node usernameNode) {
    List<Map<String, Object>> accounts = new ArrayList<Map<String, Object>>();
    for (Relationship relationship : usernameNode.getRelationships()) {
      if (!relationshipType(relationship, "dmx.core.child")) {
        continue;
      }
      Node composition = relationship.getOtherNode(usernameNode);
      if (!"dmx.core.composition".equals(stringProp(composition, "typeUri"))) {
        continue;
      }
      for (Relationship compositionRelationship : composition.getRelationships()) {
        if (!relationshipType(compositionRelationship, "dmx.core.parent")) {
          continue;
        }
        Node userAccount = compositionRelationship.getOtherNode(composition);
        if (!"dmx.accesscontrol.user_account".equals(stringProp(userAccount, "typeUri"))) {
          continue;
        }
        Map<String, Object> account = new LinkedHashMap<String, Object>();
        account.put("userAccountId", Long.valueOf(userAccount.getId()));
        account.put("workspaceId", longProp(userAccount, "dmx.workspaces.workspace_id"));
        account.put("value", stringProp(userAccount, "value"));
        account.put("created", longProp(userAccount, "dmx.timestamps.created"));
        account.put("modified", longProp(userAccount, "dmx.timestamps.modified"));
        account.put("passwordTopic", passwordTopicForUserAccount(userAccount));
        accounts.add(account);
      }
    }
    return accounts;
  }

  private static Map<String, Object> usernameTopicReport(Node usernameNode) {
    Map<String, Object> report = new LinkedHashMap<String, Object>();
    report.put("nodeId", Long.valueOf(usernameNode.getId()));
    report.put("typeUri", stringProp(usernameNode, "typeUri"));
    report.put("value", stringProp(usernameNode, "value"));
    report.put("workspaceId", longProp(usernameNode, "dmx.workspaces.workspace_id"));
    report.put("created", longProp(usernameNode, "dmx.timestamps.created"));
    report.put("modified", longProp(usernameNode, "dmx.timestamps.modified"));
    report.put("workspaceAssignment", workspaceAssignmentForTopic(usernameNode));
    report.put("userAccounts", userAccountsForUsername(usernameNode));
    report.put("configDefaults", configDefaultsForTopic(usernameNode));
    return report;
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

  private static void runReport(String dbPath, String username) {
    GraphDatabaseService db = new EmbeddedReadOnlyGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      List<Map<String, Object>> matches = new ArrayList<Map<String, Object>>();
      for (Node node : db.getAllNodes()) {
        if ("dmx.accesscontrol.username".equals(stringProp(node, "typeUri"))
            && username.equals(stringProp(node, "value"))) {
          matches.add(usernameTopicReport(node));
        }
      }
      Map<String, Object> report = new LinkedHashMap<String, Object>();
      report.put("tool", "HyperdocNeo4jDuplicateUsernameTool");
      report.put("command", "report");
      report.put("dbPath", dbPath);
      report.put("username", username);
      report.put("matchingCount", Integer.valueOf(matches.size()));
      report.put("matchingTopics", matches);
      transaction.success();
      System.out.println(toJson(report));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  private static void runRename(String dbPath, long nodeId, String newValue) {
    GraphDatabaseService db = new EmbeddedGraphDatabase(dbPath);
    Transaction transaction = db.beginTx();
    try {
      Node node = db.getNodeById(nodeId);
      Object oldValue = node.getProperty("value");
      node.setProperty("value", newValue);
      if (node.hasProperty("dmx.timestamps.modified")) {
        node.setProperty("dmx.timestamps.modified", Long.valueOf(System.currentTimeMillis()));
      }
      Map<String, Object> result = new LinkedHashMap<String, Object>();
      result.put("tool", "HyperdocNeo4jDuplicateUsernameTool");
      result.put("command", "rename-stale-username");
      result.put("dbPath", dbPath);
      result.put("nodeId", Long.valueOf(nodeId));
      result.put("oldValue", String.valueOf(oldValue));
      result.put("newValue", newValue);
      transaction.success();
      System.out.println(toJson(result));
    } finally {
      transaction.finish();
      db.shutdown();
    }
  }

  public static void main(String[] args) {
    if (args.length < 3) {
      throw new IllegalArgumentException(
          "usage: HyperdocNeo4jDuplicateUsernameTool report <db-path> <username> | "
          + "rename-stale-username <db-path> <node-id> <new-value>");
    }
    String command = args[0];
    if ("report".equals(command)) {
      runReport(args[1], args[2]);
      return;
    }
    if ("rename-stale-username".equals(command)) {
      if (args.length < 4) {
        throw new IllegalArgumentException(
            "usage: HyperdocNeo4jDuplicateUsernameTool rename-stale-username <db-path> <node-id> <new-value>");
      }
      runRename(args[1], Long.parseLong(args[2]), args[3]);
      return;
    }
    throw new IllegalArgumentException("Unsupported command: " + command);
  }
}
