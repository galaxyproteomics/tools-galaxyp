/**
 * The view controller.
 */
var BuildDataTable = (function (bdt) {

    bdt.hoverDelay;
    bdt.coverageIndicator;

    /**
     * {
     *  'tableName': 'A table's Name',
     *  'dataValues': ajax results from Galaxy data provider query,
     *  'elementID': DOM element to place the data table within,
     *  'tableID': element ID for the table
     * }
     */
    bdt.renderTable = function (configObj) {
        bdt.divElement = '#' + configObj.elementID;
        $(bdt.divElement).html('<table cellpadding="0" cellspacing="0" border="0" class="display" id=' + configObj.tableName + '></table>');
        bdt.table = $('#' + configObj.tableName).DataTable({
            data: configObj.dataValues.rows,
            columns: configObj.dataValues.columns,
            paging: false,
            lengthChange: false,
            info: false,
            dom : 'C<"clear">Rlfrtip',
            "scrollX": true,
            "scrollY": "300px",
            "scrollCollapse": true,
            "oColReorder": {
                "fnReorderCallback": function () {
                    var table = $('#' + SQLDataTypeViewer.currentDataView().name).DataTable();
                    console.log('Columns reordered ' + table.colReorder.order());
                }
            },
            stateSave: true
        });

        bdt.buildCoverageModalWindow = function (obj) {
            var dg = $('<div>', {
                id: "dialog",
                title: "Peptide Coverage for " + obj.proteinAccessionNumber + " " + obj.proteinDescription,
                style: "width:720px; height: 500px;"
            });

            dg.dialog({
                minWidth: 800,
                height: 550
            });

            var pviz = this.pviz;

            var se = new pviz.SeqEntry({
                sequence: obj.sequence()
            });
            var sei = new pviz.SeqEntryAnnotInteractiveView({
                model: se,
                el: dg
            }).render();

            //add peptides

            features = [];
            for (i = 0; i < obj.peptides.length; i++) {
                features.push({
                    category: 'Peptides',
                    text: obj.peptides[i].sequence,
                    start: obj.peptides[i].start,
                    end: obj.peptides[i].end - 1
                })
            }
            se.addFeatures(features);
            SQLDataTypeViewer.currentDataView().busySpinner.stop();
        };

        $('#' + configObj.tableName).on('order.dt', function () {
            var order = $('#' + configObj.tableName).DataTable().order();
            var columnName = $($('#' + configObj.tableName).DataTable().column(order[0][0]).header()).html();
            SQLDataTypeViewer.currentDataView().orderBy = [columnName, order[0][1]];
        });

        //When mousing over a protein Accession number and hovering for 2 seconds, show pViz protein coverage.
        $('#' + configObj.tableName).on('mouseover', 'td', function () {
            var cell = $('#' + configObj.tableName).DataTable().cell(this),
                idx = cell.index().column,
                title = $('#' + configObj.tableName).DataTable().columns(idx).header();

            BuildDataTable.hoverDelay = window.setTimeout(function() {
                if ($(title).html().toUpperCase() === 'ACCESSION') {
                    SQLDataTypeViewer.currentDataView().busySpinner.spin(document.getElementById('spinHere'));
                    ProteinCoverageManager.coverageForProtein(cell.data(), BuildDataTable.buildCoverageModalWindow)
                }}, 2000)
        });

        $('#' + configObj.tableName).on('mouseout', 'td', function () {
            window.clearTimeout(BuildDataTable.hoverDelay);
        });


        /**
         * Function to handle user selecting a row in a data table.
         * If the data table shows proteins or peptides, only allow a single row selected at a time.
         * PSM data can have multiple selected rows.
         */
        $('#' + configObj.tableName + " tbody").on("click", "tr", function () {
            var lModel = null,
                isSelected = false;

            if (configObj.tableName === 'psm') {
                $(this).toggleClass('selected');
                if (this.classList.contains("selected")) {
                    isSelected = true;

                    if (SQLDataTypeViewer.currentDataView().creatingLorikeetObject) {
                        //currently processing a lorikeet object. Ignore users current row selection. User is impatient.
                        $(this).toggleClass('selected');
                        return;
                    }

                }
            } else {
                if ($(this).hasClass('selected')) {
                    $(this).removeClass('selected');
                    //change data view state back to protein or peptide TODO: Refactor this out better.
                    SQLDataTypeViewer.currentDataView().name = configObj.tableName;
                    SQLDataTypeViewer.currentDataView().dataGridElement = 'protPepGrid';
                }
                else {
                    $('#' + configObj.tableName).DataTable().$('tr.selected').removeClass('selected');
                    $(this).addClass('selected');
                    isSelected = true;
                }
            }

            rNames = $('#' + configObj.tableName).DataTable().columns().header().map(function (v) {
                return $(v).html();
            });
            rData = $('#' + configObj.tableName).DataTable().row(this).data();
            selectedObj = _.object(rNames, rData);
            SQLDataTypeViewer.currentDataView().rowClickFunction[configObj.tableName](selectedObj, isSelected);
        });

        $('#reset').click( function (e) {
            e.preventDefault();
            $('#' + configObj.tableName).DataTable().colReorder.reset();
        } );
    };

    /**
     * This will create a div of MIN/MAX inputs.
     * These will be used to filter large PSM data sets
     *
     * @param confObject {
     *          data: data from galaxy,
     *          callBack: callback function for buttin click
     *      }
     */
    bdt.renderScoreFilters = function (confObject) {
        var i = 0,
            scoreData = confObject.data,
            inputA = null,
            internalDiv = $('<div/>'),
            scoreDiv = $('<div/>', {
                style: "width: 100%",
                id: "scoreDiv"
            }),
            scoreArray = [];

        for (i = 0; i < scoreData.rows[0].length; i++) {

            inputA = $('<input/>', {
                input: "number",
                class: "scoreFilter",
                id: scoreData.columns[i].title.replace(/\s+/g, '_'),
                name: scoreData.columns[i].title.replace(/\s+/g, '_'),
                placeholder: scoreData.rows[0][i],
                width: '100%'
            });
            scoreArray.push(inputA);
        }
        scoreDiv.append($('<br>'));
        scoreDiv.append(ScoreFilterManager.generateScoreFilterTable(scoreArray, confObject.callBack));
        $('#dataGrid').after(scoreDiv);

    };

    /**
     * Renders the sequence and description filters for protein and peptide views.
     */
    bdt.renderTextFilters = function () {
        var divElement;

        switch (SQLDataTypeViewer.currentDataView().name) {
            case 'peptide':
                divElement = TextFilterManager.generatePeptideFilterDiv();
                break;
            case 'protein':
                divElement = TextFilterManager.generateProteinFilterDiv();
                break;
            default:
                return;
        }

        $('#protPepGrid').after(divElement);

    };

    return bdt;

} (BuildDataTable || {}));