import Chart from 'chart.js';
import 'chart.js/dist/Chart.min.css';
import pattern from 'patternomaly';
import { seededShuffle } from './shuffle';

const baseColors = [
  '#37B8BF',
  '#5893A4',
  '#796F89',
  '#994A6D',
  '#BA2552',
  '#C6424A',
  '#D25F42',
  '#DE7B39',
  '#EA9831',
  '#C68B4D',
  '#A17E68',
  '#7D7084',
  '#58639F',
];

const colors = [
  ...baseColors,
  ...baseColors,
  ...baseColors,
  ...baseColors,
  ...baseColors,
  ...baseColors,
];

const visionImpairedBackgrounds = pattern.generate(colors);
const goodVisionBackgrounds = baseColors;

Chart.platform.disableCSSInjection = true;
Chart.defaults.global.legend.position = 'bottom';
Chart.defaults.global.responsive = true;
Chart.defaults.global.maintainAspectRatio = true;
Chart.defaults.global.aspectRatio = 4 / 3;

function prepareConfig(config) {
  config = addColorsToDataset(config);

  if (config.data.datasets.some(dataset => dataset.labels !== undefined)) {
    config = {
      ...config,
      options: {
        ...config.options,
        tooltips: {
          ...config.options.tooltips,
          callbacks: {
            label: function (tooltipItem, data) {
              var dataset = data.datasets[tooltipItem.datasetIndex];
              var index = tooltipItem.index;
              return dataset.labels[index] + ': ' + dataset.data[index];
            }
          }
        }
      }
    }
  }

  if (!config.data.labels) {
    config = { ...config, data: { ...config.data, labels: [] } }
  }

  return config;
}

function addColorsToDataset({ data: { datasets, ...otherData }, enableVisionImpairedMode = false, ...config }) {
  const backgrounds = enableVisionImpairedMode ? visionImpairedBackgrounds : goodVisionBackgrounds;
  return {
    data: {
      datasets: datasets.map((dataset, index) => ({
        backgroundColor: config.type == "doughnut"
          ? dataset.data.map((value, index) => backgrounds[index % backgrounds.length])
          : backgrounds[index % backgrounds.length],
        ...dataset
      })), ...otherData
    }, ...config
  };
}


export default {
  mounted() {
    const { id, data, ...config } = prepareConfig(JSON.parse(this.el.dataset.chart));

    this.chart = new Chart(id, { data, ...config });
  },

  updated() {
    const { data } = prepareConfig(JSON.parse(this.el.dataset.chart));

    this.chart.data = data;
    this.chart.update();
  },

  beforeDestroy() {
    this.chart.destroy();
  }
}