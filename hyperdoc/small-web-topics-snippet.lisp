(in-package :hyperdoc)

(defun small-web-topic ()
  (make-topic
   :id "small-web"
   :title "Small Web"
   :summary "The small web as a non-commercial publishing and browsing ethos centered on personal sites, feeds, directories, and human-scale discovery rather than platform capture."
   :references '("Small Web and HyperDoc"
                 "Small Web topic arrangement"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun small-web-feed-aggregation-topic ()
  (make-topic
   :id "small-web-feed-aggregation"
   :title "Small Web feed aggregation"
   :summary "Feed aggregation on the small web is useful precisely because it keeps distributed personal publishing legible without requiring full platform centralization."
   :references '("Small Web Discovery and Aggregation"
                 "Small Web Search, Directories, and Discovery"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun small-web-scale-topic ()
  (make-topic
   :id "small-web-scale"
   :title "Small Web scale"
   :summary "The small web is small relative to the commercial web, but still large enough that naive whole-web daily aggregation becomes difficult for human readers."
   :references '("Small Web Discovery and Aggregation"
                 "Small Web and HyperDoc"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun opt-in-aggregation-topic ()
  (make-topic
   :id "opt-in-aggregation"
   :title "Opt-in aggregation"
   :summary "Opt-in aggregators trade coverage for readability, curator control, and manageable daily throughput."
   :references '("Small Web Discovery and Aggregation"
                 "Small Web Search, Directories, and Discovery"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun human-reading-budget-topic ()
  (make-topic
   :id "human-reading-budget"
   :title "Human reading budget"
   :summary "The limiting resource for small-web aggregation is often reader attention rather than storage, bandwidth, or indexing compute."
   :references '("Small Web Discovery and Aggregation"
                 "Publishing Motives in the Small Web"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun feed-required-discovery-topic ()
  (make-topic
   :id "feed-required-discovery"
   :title "Feed-required discovery"
   :summary "Directories and aggregators that rely on RSS or Atom reward sites with explicit feeds while excluding otherwise valid small-web sites that publish without them."
   :references '("Small Web Search, Directories, and Discovery"
                 "Small Web Discovery and Aggregation"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun curation-boundaries-topic ()
  (make-topic
   :id "curation-boundaries"
   :title "Curation boundaries"
   :summary "Any curated small-web index expresses boundary choices about language, cadence, format, platform policy, and what counts as sufficiently personal or non-commercial."
   :references '("Small Web Search, Directories, and Discovery"
                 "Small Web topic arrangement"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun discovery-without-seo-topic ()
  (make-topic
   :id "discovery-without-seo"
   :title "Discovery without SEO"
   :summary "Small-web discovery tries to recover findability for sites that are public but do not optimize for platform ranking, social promotion, or search-engine gamesmanship."
   :references '("Small Web Search, Directories, and Discovery"
                 "Small Web and HyperDoc"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun blog-cadence-bias-topic ()
  (make-topic
   :id "blog-cadence-bias"
   :title "Blog cadence bias"
   :summary "Recency thresholds and posting-frequency filters often privilege frequently updated blogs while underrepresenting slower but still valuable personal sites."
   :references '("Small Web Search, Directories, and Discovery"
                 "Publishing Motives in the Small Web"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun gemini-topic ()
  (make-topic
   :id "gemini"
   :title "Gemini"
   :summary "Gemini is an intentionally constrained publishing protocol whose appeal comes from lower complexity, lower commercial pressure, and stronger textual focus than the mainstream web."
   :references '("Gemini, HTTP, and Protocol Minimalism"
                 "Small Web and HyperDoc"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun protocol-minimalism-topic ()
  (make-topic
   :id "protocol-minimalism"
   :title "Protocol minimalism"
   :summary "Protocol minimalism constrains affordances in order to preserve legibility, lower implementation burden, and reduce commercial escalation paths."
   :references '("Gemini, HTTP, and Protocol Minimalism"
                 "Small Web topic arrangement"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun browser-constrained-small-web-topic ()
  (make-topic
   :id "browser-constrained-small-web"
   :title "Browser-constrained small web"
   :summary "One line of small-web thought keeps ordinary browsers and HTTP but seeks social and technical limits that reduce tracking, bloat, and platform dependency."
   :references '("Small Web and HyperDoc"
                 "Gemini, HTTP, and Protocol Minimalism"
                 "https://kevinboone.me/small_web_is_big.html")))

(defun no-tracking-web-topic ()
  (make-topic
   :id "no-tracking-web"
   :title "No-tracking web"
   :summary "A no-tracking web narrows the problem from total simplicity to specific refusals such as third-party tracking, exploitative cookies, and surveillance-heavy adtech."
   :references '("Gemini, HTTP, and Protocol Minimalism"
                 "Publishing Motives in the Small Web"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun encryption-boundaries-on-the-small-web-topic ()
  (make-topic
   :id "encryption-boundaries-on-the-small-web"
   :title "Encryption boundaries on the small web"
   :summary "Debates over HTTP, HTTPS, Tor, and content signatures on the small web are boundary disputes about authenticity, privacy, reach, maintainability, and acceptable operational cost."
   :references '("Gemini, HTTP, and Protocol Minimalism"
                 "Small Web topic arrangement"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun small-web-monetization-topic ()
  (make-topic
   :id "small-web-monetization"
   :title "Small Web monetization"
   :summary "Small-web publishing does not have to exclude payment, but it resists monetization schemes that dominate attention, distort incentives, or subordinate publishing to advertising logic."
   :references '("Publishing Motives in the Small Web"
                 "Small Web and HyperDoc"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun intrinsic-publishing-motivation-topic ()
  (make-topic
   :id "intrinsic-publishing-motivation"
   :title "Intrinsic publishing motivation"
   :summary "A recurrent small-web claim is that people publish because they enjoy sharing, documenting, and making things, not only because publication can be monetized."
   :references '("Publishing Motives in the Small Web"
                 "Small Web and HyperDoc"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun discoverability-without-platforming-topic ()
  (make-topic
   :id "discoverability-without-platforming"
   :title "Discoverability without platforming"
   :summary "The hard problem is not merely publishing independently but making independent publication findable without collapsing back into centralized platform logic."
   :references '("Small Web Search, Directories, and Discovery"
                 "Publishing Motives in the Small Web"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun personal-site-neighborhoods-topic ()
  (make-topic
   :id "personal-site-neighborhoods"
   :title "Personal site neighborhoods"
   :summary "Blogrolls, 88x31 buttons, webrings, and hand-kept directories form neighborhood structures that support discovery through adjacency rather than global ranking alone."
   :references '("Small Web Search, Directories, and Discovery"
                 "Small Web topic arrangement"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun small-web-search-engines-topic ()
  (make-topic
   :id "small-web-search-engines"
   :title "Small Web search engines"
   :summary "Small-web search engines and search lenses prioritize independent sites, lower popularity bias, and deliberately different ranking signals than large commercial search systems."
   :references '("Small Web Search, Directories, and Discovery"
                 "Small Web and HyperDoc"
                 "https://news.ycombinator.com/item?id=47401879")))

(defun small-web-topic-arrangement-topic ()
  (make-topic
   :id "small-web-topic-arrangement"
   :title "Small Web topic arrangement"
   :summary "Arrangement page preserving the editorial neighborhood among small-web publishing, feeds, Gemini, search, monetization, protocol minimalism, and discovery structures without collapsing them into one doctrine."
   :references '("Small Web topic arrangement"
                 "Topic arrangement in HyperDoc"
                 "Small Web and HyperDoc")))
