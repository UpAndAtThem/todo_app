$(function() {

  $("form.delete").submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure you want to delete?");

    if (ok) {
      // this.submit();

      var form = $(this)

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method")
      });

      request.done(function(data, textStatus, jqXHR) {
        form.parent("li").remove()
      });
    }
  });
});
