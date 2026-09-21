import "@hotwired/turbo-rails";
import "controllers";
import * as bootstrap from "bootstrap";
import githubAutoCompleteElement from "@github/auto-complete-element";
import Blacklight from "blacklight";
import Geoblacklight from "geoblacklight";

// Keep framework imports available to application-specific JavaScript.
window.bootstrap = bootstrap;
window.Blacklight = Blacklight;
window.Geoblacklight = Geoblacklight;
