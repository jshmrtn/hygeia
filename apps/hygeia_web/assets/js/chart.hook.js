import Highcharts from 'highcharts';
import 'highcharts/css/highcharts.css';

export default {
  mounted() {
    const {id, ...config} = JSON.parse(this.el.dataset.chart);     
    this.chart = Highcharts.chart(id, config);
  },
  
  updated() {
    const {series} = JSON.parse(this.el.dataset.chart);     
    
    this.chart.series.forEach((currentSeries) => currentSeries.setData(series.find(({name}) => currentSeries.name == name).data));
  }
}