function subst() {
  var vars = {};
  var query_strings_from_url = document.location.search.substring(1).split('&');
  for (var query_string in query_strings_from_url) {
      if (query_strings_from_url.hasOwnProperty(query_string)) {
          var temp_var = query_strings_from_url[query_string].split('=', 2);
          vars[temp_var[0]] = decodeURI(temp_var[1]);
      }
  }
  var css_selector_classes = ['page', 'frompage', 'topage', 'webpage', 'section', 'subsection', 'date', 'isodate', 'time', 'title', 'doctitle', 'sitepage', 'sitepages'];
  for (var css_class in css_selector_classes) {
      if (css_selector_classes.hasOwnProperty(css_class)) {
          var element = document.getElementsByClassName(css_selector_classes[css_class]);
          for (var j = 0; j < element.length; ++j) {
              element[j].textContent = vars[css_selector_classes[css_class]];
          }
      }
  }
}

// show certain elements only on the first page (https://stackoverflow.com/a/11950452)
var vars = {};
var x = document.location.search.substring(1).split('&');
for (var i in x) {
  var z = x[i].split('=', 2);
  vars[z[0]] = unescape(z[1]);
}
if(vars['page'] != 1){
  var page1Headers = document.getElementsByClassName("page-1-header");
  for (var e in page1Headers) {
    page1Headers[e].style.display = 'none';
  }
}