/**
 * Slider control for handling paging of data
 */
var PageSliderControl = function (confObj) {
    this.configuration = confObj;
    this._slider = $('#' + this.configuration.domElementID).slider();

    this._slider.slider('option', 'min', 1);
    this._slider.slider('option', 'max', SQLDataTypeViewer.currentDataView().maxPSMPages);
    this._slider.slider('option', 'value', SQLDataTypeViewer.currentDataView().currentOffset);
    this._slider.slider('option', 'slide', function (evt, ui) {
        $('#page_x').val(ui.value);
        $('#page_y').val(SQLDataTypeViewer.currentDataView().maxPSMPages);
        $('#record_y').val(SQLDataTypeViewer.currentDataView().recordSetSize);
    });
    this._slider.slider('option', 'stop', function (evt, ui) {
        SQLDataTypeViewer.currentDataView().currentOffset = ((ui.value - 1) * SQLDataTypeViewer.currentDataView().currentLimit);
        SQLDataTypeViewer.populateTable();
    });
    $('#page_x').val(1);
    $('#page_y').val(SQLDataTypeViewer.currentDataView().maxPSMPages);
    $('#record_y').val(SQLDataTypeViewer.currentDataView().recordSetSize);

    this.reZero = function () {
        this._slider.slider('option', 'min', 1);
        this._slider.slider('option', 'max', SQLDataTypeViewer.currentDataView().maxPSMPages);
        this._slider.slider('option', 'value', 1);
        $('#page_x').val(1);
        $('#page_y').val(SQLDataTypeViewer.currentDataView().maxPSMPages);
    };

};

/**
 * Spinner control for visual feedback
 *
 */
var ProgressSpinner = (function (spinner) {

    spinner.spinnerOpts = {
        lines: 13, // The number of lines to draw
        length: 20, // The length of each line
        width: 10, // The line thickness
        radius: 30, // The radius of the inner circle
        corners: 1, // Corner roundness (0..1)
        rotate: 0, // The rotation offset
        direction: 1, // 1: clockwise, -1: counterclockwise
        color: ['#7a0019', '#ffcc33'],
        speed: 1, // Rounds per second
        trail: 60, // Afterglow percentage
        shadow: true, // Whether to render a shadow
        hwaccel: false, // Whether to use hardware acceleration
        className: 'spinner', // The CSS class to assign to the spinner
        zIndex: 2e9, // The z-index (defaults to 2000000000)
        top: '50%', // Top position relative to parent
        left: '50%' // Left position relative to parent
    };

    spinner.getSpinner = function () {
        return new Spinner(spinner.spinnerOpts);
    }

    return spinner;
}(ProgressSpinner || {}));

/**
 * Depending on which table is displayed, selecting a data row will generate different behaviors.
 */
var RowSelectFunctions = (function (rsf) {

    rsf.renderLorikeet = function (lorikeetModelID) {
        var lm = SQLDataTypeViewer.currentDataView().lorikeetModels[lorikeetModelID],
            specElement = MSMSTabManager.activateTab(lm.properties.sequence, lm.properties.scanNum);

        $(specElement).specview(lm.getOptions());
        SQLDataTypeViewer.currentDataView().busySpinner.stop();
        SQLDataTypeViewer.currentDataView().creatingLorikeetObject = false;
    };

    rsf.storeLorikeetModel = function(lModel) {
        SQLDataTypeViewer.currentDataView().lorikeetModels[lModel.properties.scanPKID] = lModel
        RowSelectFunctions.renderLorikeet(lModel.properties.scanPKID);
    };

    rsf.manageLorikeetModel = function(selectedRowData, isSelected) {
        var lmodel = null;

        if (isSelected) {
            SQLDataTypeViewer.currentDataView().creatingLorikeetObject = true;
            SQLDataTypeViewer.currentDataView().busySpinner.spin(document.getElementById('spinHere'));
            if (selectedObj.pkid in SQLDataTypeViewer.currentDataView().lorikeetModels) {
                RowSelectFunctions.renderLorikeet(selectedObj.pkid);
            } else {
                LorikeetFactory.createLorikeetModel(selectedObj, RowSelectFunctions.storeLorikeetModel)
            }
        } else {
            lmodel = SQLDataTypeViewer.currentDataView().lorikeetModels[selectedObj.pkid];
            MSMSTabManager.deactivateTab(lmodel.properties.sequence, lmodel.properties.scanNum)
        }
    };

    rsf.psmFromProtPep = function (stateName, protPepText) {
        var currentState = SQLDataTypeViewer.currentDataView();
        SQLDataTypeViewer.currentDataView().busySpinner.spin(document.getElementById('spinHere'));
        currentState.dataGridElement = 'dataGrid';
        currentState.name = stateName;
        currentState.pepProtText = protPepText;
        currentState.currentFilter = null;
        currentState.columnOrder = null;
        currentState.currentOffset = 0;
        currentState.totalRowCount = 0;
        currentState.recordSetSize = 0;
        currentState.orderBy = null;
        currentState.maxPSMPages = 0;
        DataProvider.retrievePSMDetail(SQLDataTypeViewer.manageReturnedData);
    };

    rsf.manageProteinSelection = function(selectedRowData, isSelected) {
        if (isSelected) {
            RowSelectFunctions.psmFromProtPep('psmFromProtein', selectedRowData.Description);
        } else {
            $('#dataGrid').empty();
            $('#scoreDiv').empty();
            MSMSTabManager.clearAllActiveTabs();
        }

    };

    rsf.managePeptideSelection = function(selectedRowData, isSelected) {
        if (isSelected) {
            RowSelectFunctions.psmFromProtPep('psmFromPeptide', selectedRowData.Sequence);
        } else {
            $('#dataGrid').empty();
            $('#scoreDiv').empty();
            MSMSTabManager.clearAllActiveTabs();
        }
    };

    return rsf;
} (RowSelectFunctions || {}));

