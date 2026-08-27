//= require jquery3
//= require rails-ujs
//
// Required by Blacklight
//= require popper
// Twitter Typeahead for autocomplete
//= require twitter/typeahead
//= require bootstrap
//= require blacklight/blacklight

    // Required by Blacklight::Allmaps
    //= require blacklight-allmaps/app/assets/javascripts/blacklight/allmaps/blacklight-allmaps.js

// Required by GeoBlacklight
//= require geoblacklight

// UWM
//= require uwm

// CARTO requires an API key for its hosted basemaps. The key is supplied by
// the server's CARTO_BASEMAP_API_KEY environment variable via the page layout.
var cartoBasemapApiKey = document.querySelector('meta[name="carto-basemap-api-key"]');

if (cartoBasemapApiKey) {
  GeoBlacklight.Basemaps.positron = L.tileLayer(
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{retina}.png?key=' +
      encodeURIComponent(cartoBasemapApiKey.content), {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="https://carto.com/attributions">CARTO</a>',
      maxZoom: 18,
      worldCopyJump: true,
      retina: '@2x',
      detectRetina: false
    }
  );
}

// @CUSTOMIZED
// - set initial bbox
// following was borrowed from BTAA with slight modifications

GeoBlacklight.Viewer.Map = GeoBlacklight.Viewer.extend({

  options: {
    /**
    * Initial bounds of map
    * @type {L.LatLngBounds}
    */
    bbox: [[42.75, -87.75], [43.3, -88.45]],
    opacity: 1.0
  },

  overlay: L.layerGroup(),

  load: function() {
    if (this.data.mapGeom) {
      this.options.bbox = L.geoJSONToBounds(this.data.mapGeom);
    }
    
    this.map = L.map(this.element, {scrollWheelZoom:true, noWrap: true}).fitBounds(this.options.bbox);
    this.map.addLayer(this.selectBasemap());
    this.map.addLayer(this.overlay);
    if (this.data.map !== 'index') {
      this.addBoundsOverlay(this.options.bbox);
    }
  },

  /**
   * Add a bounding box overlay to map.
   * @param {L.LatLngBounds} bounds Leaflet LatLngBounds
   */
  addBoundsOverlay: function(bounds) {
    if (bounds instanceof L.LatLngBounds) {
      this.overlay.addLayer(L.polygon([
        bounds.getSouthWest(),
        bounds.getSouthEast(),
        bounds.getNorthEast(),
        bounds.getNorthWest()
      ]));
    }
  },

  /**
   * Remove bounding box overlay from map.
   */
  removeBoundsOverlay: function() {
    this.overlay.clearLayers();
  },

  /**
   * Add a GeoJSON overlay to map.
   * @param {string} geojson GeoJSON string
   */
  addGeoJsonOverlay: function(geojson) {
    var layer = L.geoJSON();
    layer.addData(geojson);
    this.overlay.addLayer(layer);
  },

  /**
  * Selects basemap if specified in data options, if not return mapquest
  */
  selectBasemap: function() {
    var _this = this;
    if (_this.data.basemap) {
      return GeoBlacklight.Basemaps[_this.data.basemap];
    } else {
      return _this.basemap.mapquest;
    }
  }
});
