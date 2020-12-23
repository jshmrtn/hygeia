import Chart from 'chart.js';
import 'chart.js/dist/Chart.min.css';
import pattern from 'patternomaly';

const colors = [
  '#01c5c4',
  '#47d0bc',
  '#6fdab4',
  '#92e3ac',
  '#b4eca7',
  '#d5f3a5',
  '#f6f9a7',
  '#f4dd87',
  '#f2c06d',
  '#efa15b',
  '#ea8251',
  '#e1614e',
  '#d43d51',
]

const backgrounds = pattern.generate([
  ...colors,
  ...colors,
]);

Chart.platform.disableCSSInjection = true;
Chart.defaults.global.legend.position = 'bottom';
Chart.defaults.global.responsive = true;
Chart.defaults.global.maintainAspectRatio = true;
Chart.defaults.global.aspectRatio = 4 / 3;

function addColorsToDataset({ data: { datasets, ...otherData }, ...config }) {
  return {
    data: {
      datasets: datasets.map((dataset, index) => ({
        backgroundColor: backgrounds[index % backgrounds.length],
        ...dataset
      })), ...otherData
    }, ...config
  };
}

export default {
  mounted() {
    const { id, ...config } = addColorsToDataset(JSON.parse(this.el.dataset.chart));
    this.chart = new Chart(id, config);
  },

  updated() {
    const { data } = addColorsToDataset(JSON.parse(this.el.dataset.chart));

    this.chart.data = data;
    this.chart.update();
  },

  beforeDestroy() {
    this.chart.destroy();
  }
}