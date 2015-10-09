<!DOCTYPE html>
<html>
<head lang="en">
    <meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1"/>
    <title>Galaxy SQLite Data Viewer</title>

  <link rel="stylesheet" href="/plugins/visualizations/sqlviewer/static/css/dataTables.colReorder.min.css">
  <link rel="stylesheet" href="/plugins/visualizations/sqlviewer/static/css/dataTables.colVis.min.css">
  <link rel="stylesheet" href="/plugins/visualizations/sqlviewer/static/css/jquery-ui.min.css">
  <link rel="stylesheet" href="/plugins/visualizations/sqlviewer/static/css/jquery.dataTables.min.css">
  <link rel="stylesheet" href="/plugins/visualizations/sqlviewer/static/css/msi.css">
  <link rel="stylesheet" href="/plugins/visualizations/sqlviewer/static/css/unsemantic-grid-responsive-no-ie7.css">

</head>
<body>

    <div class="grid-container">
        <h3 id="mainTitle" class="grid-33 prefix-33 suffix-33">FOOO SQLite Data Type Viewer</h3>
        <h3 class="grid-50 prefix-50">Available Tables:
            <select id="availableTables">
                <option value="NA">No Table Choosen</option>
            </select> <!-- Filled in on start up -->
        </h3>

        <button id="copyData" class="grid-10">Copy Data</button>
        <div id="dataGrid" class="display grid-100"></div>

        <h3 class="grid-100" style="text-align: center">Custom SQL Queries</h3>
        <div class=" grid-20 grid-parent">
            <div id="tableSchema" class="tblScheme">Tables and Columns</div>
        </div>

        <div class="grid-80 grid-parent">
            <textarea id="sqlText" name="textarea" rows="10" placeholder="Enter custom SQL here." class="grid-90 suffix-10"></textarea>
            <button id="fireSQL" class="grid-10">Query!</button>
            <button id="saveSQL" class="grid-10">Save Query</button>
            <button id="clearSQL" class="grid-10 suffix-70">Clear Query</button>
        </div>
      </div>

        <div class="clear"></div>

        <div class="grid-100 grid-parent">
          <div id="trash" class="grid-20">&nbsp;</div>
        <div class="grid-80">
          <h3 id="savedQueries" style="cursor: pointer">Saved SQL Queries</h3>
          <div id="sqlContent" class="grid-90 suffix-10" style="border:1px solid #d3d3d3;">
            <ul id="queryList"></ul>
          </div>
        </div>
      </div>

    <script src="/plugins/visualizations/sqlviewer/static/js/lib/jquery-2.1.4.min.js"></script>
    <script src="/plugins/visualizations/sqlviewer/static/js/lib/jquery-ui.min.js"></script>
    <script src="/plugins/visualizations/sqlviewer/static/js/lib/dataTables.colReorder.min.js"></script>
    <script src="/plugins/visualizations/sqlviewer/static/js/lib/dataTables.colVis.min.js"></script>
    <script src="/plugins/visualizations/sqlviewer/static/js/lib/jquery.dataTables.min.js"></script>
    <script src="/plugins/visualizations/sqlviewer/static/js/application.min.js"></script>


    <script>
$(document).ready(function () {
                var config = {
                    dataGridElement: 'data_table',
                    href: document.location.origin,
                    dataName: '${hda.name}',
                    isPSM: true,
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
