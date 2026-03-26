/*global GeoBlacklight */

(function() {
  if (!GeoBlacklight || !GeoBlacklight.Util || !GeoBlacklight.Util.indexMapTemplate) {
    return;
  }

  function websiteLinkLabel(data) {
    if (data && data.title) return "Open website for " + data.title;
    if (data && data.label) return "Open website for " + data.label;
    return "Open website";
  }

  function addIndexMapImageAccessibility(html, data) {
    var container = document.createElement("div");
    container.innerHTML = html;

    Array.prototype.forEach.call(container.querySelectorAll(".index-map-info img"), function(image) {
      image.setAttribute("alt", "");

      var link = image.closest("a");
      if (!link) return;

      if (!link.getAttribute("aria-label")) {
        link.setAttribute("aria-label", websiteLinkLabel(data));
      }
    });

    return container.innerHTML;
  }

  var originalIndexMapTemplate = GeoBlacklight.Util.indexMapTemplate;

  GeoBlacklight.Util.indexMapTemplate = function(data, cb) {
    return originalIndexMapTemplate.call(this, data, function(html) {
      cb(addIndexMapImageAccessibility(html, data));
    });
  };
}());
