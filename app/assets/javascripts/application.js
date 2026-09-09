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

// @CUSTOMIZED
// - set initial bbox
// following was borrowed from BTAA with slight modifications

// Inherit upstream basemap selection, including LEAFLET.BASEMAPS settings.
GeoBlacklight.Viewer.Map = GeoBlacklight.Viewer.Map.extend({

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
  }
});
