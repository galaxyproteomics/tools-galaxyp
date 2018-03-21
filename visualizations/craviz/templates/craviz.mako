<%
    default_title = "Cancer-Related Analysis of Variants Toolkit"
    info = hda.name
    if hda.info:
        info += ' : ' + hda.info

    # optionally bootstrap data from dprov
    #data = list( hda.datatype.dataset_column_dataprovider( hda, limit=20 ) )

    root            = h.url_for( "/" )
    app_root        = root + "plugins/visualizations/craviz/static/js"
    repository_root = root + "plugins/visualizations/craviz/static/"
%>


<!DOCTYPE HTML>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <title>${hda.name | h} | ${visualization_name}</title>

        ${h.js( 'libs/jquery/jquery',
                'libs/jquery/jquery-ui')}

        <link rel="stylesheet" type="text/css" href="${repository_root}/css/datatables.css"/>
        <script type="text/javascript" src="${app_root}/lib/datatables.js"></script>


        ${h.js( 'libs/jquery/select2',
                'libs/bootstrap',
                'libs/underscore',
                'libs/backbone',
                'libs/d3',
                'libs/require')}
        ${h.css( 'base', 'jquery-ui/smoothness/jquery-ui' )}
        ${h.stylesheet_link( repository_root + "/css/style.css" )}
        ${h.stylesheet_link( repository_root + "/css/datatables.min.css" )}



    </head>
    <body>
        <div id="container">

            <div class="chart-header">
                <h2>${title or default_title}</h2>
            </div>



        </div>

        <script type="text/javascript">
            var app_root = '${app_root}';
            var repository_root = '${repository_root}';
            var Galaxy = Galaxy || parent.Galaxy || {
                root    : '${root}',
                emit    : {
                    debug: function() {}
                }
            };
            window.console = window.console || {
                log     : function(){},
                debug   : function(){},
                info    : function(){},
                warn    : function(){},
                error   : function(){},
                assert  : function(){}
            };
            require.config({
                baseUrl: Galaxy.root + "static/scripts/",
                paths: {
                    "plugin"        : "${app_root}",
                    "d3"            : "libs/d3",
                    "repository"    : "${repository_root}"
                },
                shim: {
                    "libs/underscore": { exports: "_" },
                    "libs/backbone": { exports: "Backbone" },
                    "d3": { exports: "d3" }
                }
            });


            $(function() {
                require( [ 'plugin/app' ], function( App ) {
                    var config = ${ h.dumps( config ) };
                    var app = new App({
                        dataset_id  : config.dataset_id});;
                    $('body').append(app.$el);
                    $('body').append(app.footer);
                });
            });
        </script>
    </body>
</html>