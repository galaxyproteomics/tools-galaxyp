<!DOCTYPE html> <meta charset="utf-8">
<html>
<head lang="en">
    <meta name="viewport" content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=1"/>
    <title>Galaxy MVP Viewer</title>

    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/lorikeet.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/datatables.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/jquery-ui.min.css">
    <link rel="stylesheet" href="/plugins/visualizations/psmeviz/static/css/msi.css">

</head>
<body>

    <!-- MODAL -->
    <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header" style="text-align: center">
            Working ...
          </div>
        </div>
      </div>
    </div>
    <!-- END MODAL -->

    <!-- PEPTIDE MODAL -->
    <div class="modal fade" id="sequence_modal" tabindex="-1" role="dialog">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header" style="text-align: center">
                <h4 class="modal-title">Select Peptide Sequence(s) for Filtering Data</h4>
              </div>
              <div id="peptide_seq_list" class="modal-body"></div>
              <div class="modal-footer">
                      <button type="button" class="btn btn-default" data-dismiss="modal">Cancel</button>
                      <button id="seq_filter_btn" type="button" class="btn btn-primary">Add to Filter</button>
              </div>
            </div>
          </div>
     </div>
    <!-- END PEPTIDE MODAL-->

    <!-- NAVBAR -->
    <nav class="navbar navbar-fixed-top">
        <div class="container">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar"
                        aria-expanded="false" aria-controls="navbar">
                    <span class="sr-only">Toggle navigation</span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                    <span class="icon-bar"></span>
                </button>
                <a class="navbar-brand" href="#">MVP Viewer</a>
            </div>
            <div id="navbar" class="collapse navbar-collapse">
                <ul class="nav navbar-nav">
                    <li><a href="#about">About</a></li>
                </ul>
            </div>
            <!--/.nav-collapse -->
        </div>
    </nav>
    <!-- END NAVBAR -->

    <div class="container">
        <div class="row">
            <div class="col-sm-12">
                <h3 id="data_file_name"></h3>
            </div>
        </div>

        <!-- Module for GUI presentation of protein information.-->
        <div id="protein_gui"></div>

        <!-- Module for presenting table of peptides or proteins.-->
        <div class="row">
            <div id="overview_table"></div>
        </div>

        <!-- Filtering buttons -->
        <div class="well well-lg row lead">Filter by:
        <div class="btn-group" role="group">
          <button id="peptide_score" type="button" class="btn btn-default">Peptide Score</button>
          <button id="peptide_sequence" type="button" class="btn btn-default">Peptide Sequence</button>
          <button id="peptide_modification" type="button" class="btn btn-default">Modification</button>
          <button id="protein_acc" type="button" class="btn btn-default">Protein Accession</button>
        </div>
        </div>

        <!-- module for showing score spark lines and filtering -->
        <div class="row">
            <div class="well well-lg collapse" id="spark_lines">
                <div class="row" id="svg_elements"></div>
            </div>
        </div>

        <!-- Module for graphic filtering based on mod types -->
        <div class="row">
            <div class="well well-lg col-sm-12 collapse" id="gui_mods"></div>
        </div>

        <!-- Module for filtering peptide  data-->
        <div class="row">
            <div class="well well-lg col-sm-12 collapse" id="data_filter"></div>
        </div>

        <!-- Module for filtering based on protein information -->
        <div class="row">
            <div class="well well-lg col-sm-12 collapse" id="protein_filter">
                <button type="button" class="btn btn-default col-sm-2">Protein Accession</button>
                <input id="protein_accession" class="col-sm-2"><div class="col-sm-8" id="p_desc"></div>
            </div>
        </div>

        <!-- Module for showing selected PSMs -->
        <div class="row" id="detail_table"></div>

        <!-- Module for showng lorikeet -->
        <div class="row" id="lorikeet_panel">
            <h3 class="hidden" id="ms_title">MS/MSMS Spectra</h3>
        </div>

    </div>
    <!--close main container-->


    <script src="/plugins/visualizations/psmeviz/static/js/lib/datatables.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/buttons.html5.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery-ui.min.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/aminoacid.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/excanvas.min.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/ion.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.flot.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/jquery.flot.selection.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/peptide.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/internal.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/specview.js"></script>
    <script src="/plugins/visualizations/psmeviz/static/js/lib/d3.js"></script>

    <script src="/plugins/visualizations/psmeviz/static/js/mvpapplication.js"></script>

<script>
    $(document).ready(function () {
                var config = {

                    % if pageargs['saved_visualization']:
                            savedVizConfig: {
                            % for k in pageargs['config']['dataState']:
                                % if k == 'overviewData':
                                   overviewData: [
                                   % for obj in pageargs['config']['dataState']['overviewData']:
                                    {
                                        % for objKey in obj:
                                            '${objKey}': '${obj[objKey]}',
                                        % endfor
                                    },

                                   % endfor
                                   ],
                                % else:
                                    '${k}': '${pageargs['config']['dataState'][k]}',
                                % endif
                            % endfor
                            },
                    % endif
                    href: document.location.origin,
                    dataName: '${hda.name}',
                    tableNames: ['Proteins', 'Peptides'],
                    historyID: '${trans.security.encode_id( hda.history_id )}',
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

            MVPApplication.run(config);
    });
</script>


</body>
</html>