var ViewSelectFunctions = (function (vsf) {

    vsf.startProcessing = function (viewName) {
        SQLDataTypeViewer.currentDataView().busySpinner.spin(document.getElementById('spinHere'));

        SQLDataTypeViewer.currentDataView().currentFilter = null;
        SQLDataTypeViewer.currentDataView().columnOrder = null;
        SQLDataTypeViewer.currentDataView().currentOffset = 0;
        SQLDataTypeViewer.currentDataView().totalRowCount = 0;
        SQLDataTypeViewer.currentDataView().recordSetSize = 0;
        SQLDataTypeViewer.currentDataView().orderBy = null;
        SQLDataTypeViewer.currentDataView().maxPSMPages = 0;


        MSMSTabManager.clearAllActiveTabs();
    };

    vsf.preparePSMView = function () {
        ViewSelectFunctions.startProcessing();
        SQLDataTypeViewer.currentDataView().dataGridElement = 'dataGrid';
        SQLDataTypeViewer.currentDataView().name = 'psm';
        SQLDataTypeViewer.currentDataView().maxPSMPages = Math.ceil(SQLDataTypeViewer.currentDataView().tableRowCount.PeptideEvidence/SQLDataTypeViewer.currentDataView().currentLimit);

        $('#protPepGrid').empty();
        $('#textFilter').empty();
        MSMSTabManager.clearAllActiveTabs();

        SQLDataTypeViewer.populateTable(SQLDataTypeViewer.resetMaximumPageSize, true);
        DataProvider.retrieveData({
            'href': SQLDataTypeViewer.currentDataView().href,
            'datasetID': SQLDataTypeViewer.currentDataView().datasetID,
                'callBack': SQLDataTypeViewer.fillScoreRangeDiv,
            'tableColumns': SQLDataTypeViewer.currentDataView().tableColumns,
            'scoreRange': true
        });
    };

    vsf.prepareProteinView = function () {
        SQLDataTypeViewer.currentDataView().dataGridElement = 'protPepGrid';
        SQLDataTypeViewer.currentDataView().name = 'protein';
        ViewSelectFunctions.startProcessing();
        $('#dataGrid').empty();
        $('#scoreDiv').empty();
        $('#textFilter').empty();
        SQLDataTypeViewer.populateTable(SQLDataTypeViewer.resetMaximumPageSize, true);
        //dataprovider call with accession/description filtering call back.
        BuildDataTable.renderTextFilters();

    };

    vsf.preparePeptideView = function () {
        SQLDataTypeViewer.currentDataView().dataGridElement = 'protPepGrid';
        SQLDataTypeViewer.currentDataView().name = 'peptide';
        ViewSelectFunctions.startProcessing();
        $('#dataGrid').empty();
        $('#scoreDiv').empty();
        $('#textFilter').empty();
        SQLDataTypeViewer.populateTable(SQLDataTypeViewer.resetMaximumPageSize, true);
        BuildDataTable.renderTextFilters();
    };

    return vsf;
} (ViewSelectFunctions || {}));

/**
 * Main controller for Galaxy SQL Data Type Viewer
 */
