<!DOCTYPE html>
<html>
<head lang="en">
    <meta charset="UTF-8">
    <title>Galaxy Peptide Spectral Matching</title>

    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/dataTables.colReorder.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/dataTables.colVis.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery.dataTables.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/lorikeet.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/pviz-core.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/loader.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery-ui.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery-ui.theme.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery-ui.theme.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/unsemantic-grid-responsive-no-ie7.css">

</head>
<body>

<div class="grid-container">

    <h3 class="grid-100">PSM Table: <select id="dataView">
        <option value="psm">PSM View</option>
        <option value="protein">Protein View</option>
        <option value="peptide">Peptide View</option>
    </select></h3>

    <div id="spinHere" class="grid-100"></div>

    <div class="grid-10">
        <button id="toggleProtPepGrid">Hide</button>
    </div>

    <div id="protPepGrid" class="grid-100"></div>

    <div class="clear"></div>

    <div class="grid-10">
        <button id="toggleDataGrid">Hide</button>
    </div>

    <div id="dataGrid" class="grid-100"></div>

    <div class="clear"></div>
    <div class="grid-90">
        <div>
            <!--<div><button id="reset">Reset to original column order</button></div>-->
            <p>Page<input type="text" id="page_x" readonly style="border:0; color:#f6931f; font-weight:bold;">
                of
                <input type="text" id="page_y" readonly style="border:0; color:#f6931f; font-weight:bold;">Showing
                records
                <input type="text" id="record_x" readonly style="border:0; color:#f6931f; font-weight:bold;"> of
                <input type="text" id="record_y" readonly style="border:0; color:#f6931f; font-weight:bold;"> total
                records.

            <div id="pageSlider"></div>
        </div>
    </div>


    <div class="grid-100">
        <div id="lorikeetData" class="grid-100">
            <div id="tabs" class="grid-100">
                <ul></ul>
            </div>
        </div>
    </div>
</div>

<script src="/plugins/visualizations/psmeviz/static/js/lib/pviz-bundle.min.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/underscore.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/backbone.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/jquery-ui.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.dataTables.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/dataTables.colReorder.min.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/dataTables.colVis.min.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/aminoacid.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/excanvas.min.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/ion.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/internal.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/jquery.flot.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/jquery.flot.selection.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/peptide.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/lorikeet/specview.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/lib/spin.js"></script>
<!-- *************************************** -->
<script src="/plugins/visualizations/psmeviz/static/js/modules/dataModule.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/modules/dataTableUtilities.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/modules/guiUtilities.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/modules/proteinCoverageModule.js"></script>
<script src="/plugins/visualizations/psmeviz/static/js/testApp.js"></script>


<script>
    $(document).ready(function () {
                var config = {
                    dataGridElement: 'dataGrid',
                    href: document.location.origin,
                    dataName: '${hda.name}',
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

            SQLDataTypeViewer.produceVisualization(config);
    });
</script>


</body>
</html>
