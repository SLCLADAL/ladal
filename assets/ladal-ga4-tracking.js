/**
 * ============================================================
 *  LADAL GA4 Enhanced Tracking Script
 *  Property: SLCLADAL-G4  |  Measurement ID: G-313828151
 *  Last updated: March 2026
 *
 *  Covers:
 *    - Tool launch clicks (Shiny + Jupyter, all 3 platforms)
 *    - Tutorial page scroll depth (50% and 90%)
 *    - Tutorial individual page identity (category + name)
 *    - Outbound "Learn more" link clicks from tool cards
 *    - Tutorial → Tool funnel clicks
 *
 *  HOW TO DEPLOY:
 *    Add this <script> tag to every page, AFTER your existing
 *    gtag.js snippet (the one that loads GA4):
 *
 *    <script src="/js/ladal-ga4-tracking.js"></script>
 *
 *  Or paste the contents inline in a <script> block.
 * ============================================================
 */

(function () {
  'use strict';

  // ----------------------------------------------------------
  // 1. TOOL MAPS
  //    Maps the notebook/launcher filename found in the URL
  //    to a human-readable tool name and tool type.
  // ----------------------------------------------------------

  /**
   * Shiny tools — launched via ARDC BinderHub (tools-env repo)
   * URL pattern: binderhub.rc.nectar.org.au/...tools-env...voila/render/tools/<key>_launcher.ipynb
   */
  var SHINY_TOOLS = {
    'filerenamer':            'FileRenamer',
    'textcleaner':            'TextCleaner',
    'postagger':              'POSTagger',
    'wordfinder':             'WordFinder',
    'keywordextractor':       'KeywordExtractor',
    'wordwebber':             'WordWebber',
    'sentimentexplorer':      'SentimentExplorer',
    'collocationcalculator':  'CollocationCalculator',
    'topicdetector':          'TopicDetector'
  };

  /**
   * Jupyter Notebook tools — launched via MyBinder or GESIS (jupyter-env repo)
   * URL pattern: mybinder.org/...jupyter-env...notebooks/<key>.ipynb
   *           or notebooks.gesis.org/...jupyter-env...notebooks/<key>.ipynb
   */
  var JUPYTER_TOOLS = {
    'concordance_explorer':   'Concordance Explorer',
    'text_cleaner':           'Text Cleaner',
    'pos_tagger':             'Part-of-Speech Tagger',
    'collocation_analyser':   'Collocation Analyser',
    'keyword_finder':         'Keyword Finder',
    'network_visualiser':     'Network Visualiser',
    'topic_explorer':         'Topic Explorer',
    'sentiment_explorer':     'Sentiment Explorer'
  };


  // ----------------------------------------------------------
  // 2. HELPER: resolve tool name, type, and launcher from URL
  // ----------------------------------------------------------

  function resolveToolLaunch(href) {
    var decoded = decodeURIComponent(href);

    // --- Shiny tool via ARDC BinderHub ---
    if (decoded.indexOf('binderhub.rc.nectar.org.au') !== -1 &&
        decoded.indexOf('tools-env') !== -1) {

      // Extract the launcher filename, e.g. "wordfinder_launcher.ipynb"
      var shinyMatch = decoded.match(/voila\/render\/tools\/([a-z0-9_]+)_launcher\.ipynb/i);
      var shinyKey   = shinyMatch ? shinyMatch[1].toLowerCase() : null;
      var shinyName  = shinyKey ? (SHINY_TOOLS[shinyKey] || shinyKey) : 'Unknown Shiny Tool';

      return {
        tool_name:    shinyName,
        tool_type:    'shiny',
        launcher:     'ARDC BinderHub'
      };
    }

    // --- Jupyter tool via MyBinder ---
    if (decoded.indexOf('mybinder.org') !== -1 &&
        decoded.indexOf('jupyter-env') !== -1) {

      var myMatch  = decoded.match(/notebooks\/([a-z0-9_]+)\.ipynb/i);
      var myKey    = myMatch ? myMatch[1].toLowerCase() : null;
      var myName   = myKey ? (JUPYTER_TOOLS[myKey] || myKey) : 'Unknown Jupyter Tool';

      return {
        tool_name:    myName,
        tool_type:    'jupyter',
        launcher:     'MyBinder'
      };
    }

    // --- Jupyter tool via GESIS BinderHub ---
    if (decoded.indexOf('notebooks.gesis.org') !== -1 &&
        decoded.indexOf('jupyter-env') !== -1) {

      var gesisMatch = decoded.match(/notebooks\/([a-z0-9_]+)\.ipynb/i);
      var gesisKey   = gesisMatch ? gesisMatch[1].toLowerCase() : null;
      var gesisName  = gesisKey ? (JUPYTER_TOOLS[gesisKey] || gesisKey) : 'Unknown Jupyter Tool';

      return {
        tool_name:    gesisName,
        tool_type:    'jupyter',
        launcher:     'GESIS BinderHub'
      };
    }

    return null; // not a tool launch link
  }


  // ----------------------------------------------------------
  // 3. TOOL LAUNCH CLICK TRACKING
  //    Fires: tool_launch
  //    Parameters: tool_name, tool_type, launcher, page_location
  // ----------------------------------------------------------

  function initToolLaunchTracking() {
    // Match all three launcher button types
    var selector = [
      'a.card-btn.ardc',
      'a.card-btn.mybinder',
      'a.card-btn.gesis'
    ].join(', ');

    var buttons = document.querySelectorAll(selector);

    buttons.forEach(function (btn) {
      btn.addEventListener('click', function () {
        var info = resolveToolLaunch(btn.href);
        if (!info) return;

        if (typeof gtag === 'function') {
          gtag('event', 'tool_launch', {
            tool_name:     info.tool_name,
            tool_type:     info.tool_type,
            launcher:      info.launcher,
            page_location: window.location.href
          });
        }
      });
    });
  }


  // ----------------------------------------------------------
  // 4. TUTORIAL PAGE TRACKING
  //    Detects tutorial pages by URL pattern:
  //      /tutorials/<category>/<name>.html
  //    Fires: tutorial_view  (on load)
  //    Fires: tutorial_scroll (at 50% and 90%)
  // ----------------------------------------------------------

  function getTutorialInfo() {
    var path  = window.location.pathname;
    // Matches /tutorials/sem/sem.html or /tutorials/mixedmodel/mixedmodel.html etc.
    var match = path.match(/\/tutorials\/([^/]+)\/([^/]+)\.html/);
    if (match) {
      return {
        tutorial_category: match[1],   // e.g. "sem", "mixedmodel", "kwics"
        tutorial_name:     match[2]    // e.g. "sem", "mixedmodel", "kwics"
      };
    }
    return null;
  }

  function initTutorialTracking() {
    var info = getTutorialInfo();
    if (!info) return;

    // 4a. Fire tutorial_view on page load
    if (typeof gtag === 'function') {
      gtag('event', 'tutorial_view', {
        tutorial_category: info.tutorial_category,
        tutorial_name:     info.tutorial_name,
        page_location:     window.location.href
      });
    }

    // 4b. Scroll depth — fire at 50% and 90%
    var fired50 = false;
    var fired90 = false;

    function onScroll() {
      var scrolled  = window.scrollY || window.pageYOffset;
      var docHeight = document.documentElement.scrollHeight - window.innerHeight;
      if (docHeight <= 0) return;

      var pct = (scrolled / docHeight) * 100;

      if (!fired50 && pct >= 50) {
        fired50 = true;
        if (typeof gtag === 'function') {
          gtag('event', 'tutorial_scroll', {
            tutorial_category: info.tutorial_category,
            tutorial_name:     info.tutorial_name,
            scroll_milestone:  '50_percent'
          });
        }
      }

      if (!fired90 && pct >= 90) {
        fired90 = true;
        if (typeof gtag === 'function') {
          gtag('event', 'tutorial_scroll', {
            tutorial_category: info.tutorial_category,
            tutorial_name:     info.tutorial_name,
            scroll_milestone:  '90_percent'
          });
        }
        // No more scroll events needed once 90% fired
        window.removeEventListener('scroll', onScroll);
      }
    }

    window.addEventListener('scroll', onScroll, { passive: true });
  }


  // ----------------------------------------------------------
  // 5. "LEARN MORE" LINK CLICKS FROM TOOL CARDS
  //    Fires: tool_tutorial_click
  //    Parameters: tool_name, tool_type, destination
  //    Tells you which tutorial users read after browsing tools
  // ----------------------------------------------------------

  function initToolLearnMoreTracking() {
    var learnLinks = document.querySelectorAll('a.tool-learn-link');

    learnLinks.forEach(function (link) {
      link.addEventListener('click', function () {
        // Try to find the nearest tool card and read its h3 for the name
        var card = link.closest('.tool-card');
        var toolNameEl = card ? card.querySelector('.tool-card-header-text h3') : null;
        var toolName   = toolNameEl ? toolNameEl.textContent.trim() : 'Unknown Tool';

        // Determine tool type from card class on the header
        var header   = card ? card.querySelector('.tool-card-header') : null;
        var isJupyter = header ? !header.classList.contains('h1') &&
                                  !header.classList.contains('h2') &&
                                  !header.classList.contains('h3') &&
                                  !header.classList.contains('h4') &&
                                  !header.classList.contains('h5') &&
                                  !header.classList.contains('h6') &&
                                  !header.classList.contains('h7') &&
                                  !header.classList.contains('h8') &&
                                  !header.classList.contains('h9') &&
                                   header.classList.contains('jn')
                               : false;

        if (typeof gtag === 'function') {
          gtag('event', 'tool_tutorial_click', {
            tool_name:   toolName,
            tool_type:   isJupyter ? 'jupyter' : 'shiny',
            destination: link.href
          });
        }
      });
    });
  }


  // ----------------------------------------------------------
  // 6. TUTORIAL → TOOL PAGE FUNNEL
  //    On tutorial pages, track clicks on links leading to
  //    /tools.html so you can measure the tutorial→tool journey.
  //    Fires: tutorial_to_tools_click
  // ----------------------------------------------------------

  function initTutorialToToolsTracking() {
    var info = getTutorialInfo();
    if (!info) return; // only on tutorial pages

    document.querySelectorAll('a[href*="/tools"]').forEach(function (link) {
      link.addEventListener('click', function () {
        if (typeof gtag === 'function') {
          gtag('event', 'tutorial_to_tools_click', {
            tutorial_category: info.tutorial_category,
            tutorial_name:     info.tutorial_name,
            destination:       link.href
          });
        }
      });
    });
  }


  // ----------------------------------------------------------
  // 7. INIT — run everything on DOMContentLoaded
  // ----------------------------------------------------------

  function init() {
    initToolLaunchTracking();
    initTutorialTracking();
    initToolLearnMoreTracking();
    initTutorialToToolsTracking();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    // DOM already ready (e.g. script loaded async)
    init();
  }

})();