var SQLDataTypeViewer = (function (dv) {

    var currentDataView = {
        busySpinner: ProgressSpinner.getSpinner(),
        dataGridElement: '',
        dataName: '',
        datasetID: '',
        href: '',
        tableColumns: '',
        name: '',
        currentOffset: 0,
        currentLimit: 50,
        totalRowCount: 0,
        recordSetSize: 0,
        currentFilter: null,
        orderBy: null,
        columnOrder: null,
        viewSelectFunctions: {
            psm: ViewSelectFunctions.preparePSMView,
            protein: ViewSelectFunctions.prepareProteinView,
            peptide: ViewSelectFunctions.preparePeptideView
        },
        rowClickFunction: {
            psm: RowSelectFunctions.manageLorikeetModel,
            protein: RowSelectFunctions.manageProteinSelection,
            peptide: RowSelectFunctions.managePeptideSelection
        },
        lorikeetModels: {} //key: scan pkid, value: lorikeet object
    };

    dv.currentDataView = function () {
        return currentDataView;
    };

    //configures psm app based on the mako template input from Galaxy.
    dv.produceVisualization = function (configurationObject) {
        var prop;


        $('#toggleDataGrid').on('click', GridToggle.toggleDivs);
        $('#toggleProtPepGrid').on('click', GridToggle.toggleDivs);

        for (prop in configurationObject) {
            currentDataView[prop] = configurationObject[prop];
        }
        currentDataView.maxPSMPages = Math.ceil(currentDataView.tableRowCount.PeptideEvidence/currentDataView.currentLimit);
        SQLDataTypeViewer.currentDataView().recordSetSize = SQLDataTypeViewer.currentDataView().tableRowCount.PeptideEvidence;

        currentDataView.name = 'psm';
        SQLDataTypeViewer.populateTable();
        //little test of getting score range.
        DataProvider.retrieveData({
            'href': currentDataView.href,
            'datasetID': currentDataView.datasetID,
            'callBack': SQLDataTypeViewer.fillScoreRangeDiv,
            'tableColumns': currentDataView.tableColumns,
            'scoreRange': true
        });
        currentDataView.pageSliderControl = new PageSliderControl({domElementID: 'pageSlider'});
        $('#dataView').change(function() {
            SQLDataTypeViewer.currentDataView().viewSelectFunctions[$(this).find(":selected").val()]();
        });
    };

    dv.resetMaximumPageSize = function(queryData) {
        SQLDataTypeViewer.currentDataView().currentTotalRecordCount = queryData.rows[0][0];
        SQLDataTypeViewer.currentDataView().currentOffset = 0;
        SQLDataTypeViewer.currentDataView().recordSetSize = queryData.rows[0][0];
        SQLDataTypeViewer.currentDataView().maxPSMPages = Math.ceil(queryData.rows[0][0]/SQLDataTypeViewer.currentDataView().currentLimit);
        SQLDataTypeViewer.currentDataView().pageSliderControl.reZero();
        SQLDataTypeViewer.populateTable(SQLDataTypeViewer.manageReturnedData);
    }

    dv.fillScoreRangeDiv = function (scoreData) {
        var filterFunction = function () {

            var allInputs = $("#scoreDiv .scoreFilter"),
                i = 0,
                filterObject = {},
                filterValue = 0,
                propName = null,
                scoreType = null,
                isFilterDirty = false; //if any filter value has non placeholder value, then filter is dirty.

            for (i = 0; i < allInputs.length; i += 1) {

                propName = allInputs[i].name.replace(/_/g, ' ');
                scoreType = propName.slice(0,3); // MIN || MAX
                propName = propName.slice(4); //just the field name now

                if (isNaN(parseFloat(allInputs[i].value))) {
                    //filterValue = parseFloat(allInputs[i].placeholder);
                    //DO NOTHING, USER IS __NOT__ FILTERING ON THIS VALUE
                } else {
                    if (!(propName in filterObject)) {
                        filterObject[propName] = {};
                    }
                    filterValue = parseFloat(allInputs[i].value);
                    isFilterDirty = true;
                    filterObject[propName][scoreType] = filterValue;
                }
            }

            if (isFilterDirty) {
                console.log("SETTING FILTER");
                currentDataView.currentFilter = filterObject;
            } else {
                console.log("REMOVING FILTER");
                currentDataView.currentFilter = null;
            }


            //filtering data, max pages will be changing. Wherever the offset is currently, must set to 0
            SQLDataTypeViewer.currentDataView().currentOffset = 0; // if not reset, query will not return proper count. TODO: refactor data state prep for changes.
            SQLDataTypeViewer.populateTable(SQLDataTypeViewer.resetMaximumPageSize, true);
           };

        BuildDataTable.renderScoreFilters({
            data: scoreData,
            callBack: filterFunction
        });
    };

    dv.fillAndDrawTable = function (tableData) {
        BuildDataTable.renderTable({
            'tableName': currentDataView.name,
            'dataValues': tableData,
            'elementID': currentDataView.dataGridElement
        });
    };

    dv.manageReturnedData = function (data) {
        //Now draw
        SQLDataTypeViewer.fillAndDrawTable(data);
        currentDataView.busySpinner.stop();
    };

    dv.populateTable =  function (callBackFn, countOnly) {

        var callBack = callBackFn ||  SQLDataTypeViewer.manageReturnedData,
            countQueryOnly = countOnly || false;

        DataProvider.retrieveData({
            callBack: callBack,
            href: currentDataView.href,
            datasetID: currentDataView.datasetID,
            tableColumns: currentDataView.tableColumns,
            type: currentDataView.name,
            limit: currentDataView.currentLimit,
            offset: currentDataView.currentOffset,
            whereFilter: currentDataView.currentFilter,
            orderBy: currentDataView.orderBy,
            countOnly: countQueryOnly
        });

        currentDataView.busySpinner.spin(document.getElementById('spinHere'));
    };

    return dv;
} (SQLDataTypeViewer || {}));
