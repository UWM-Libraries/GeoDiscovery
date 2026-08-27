import '@geoblacklight/frontend/dist/style.css'
import { OlInitializer } from '@geoblacklight/frontend'
import TileLayer from 'ol/layer/Tile'
import XYZ from 'ol/source/XYZ'

class CartoBasemapOlInitializer extends OlInitializer {
  baseLayer () {
    const apiKey = document.querySelector('meta[name="carto-basemap-api-key"]')

    if (this.data.basemap !== 'positron' || !apiKey) return super.baseLayer()

    return new TileLayer({
      source: new XYZ({
        attributions: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors, &copy; <a href="https://carto.com/attributions">CARTO</a>',
        url: 'https://{a-d}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png?key=' + encodeURIComponent(apiKey.content),
        maxZoom: 18
      })
    })
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new CartoBasemapOlInitializer().run()
})
