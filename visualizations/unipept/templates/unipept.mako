<%
    root = h.url_for( "/" )
    app_root = root + "plugins/visualizations/unipept/static/"
%>

<html>

  <head>
    <title>Treeview ${hda.name | h}</title>

    <!-- Jquery -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>

    <!-- D3 -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.6/d3.min.js"></script>

    <!-- Visualiations -->
    ${h.javascript_link( app_root + 'unipept-visualizations.es5.js' )}

    <script>
      $(function() {

        d3.json("${h.url_for( controller='/datasets', action='index')}/${trans.security.encode_id( hda.id )}/display", function(error, data) {
          if (error) return console.warn(error);

          $("#d3TreeView").treeview(data, {
            width: 1600,
            height: 1200,
            getTooltip: function(d) {
              let numberFormat = d3.format(",d");
              return "<b>" + d.name + "</b> (" + d.data.rank + ")<br/>" + numberFormat(!d.data.self_count ? "0" : d.data.self_count) + (d.data.self_count && d.data.self_count === 1 ? " sequence" : " sequences") +
                " specific to this level<br/>" + numberFormat(!d.data.count ? "0" : d.data.count) + (d.data.count && d.data.count === 1 ? " sequence" : " sequences") + " specific to this level or lower";
            }
          });
        });
      });

    </script>
  </head>

  <body>
    <div id="d3TreeView"></div>
  </body>

</html>
