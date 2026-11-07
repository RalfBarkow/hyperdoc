// Test transport adapter. The pinned Main.java resolver bodies are unchanged.
import java.io.*;
import java.net.*;
import java.net.http.*;
import java.lang.reflect.*;
import java.util.*;
import java.util.concurrent.*;
import java.time.Duration;
import javax.net.ssl.*;
import com.fasterxml.jackson.databind.*;

public class OfflineReferenceProbe {
  static final ObjectMapper mapper = new ObjectMapper();
  static final Map<String, JsonNode> responses = new HashMap<>();
  static final List<String> trace = new ArrayList<>(), sitemaps = new ArrayList<>();
  static final Map<String,Object> evidence = new LinkedHashMap<>();
  static final HttpClient transport = new StubClient();
  static int sitemapStatus=200;
  public static HttpClient client() { return transport; }
  static Field field(Class<?> type, String name) throws Exception {
    Field f=type.getDeclaredField(name); f.setAccessible(true); return f;
  }
  static Method method(Class<?> type, String name, Class<?>... args) throws Exception {
    Method m=type.getDeclaredMethod(name,args);m.setAccessible(true);return m;
  }
  static List<String> strings(JsonNode array) {
    List<String> out=new ArrayList<>(); if(array!=null) for(JsonNode x:array) out.add(x.isNull()?null:x.asText());return out;
  }
  public static void main(String[] args) throws Exception {
    Locale.setDefault(Locale.ENGLISH);
    JsonNode spec=null;
    for(JsonNode x:mapper.readTree(new File(args[0])).get("cases"))
      if(x.get("id").asText().equals(args[1])) spec=x;
    if(spec==null) throw new AssertionError("Unknown fixture");
    if(spec.has("sitemapStatus")) sitemapStatus=spec.get("sitemapStatus").asInt();
    for(JsonNode x:spec.get("responses")) responses.put(x.get("site").asText(),x);
    Main.origin="origin";
    Class<?> panel=Class.forName("Main$Panel");
    Constructor<?> constructor=panel.getDeclaredConstructor(String.class,String.class);constructor.setAccessible(true);
    Object from=constructor.newInstance(spec.get("panel").asText(),"source");
    Main.Page page=new Main.Page();
    Main.Item item=new Main.Item();item.type="paragraph";item.text="[[Target]] [[Ignored]]";
    if(!spec.get("itemSite").isNull()) item.site=spec.get("itemSite").asText();
    int sourceItemno=spec.has("sourceItemno")?spec.get("sourceItemno").asInt():0;
    if(sourceItemno==1) {
      Main.Item first=new Main.Item();first.text="[[Ignored]]";first.site=spec.get("firstItemSite").asText();
      page.story=List.of(first,item);
    } else page.story=List.of(item);
    page.title="Source";
    List<Main.Action> journal=new ArrayList<>();
    for(String site:strings(spec.get("journal"))) {Main.Action a=new Main.Action();a.site=site;a.type="edit";journal.add(a);}
    page.journal=journal;
    field(panel,"page").set(from,page);field(panel,"itemno").set(from,sourceItemno);
    @SuppressWarnings("unchecked") List<Object> lineup=(List<Object>)field(Main.class,"lineup").get(null);
    lineup.add(from);
    evidence.put("id",args[1]); evidence.put("pageContext",page.context());
    evidence.put("sourcePanelSite",field(panel,"site").get(from));
    evidence.put("sourceItemSite",item.site);evidence.put("sourceItemType",item.type);
    evidence.put("initialLineupSize",lineup.size());evidence.put("initialNeighborhood",new ArrayList<>(Main.neighborhood.keySet()));
    evidence.put("sourceItemno",sourceItemno);
    evidence.put("panelContext",method(panel,"context").invoke(from));evidence.put("links",item.links());
    Runtime.getRuntime().addShutdownHook(new Thread(() -> {
      try {
        evidence.put("trace",trace);evidence.put("sitemaps",sitemaps);evidence.put("lineupSize",lineup.size());
        evidence.put("neighborhood",new TreeSet<>(Main.neighborhood.keySet()));
        evidence.put("nullSitemaps",Main.neighborhood.values().stream().filter(Objects::isNull).count());
        System.out.println("EVIDENCE "+mapper.writeValueAsString(evidence));
      } catch(Exception e) {throw new RuntimeException(e);}
    }));
    int repeat=spec.has("repeat")?spec.get("repeat").asInt():1;
    for(int i=0;i<repeat;i++) method(Main.class,"link",panel).invoke(null,from);
    Object selected=lineup.get(lineup.size()-1);
    evidence.put("site",field(panel,"site").get(selected));
    evidence.put("itemno",field(panel,"itemno").get(selected));
    // Check the single-site overload: it does not enlarge the neighborhood.
    int mapsBefore=sitemaps.size();
    method(panel,"load",String.class,String.class).invoke(null,evidence.get("site"),"target");
    evidence.put("explicitLoadEnlarges",sitemaps.size()!=mapsBefore);
    evidence.put("linkTrace",new ArrayList<>(trace.subList(0,trace.size()-1)));
    Main.Item unicode=new Main.Item(); unicode.text="[[I Ä]] [[Second]]";
    evidence.put("englishSlug",unicode.links());Locale.setDefault(Locale.forLanguageTag("tr-TR"));
    evidence.put("turkishSlug",unicode.links());
  }
  static class StubClient extends HttpClient {
    public Optional<java.net.CookieHandler> cookieHandler(){return Optional.empty();}
    public Optional<Duration> connectTimeout(){return Optional.empty();}
    public Redirect followRedirects(){return Redirect.NEVER;}
    public Optional<java.net.ProxySelector> proxy(){return Optional.empty();}
    public SSLContext sslContext(){try{return SSLContext.getDefault();}catch(Exception e){throw new RuntimeException(e);}}
    public SSLParameters sslParameters(){return new SSLParameters();}
    public Optional<java.net.Authenticator> authenticator(){return Optional.empty();}
    public Version version(){return Version.HTTP_1_1;}
    public Optional<Executor> executor(){return Optional.empty();}
    public <T> HttpResponse<T> send(HttpRequest request,HttpResponse.BodyHandler<T> handler) throws IOException {
      URI uri=request.uri();String site=uri.getHost();int status;String body;
      if(uri.getPath().equals("/system/sitemap.json")) {
        sitemaps.add(site);status=sitemapStatus;body="[]";
      } else {
        trace.add(site);JsonNode spec=responses.get(site);
        if(spec==null) throw new AssertionError("Undeclared availability, not a 404: "+uri);
        String kind=spec.get("kind").asText();
        if(kind.equals("network-error")) throw new IOException("fixture network failure");
        status=kind.equals("page")?200:kind.equals("absent")?404:spec.get("status").asInt();
        var page=new LinkedHashMap<String,Object>();page.put("title","Target");
        page.put("story",List.of(Map.of("type","paragraph","text","Loaded")));
        List<Object> journal=new ArrayList<>();
        for(String s:strings(spec.get("journal"))) journal.add(Map.of("type","edit","site",s));
        page.put("journal",journal);body=mapper.writeValueAsString(page);
      }
      final int code=status;final String content=body;
      return new HttpResponse<T>() {
        public int statusCode(){return code;} public HttpRequest request(){return request;}
        public Optional<HttpResponse<T>> previousResponse(){return Optional.empty();}
        public HttpHeaders headers(){return HttpHeaders.of(Map.of(),(a,b)->true);}
        @SuppressWarnings("unchecked") public T body(){return (T)content;}
        public Optional<SSLSession> sslSession(){return Optional.empty();}
        public URI uri(){return uri;}public Version version(){return Version.HTTP_1_1;}
      };
    }
    public <T> CompletableFuture<HttpResponse<T>> sendAsync(HttpRequest r,HttpResponse.BodyHandler<T> h){throw new UnsupportedOperationException();}
    public <T> CompletableFuture<HttpResponse<T>> sendAsync(HttpRequest r,HttpResponse.BodyHandler<T> h,HttpResponse.PushPromiseHandler<T> p){throw new UnsupportedOperationException();}
  }
}
