<!DOCTYPE html>
<html>
<head lang="en">
    <meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1"/>
    <title>Galaxy SQLite Data Viewer</title>

    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery-ui.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/lorikeet.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/dataTables.colReorder.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/dataTables.colVis.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery.dataTables.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/unsemantic-grid-responsive-no-ie7.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/msi.css">

</head>
<body>

    <div class="grid-container" >
        <h1 id="mainTitle" class="grid-33 prefix-33 suffix-33">PSM Viewer</h1>
        <h3 class="grid-25 suffix-75">Available Tables:
            <select id="availableTables">
            </select> <!-- Filled in on start up -->
        </h3>

        <div id="overviewGrid" class="display grid-100 grid-parent" > <!-- style="background-color: #aaaaaa" -->
            <div id="overviewTitle" class="grid-100 align-center"></div>
            <div id="overviewDataTable" class="grid-100" >&nbsp;</div> <!-- style="background-color: #d7ebf9" -->
            <div class="grid-80 suffix-20"></div>
            <div id="overviewDataTableFilters" class="grid-100" >&nbsp;</div> <!-- style="background-color: #d7ebf9" -->
        </div>

        <div>&nbsp;</div>

        <div id="psmGrid" class="display grid-100 grid-parent"> <!--  style="background-color: #aaaaaa" -->
            <div id="psmTitle" class="grid-100 align-center"></div>
            <div id="psmDataTable" class="grid-100" >&nbsp;</div> <!-- style="background-color: #d7ebf9" -->
            <div id="psmScoreFilters" class="grid-80 suffix-20"></div>
            <div id="psmDataTableFilters" class="grid-100" >&nbsp;</div> <!-- style="background-color: #d7ebf9" -->
            &nbsp;</div> <!-- FOR TESTING -->

        <div>&nbsp;</div>

        <div class="grid-100">
            <div id="lorikeetData" class="grid-100">
                <div id="tabs" class="grid-100"> <!--  style="background-color: rgba(100, 140, 170, 0.58)" -->
                    <ul></ul>
                </div>
            </div>
        </div>

    </div>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery-ui.js"></script>

    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.dataTables.min.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/dataTables.colReorder.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/dataTables.colVis.min.js"></script>

    <script src="/plugins/visualizations/psmeviz/static/js/application.min.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/aminoacid.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/excanvas.min.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/internal.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/ion.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.flot.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.flot.selection.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/peptide.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/specview.js"></script>

<script>
    $(document).ready(function () {
                var config = {
                    dataGridElement: 'data_table',
                    href: document.location.origin,
                    dataName: '${hda.name}',
                    isPSM: true,
                    historyID: '${trans.security.encode_id( hda.history_id )}',
                    pageTitle: 'PSM Viewer',
                    datasetID: '${trans.security.encode_id( hda.id )}',
                    tableRowCount: {
                        % for table in hda.metadata.table_row_count:
                            '${table}': ${hda.metadata.table_row_count[table]} ,
                        % endfor
                    },
                    tableColumns: {
                        % for k in hda.metadata.table_columns:
                            '${k}': [
                                % for v in hda.metadata.table_columns[k]:
                                    '${v}',
                                % endfor
                            ],
                        % endfor
                    }
                };

            SQLDataViewer.produceVisualization(config);
    });
</script>


</body>
</html>
