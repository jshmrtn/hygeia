function supportsDateInput() {
  var input = document.createElement('input');
  input.setAttribute('type', 'date');
  input.value = '2018-01-01';
  return !!input.valueAsDate;
}

function supportsDatetimeLocalInput() {
  var input = document.createElement('input');
  input.setAttribute('type', 'datetime-local');
  input.value = '2018-01-01T00:00:00';
  return !!input.valueAsNumber;
}

export default {
  date_input: supportsDateInput(),
  datetime_local_input: supportsDatetimeLocalInput(),
};