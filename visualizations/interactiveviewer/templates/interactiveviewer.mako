<%
    default_title = "Interactive Viewer"
    info = hda.name
    if hda.info:
        info += ' : ' + hda.info
    root            = h.url_for( "/static/" )

    data =  hda.datatype.dataprovider(hda, 'base')
    app_root        = root + "plugins/visualizations/interactiveviewer/static"
    app_root = "static/js"
    hdadict = trans.security.encode_dict_ids( hda.to_dict() )
    import re
    re_img = re.compile(r"<img .*?>")
%>

<!DOCTYPE HTML>
<head>
    <style>
        #loading {
            border-top: 15px solid #EBD9B1;
            border-left: 15px solid #DAB870;
            border-right: 15px solid #DAB870;
            border-bottom: 15px solid #EBD9B1;
            border-radius: 50%;
            width: 120px;
            height: 120px;
            animation: spin 1s linear infinite;

            position:absolute;
            top: 50%;
            left: 50%;
            margin-left: -75px;
            margin-top: -75px;
        }

        #overlay {
            height: 100%;
            width: 100%;
            background-color: #f2f2f2;
            opacity: 0.4;
            position:absolute;
        }

        @-moz-keyframes spin {
            from { -moz-transform: rotate(0deg); }
            to { -moz-transform: rotate(360deg); }
        }
        @-webkit-keyframes spin {
            from { -webkit-transform: rotate(0deg); }
            to { -webkit-transform: rotate(360deg); }
        }
        @keyframes spin {
            from {transform:rotate(0deg);}
            to {transform:rotate(360deg);}
        }
    </style>
</head>
<html>
    <div id="overlay"><div id="loading"></div></div>
        %  for i, row in enumerate(data):
            % if 'script src' in row or 'link href' in row:
                % if 'Box_TE_all_rep_files' in row:
                    ${row.replace('Box_TE_all_rep_files', 'static/js')}
                % else:
                    ${row.replace('PE_TE_heatmap_files', 'static/js')}
                % endif
            % elif '.txt' in row:
                ${row.replace("href='", "href='/datasets/" + hdadict['id'] + "/display/").replace('href="', 'href="/datasets/' + hdadict['id'] + '/display/')}
            % else:
                ${re_img.sub("",row).replace('<!--', '').replace('-->','')}
            % endif
        % endfor
</html>

<script>
    window.onload = function(){
        $(document.getElementById('loading')).hide();
        $(document.getElementById('overlay')).hide();
    }
</script>