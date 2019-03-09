$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure you want to delete?");

    if (ok) {
      var form = $(this)

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      console.log(request)

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status == 204) {
          console.log("list item removed")
          form.parent("li").remove();
        } else if (jqXHR.status == 200) {
          console.log("inside redirect for deleted list")
          document.location = data;
        }
      });
    }
  });
});