/* ============================================================
   GA4 SETUP CHECKLIST (do these once in the GA4 Admin UI)
   ============================================================

   1. KEY EVENT (Conversion)
      Admin → Key events → Create key event
      Event name: tool_launch
      → This is your primary conversion metric.

   2. CUSTOM DIMENSIONS
      Admin → Custom definitions → Create custom dimension

      Dimension name        | Scope  | Event parameter
      ─────────────────────────────────────────────────
      Tool Name             | Event  | tool_name
      Tool Type             | Event  | tool_type
      Launcher              | Event  | launcher
      Tutorial Category     | Event  | tutorial_category
      Tutorial Name         | Event  | tutorial_name
      Scroll Milestone      | Event  | scroll_milestone

   3. DATA RETENTION
      Admin → Data settings → Data retention
      Set to: 14 months  (default is only 2)

   4. UNWANTED REFERRALS
      Admin → Data streams → your stream → Configure tag
        → Unwanted referrals → Add:
          binderhub.rc.nectar.org.au
          mybinder.org
          notebooks.gesis.org
      (Prevents these platforms appearing as traffic sources
       if users navigate back to LADAL after launching a tool.)

   5. INTERNAL TRAFFIC FILTER
      Admin → Data filters → Create filter → Internal traffic
      Add your UQ office IP range(s) so staff visits don't
      inflate your usage stats.

   6. GOOGLE SEARCH CONSOLE LINK
      Admin → Product links → Search Console
      Links keyword/query data into your GA4 reports.

   ============================================================
   EVENTS THIS SCRIPT FIRES
   ============================================================

   tool_launch
     tool_name       e.g. "WordFinder", "Concordance Explorer"
     tool_type       "shiny" or "jupyter"
     launcher        "ARDC BinderHub", "MyBinder", "GESIS BinderHub"
     page_location   full URL of the page the click happened on

   tutorial_view
     tutorial_category  e.g. "sem", "mixedmodel", "kwics"
     tutorial_name      e.g. "sem", "mixedmodel", "kwics"
     page_location      full URL

   tutorial_scroll
     tutorial_category  as above
     tutorial_name      as above
     scroll_milestone   "50_percent" or "90_percent"

   tool_tutorial_click
     tool_name     name of the tool whose "Learn more" was clicked
     tool_type     "shiny" or "jupyter"
     destination   URL of the tutorial

   tutorial_to_tools_click
     tutorial_category  as above
     tutorial_name      as above
     destination        URL clicked (tools page link)

   ============================================================
   SUGGESTED EXPLORATIONS TO BUILD IN GA4
   ============================================================

   A. Tool Popularity Report
      Technique: Free-form exploration
      Dimensions: tool_name, tool_type, launcher
      Metrics:    eventCount
      Filter:     event_name = tool_launch
      → Answers: Which tools are most used? ARDC vs MyBinder vs GESIS?

   B. Tutorial Engagement Report
      Technique: Free-form exploration
      Dimensions: tutorial_category, tutorial_name, scroll_milestone
      Metrics:    eventCount
      Filter:     event_name = tutorial_scroll
      → Answers: Which tutorials do people actually read to completion?

   C. Tutorial → Tool Funnel
      Technique: Funnel exploration
      Step 1: tutorial_view
      Step 2: tutorial_to_tools_click
      Step 3: tool_launch
      → Answers: How many tutorial readers go on to use a tool?

   D. Shiny vs Jupyter Usage Split
      Technique: Free-form exploration
      Dimension: tool_type
      Metric:    eventCount
      Filter:    event_name = tool_launch
      → Answers: Are AU/NZ users (Shiny) vs global users (Jupyter)
                 using different tools?

   ============================================================
*/
