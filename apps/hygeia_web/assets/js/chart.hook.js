import {
  ArcElement,
  CategoryScale,
  Chart,
  DoughnutController,
  Filler,
  Legend,
  LineController,
  LineElement,
  LinearScale,
  PointElement,
  TimeScale,
  Title,
  Tooltip
} from 'chart.js';
import 'chartjs-adapter-date-fns';
import pattern from 'patternomaly';

Chart.register(
  ArcElement,
  CategoryScale,
  DoughnutController,
  Filler,
  Legend,
  LineController,
  LineElement,
  LinearScale,
  PointElement,
  TimeScale,
  Title,
  Tooltip
);

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

Chart.defaults.plugins.legend.position = 'bottom';
Chart.defaults.responsive = true;
Chart.defaults.maintainAspectRatio = true;
Chart.defaults.aspectRatio = 4 / 3;

function prepareConfig(config) {
  config = addColorsToDataset(config);

  if (config.data.datasets.some(dataset => dataset.labels !== undefined)) {
    config = {
      ...config,
      options: {
        ...config.options,
        plugins: {
          ...config.options.plugins,
          tooltip: {
            ...config.options.plugins.tooltip,
            callbacks: {
              label: function ({ dataset: { labels: labels }, dataIndex: index, formattedValue }) {
                return labels[index] + ': ' + formattedValue;
              }
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