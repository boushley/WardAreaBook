function go_to_was_family_visited(category) {
  var month = jQuery('#was-visited-report-month-select').val(), year = jQuery('#was-visited-report-year-select').val();
  window.location = '/reports/was_visited/' + category + '/' + year + '/' + month;
}
