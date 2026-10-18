import javax.xml.parsers.SAXParserFactory;
import org.apache.xml.resolver.CatalogManager;
import org.apache.xml.resolver.tools.CatalogResolver;
import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;
import java.io.File;

/** Validates DITA files against the DTD their DOCTYPE names, resolved through a DITA-OT catalog. */
public class DitaValidate {
  public static void main(String[] args) throws Exception {
    CatalogManager manager = new CatalogManager();
    manager.setIgnoreMissingProperties(true);
    manager.setCatalogFiles(args[0]);
    manager.setUseStaticCatalog(false);
    manager.setPreferPublic(true);
    CatalogResolver resolver = new CatalogResolver(manager);
    int failures = 0;
    for (int i = 1; i < args.length; i++) {
      SAXParserFactory factory = SAXParserFactory.newInstance();
      factory.setValidating(true);
      XMLReader reader = factory.newSAXParser().getXMLReader();
      reader.setEntityResolver(resolver);
      final int[] problems = {0};
      final String name = args[i];
      reader.setErrorHandler(new DefaultHandler() {
        public void warning(SAXParseException e) { System.err.println(name + ":" + e.getLineNumber() + ": warning: " + e.getMessage()); }
        public void error(SAXParseException e) { problems[0]++; System.err.println(name + ":" + e.getLineNumber() + ": error: " + e.getMessage()); }
        public void fatalError(SAXParseException e) { problems[0]++; System.err.println(name + ":" + e.getLineNumber() + ": fatal: " + e.getMessage()); }
      });
      try { reader.parse(new InputSource(new File(args[i]).toURI().toString())); }
      catch (SAXException e) { problems[0]++; }
      if (problems[0] > 0) failures++; else System.out.println(name + ": valid");
    }
    System.exit(failures == 0 ? 0 : 1);
  }
}
