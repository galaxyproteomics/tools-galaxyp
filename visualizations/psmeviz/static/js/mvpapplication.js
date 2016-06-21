/**
  User can select either peptides or proteins. This module publishes the
  user's choice.
*/
var available_tables = {

  init: function(parent_div) {
    // $('#' + parent_div).append($.parseHTML(
    //   '<div id="type_group" class="btn-group" data-toggle="buttons"><label class="btn btn-primary active">' +
    //   '<input type="radio" name="options" id="peptides" autocomplete="off" checked>Peptides' +
    //   '</label></div>'
    //   +
    //   '<label class="btn btn-primary">' +
    //   '<input type="radio" name="options" id="proteins" autocomplete="off">Proteins' +
    //   '</label></div>'
    // ));
    $('#type_group').on('change', function(event) {
      available_tables.publish('userChangedTable', event.target.id);
    });
    //Initial publish of default value.
    available_tables.publish('userChangedTable', 'peptides');
  }
};
//Module to allow user filtering on peptide sequence or protein name;
var data_filter = {

    filterData: function () {
        console.log('publishing filtering data now');
        this.publish('userSelectedFilter', $('#filter_string').val());
    },

    clearFilter: function () {
        $('#filter_string').val('');
        this.publish('userClearedFilter', '');
    },

    init: function (initObj) {
        $('#' + initObj.domDiv).append($.parseHTML(
            '<div class="row"><div class="col-lg-6"><div class="input-group">' +
            '<div class="input-group-btn">' +
            '<button type="button" class="btn btn-default dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Filter' +
            '<span class="caret"></span></button><ul class="dropdown-menu" id="filter_actions">' +
            '<li><a href="#" id="filter">Filter by peptide sequence(s)</a></li>' +
            '<li><a href="#" id="clear">Clear Filter</a></li>' +
            '</ul></div>' +
            '<input id="filter_string" type="text" class="form-control" aria-label="..."></div>' +
            '</div></div>'
        ));
        
        $('#filter_actions li').on('click', function (event) {
            if (event.target.id === 'filter') {
                data_filter.filterData();
            }
            if (event.target.id === 'clear') {
                data_filter.clearFilter();
            }
        });
        this.subscribe('userChangedTable', function (arg) {
            data_filter.clearFilter();
        });

        this.subscribe('userResetTable', function(arg) {
            $('#filter_string').val('');
        });

        this.subscribe('userSelectsSequence', function (arg) {
            //Place the selected sequence(s) into the input field
            var current_input = $('#filter_string').val();
            arg.seq.map(function (cv) {
                current_input += cv + ' ';
            });
            $('#filter_string').val(current_input);
        });

        //enable the UI btn
        $('#peptide_sequence').attr({
            'data-toggle': 'collapse',
            'data-target': '#data_filter',
            'aria-expanded': 'false',
            'aria-controls': 'collapseExample'});

    }
};
/**
 Module for managing details of data transfer to and from Galaxy.
 This includes creating a "server-side" method to handle large databases
 in a performant manner.
 */
var DataManager = function (initObj) {

    this.hrefValue = initObj.href;
    this.dataID = initObj.dataSetID;
    this.historyID = initObj.historyID;
    this.tableRowCount = initObj.tableRowCount;
    this.tableColumns = initObj.tableColumns;
    this.urlString = this.hrefValue + '/api/datasets/' + this.dataID +
        '?data_type=raw_data&provider=sqlite-table&headers=True&query=';

    /**
     confObj.rawData -> raw data record set from ajax call
     confObj.requestObject -> the request object used for raw data
     */
    this.generateResponseObject = function (confObj) {
        var colNames = [];
        var dataArray = [];
        var responseObject = new ResponseObject();
        var rawData = confObj.rawData;
        var requestObject = confObj.requestObject;
        //TODO: this is NOT pub/sub
        var getModificationString = function(ro) {
            var this_ro = ro;
            var seqs = [];
            ro.data.map(function(obj){
                var o = {};
                o.pkid = obj.peptidePKID;
                o.sequence = obj.sequence;
                seqs.push(o);
            });
            f_seqs = sequence_formatter.formatted_sequences(seqs);
            ro.data.map(function(obj){
                obj.sequence = f_seqs[obj.peptidePKID];
            });
            return ro;
        };

        requestObject.generateColumnNames().map(function (cv) {
            colNames.push(cv.data);
        });
        rawData.data.splice(0, 1); //removes the column name elements from the record set.
        rawData.data.map(function (x) {
            var tObj = {};
            colNames.map(function (cv, idx) {
                tObj[cv] = x[idx];
            });
            dataArray.push(tObj);
        });

        responseObject.draw = parseInt(requestObject.draw);
        if (this.tableRowCount[requestObject.tableName]) {
            responseObject.recordsTotal = this.tableRowCount[requestObject
                .tableName];
            responseObject.recordsFiltered = responseObject.recordsTotal;
        } else {
            responseObject.recordsTotal = requestObject.actualRecordCount;
            responseObject.recordsFiltered = requestObject.actualRecordCount;
        }

        //TODO: this is not good. Rethink this.
        if (requestObject.scoreFilterObject || requestObject.modificationFilterObject || requestObject.accessionFilter) {
            responseObject.recordsFiltered = requestObject.filteredRecordCount;
        }
        responseObject.data = dataArray;

        //Grab formatted sequence strings before sending to data table
        return  getModificationString(responseObject);
    };


    this.executeSQL = function (confObj, urlValue) {
        $.get(urlValue, function (data) {
                confObj.callBackFn(this.generateResponseObject({
                    rawData: data,
                    requestObject: confObj
                })); //TODO: bind outer this.
            }.bind(this))
            .error(function (jqXHR) {
                console.log('Error in executing SQL : ' + jqXHR.responseText);
            });
    };


    /**
     * For paging, we need the full data count.
     *
     * @param {Object} requestObject
     */
    this.getDataCount = function (requestObject) {
        $.get(this.urlString + requestObject.generateSQL(true),
            function (data) {
                if (requestObject.scoreFilterObject || requestObject.modificationFilterObject || requestObject.accessionFilter ) { //TODO: Same as above
                    requestObject.setFilteredDataCount(data);
                } else {
                    requestObject.setFullDataCount(data);
                }
                requestObject.needCount = false;
                this.getData(requestObject);
            }.bind(this));
    };


    /**
     * We have full data count, now get limited and offset data.
     *
     @param {Object} requestObject
     */
    this.getData = function (requestObject) {
        var url = this.urlString;
        url += requestObject.generateSQL();
        this.executeSQL(requestObject, url);
    };


    /**
     This function is used in by the DataTables code as a server-side ajax
     data provider.
     */
    this.ajaxDataProvider = function (requestData, tableSettings, requestObject,
                                      callBackFn) {
        var ro = requestObject;

        ro.callBackFn = callBackFn;
        ro.limit = requestData.length;
        ro.offset = requestData.start;
        ro.draw = requestData.draw;

        //requestData contains the datatable filter and order mandates
        if (requestData.order.length > 0) {
            ro.orderColumn = requestData.columns[requestData.order[0].column]
                .name;
            ro.orderDirection = requestData.order[0].dir;
        }

        if (ro.needCount) {
            this.getDataCount(ro);
        } else {
            this.getData(ro);
        }
    };

}; //end DataManger
//Core request object. Used to manage the data queries.
var RequestObject = function () {
    this.limit = 10;
    this.offset = 0;
    this.draw = 0;
    this.callBackFn = null;
    this.orderColumn = null;
    this.orderDirection = null;
    this.needCount = false;
    this.psmQueryValues = null;
    this.stringFilterObject = null;
    this.actualRecordCount = 0;
    this.filteredRecordCount = 0;
    this._tableName = undefined;
    this.score_fields = undefined;
    this.customSQL = undefined;
    this.base_sql = {
        proteins: 'SELECT DISTINCT ' +
        'dbs.accession, dbs.description ##SCORES##' +
        'FROM ' +
        'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
        'spectrumidentification si, score ' +
        'WHERE ' +
        'pe.dbsequence_pkid = dbs.pkid AND ' +
        'pe.peptide_pkid = peptide.pkid AND ' +
        'pe.spectrumidentification_pkid = si.pkid AND ' +
        'si.spectrum_pkid = spectrum.pkid AND ' +
        'score.spectrumidentification_pkid = si.pkid ',
        peptides: 'SELECT DISTINCT Peptide.sequence, Peptide.pkid ##SCORES## FROM spectrum, peptide, peptideevidence pe, ' +
            'DBSequence dbs, spectrumidentification si, score WHERE pe.dbsequence_pkid = dbs.pkid AND ' +
            'pe.peptide_pkid = peptide.pkid AND pe.spectrumidentification_pkid = si.pkid AND ' +
            'si.spectrum_pkid = spectrum.pkid AND score.spectrumidentification_pkid = si.pkid '
};
    this.filter_query_parts = {
        proteins: {
            column: 'dbs.accession',
            likeClause: 'SELECT DBSequence.accession ' +
            'FROM DBSequence WHERE DBSequence.accession LIKE '
        },
        peptides: {
            column: 'peptide.sequence',
            likeClause: 'SELECT peptide.sequence FROM peptide ' +
            'WHERE peptide.sequence LIKE '
        }
    };
    /**
     PSM queries are created from four parts
     1) The score values found in the score table. This is dynamic, but the same for
     both peptides and proteins.
     2) this.psmQueryString_A
     3) the peptide or protein WHERE condition
     4) this.psmQueryString_B
     */
    this.psmQueryString_A =
        ' ,Peptide.sequence, Peptide.pkid, Peptide.modNum, group_concat(dbs.accession), si.pkid , pe.isDecoy FROM spectrum, peptide, peptideevidence pe, DBSequence dbs, spectrumidentification si, score WHERE pe.dbsequence_pkid = dbs.pkid AND ';
    this.psmQueryString_B =
        'pe.peptide_pkid = peptide.pkid AND pe.spectrumidentification_pkid = si.pkid AND si.spectrum_pkid = spectrum.pkid AND score.spectrumidentification_pkid = si.pkid ';

    //Creates the select values for all the score fields found in the Score table.
    this.generateScoreSelect = function () {
        var returnStr = 'SELECT ';
        //Dont want these fields in the select portion of the query.
        var excludedFields = [
            'pkid',
            'spectrum_identification_id',
            'SpectrumIdentification_pkid'
        ];
        var cleanedArrary = $(this.psmQueryValues.score_columns).not(
            excludedFields);
        //Little strange here since cleanedArrary is a JQuery object TODO: use the util.js function.
        cleanedArrary.map(function (idx, cv) {
            if (idx === 0) {
                returnStr = returnStr + 'Score."' + cv + '" ';
            } else {
                returnStr = returnStr + ',Score."' + cv + '" ';
            }
        });
        return returnStr;
    };

    //Helper functions for generating column names
    this.cleanRawColumnNames = function (nameArray) {
        var returnArray = [];
        nameArray.map(function (cv) {
            if (cv.indexOf('CAST') > -1) {
                returnArray.push(cv.split(/AS REAL\) AS /)[1].slice(1, -1)); //get rid of the AS parens.
            } else if (cv.indexOf('AS') > -1) {
                returnArray.push(cv.split('AS')[0].trim());
            } else if (cv.indexOf('DISTINCT') > -1) {
                returnArray.push(cv.split('DISTINCT')[1].trim());
            } else {
                returnArray.push(cv);
            }
        });
        return returnArray;
    };

    this.makeNameArray = function (rawArray) {
        var returnArray = [];
        rawArray.map(function (cv) {
            var obj = {};
            if (cv.indexOf('Peptide.pkid') > -1) {
                cv = 'Peptide.peptidePKID';
            }
            obj.data = cv.indexOf('count') > -1 ? 'count' : cv.trim().split('.')[1];
            obj.name = cv.trim();
            obj.title = cv.trim();
            returnArray.push(obj);
        });
        return returnArray;
    };

    //Generate column names for DataTables API
    this.generateColumnNames = function () {
        var rawColumns;
        var sqlStr = this.generateSQL();
        var str = sqlStr.slice(sqlStr.indexOf('SELECT') + 6,
            sqlStr.indexOf('FROM'));
        rawColumns = this.cleanRawColumnNames(str.split(','));

        return this.makeNameArray(rawColumns);
    };

    this.setFullDataCount = function (dataset) {
        this.actualRecordCount = dataset.data[1][0];
    };

    this.setFilteredDataCount = function (dataset) {
        this.filteredRecordCount = dataset.data[1][0];
    };

    this.generateFilterClause = function () {
        var spliceLoc = this.customSQL.indexOf('GROUP');
        var half1 = this.customSQL.slice(0, spliceLoc);
        var half2 = this.customSQL.slice(spliceLoc);
        var fStr = '';

        fStr = ' AND ' + this.filter_query_parts[this.tableName].column +
            ' in (' + this.filter_query_parts[this.tableName].likeClause;

        this.stringFilterObject.map(function (cv, idx) {
            if (idx === 0) {
                fStr = fStr + ' %22%25' + cv + '%25%22 ';
            } else {
                fStr = fStr + ' OR ' + this.filter_query_parts[this.tableName]
                        .column +
                    ' LIKE %22%25' + cv + '%25%22 ';
            }
        }.bind(this));

        return half1 + fStr + ') ' + half2;

    };

    this.generatePSMQuery = function () {
        var returnStr = this.generateScoreSelect();
        var elem;
        var spectrum_columns = app_utils.remove_array_values(['id'], this.table_columns.Spectrum);

        //Get rid of spans if needed
        //If sequence has modifications, it may have <span> tags.
        // if (this.psmQueryValues.data.sequence.indexOf('<span') > -1) {
        //     elem = $.parseHTML(this.psmQueryValues.data.sequence);
        //     this.psmQueryValues.data.sequence = $(elem).text();
        // }

        //Prepare the Spectrum table select
        spectrum_columns.map(function(cv){
            returnStr += ', Spectrum.' + cv;
        });

        returnStr = returnStr + this.psmQueryString_A;
        switch (this.psmQueryValues.type) {
            case 'peptides':
                returnStr = returnStr + ' peptide.pkid = "' + this.psmQueryValues
                        .data.peptidePKID +
                    '" AND ';
                break;
            case 'proteins':
                returnStr = returnStr + ' dbs.accession = "' + this.psmQueryValues.data
                        .accession +
                    '" AND ';
                break;
            default:
                console.log('Oh oh.');
        }
        returnStr = returnStr + this.psmQueryString_B;
        return returnStr;
    };

    this.build_mod_query = function(obj) {
        var returnStr = '';
        var select_stmt = obj.qStr.slice(0, obj.qStr.indexOf('FROM'));
        var from_stmt = obj.qStr.slice(obj.qStr.indexOf('FROM'), obj.qStr.indexOf('WHERE'));
        var where_stmt = obj.qStr.slice(obj.qStr.indexOf('WHERE'));
        var mod_num = 1;

        obj.mods.include.map(function(cv){
            from_stmt += ', Modification m' + mod_num + ' ';
            where_stmt += ' AND m' + mod_num + '.Peptide_pkid = peptide.pkid ';
            where_stmt += ' AND m' + mod_num + '.name = "' + cv + '"';
            mod_num += 1;
        });

        returnStr = returnStr + select_stmt + from_stmt + where_stmt;

        return returnStr;
    };

    this.generateSQL = function (wantCount) {
        var countQuery = wantCount || false;
        var returnStr;
        var preWhere;
        var postWhere;
        var scoreSelect = 'SELECT peptide.sequence ';

        returnStr = this.customSQL;

        if (this.psmQueryValues) {
            returnStr = this.generatePSMQuery();
        }

        if (this.accessionFilter) {
            //user wants peptides associated with a specific accession.
            console.log("Accession filter now");
            returnStr += ' AND dbs.accession = "' + this.accessionFilter + '"';
        }

        if (this.stringFilterObject) {
            returnStr = this.generateFilterClause();
        }

        if (this.scoreFilterObject) {
            postWhere = returnStr.substring(returnStr.indexOf('WHERE'));
            preWhere = returnStr.substring(0,returnStr.indexOf('WHERE'));
            returnStr = preWhere + ' ' + postWhere + ' ' + this.scoreFilterObject.generateWhereClause();

            this.scoreFilterObject.getScoreFieldNames().map(function(cv) {
               scoreSelect = scoreSelect + ', score."' + cv + '" ';
            });
        }

        //User has asked for filtering based on peptide modification
        if (this.modificationFilterObject) {
            returnStr = this.build_mod_query({
                qStr: returnStr,
                mods: this.modificationFilterObject
            });
        }

        if (this.orderColumn) {
            if (this.orderColumn.indexOf('Score') > -1) {
                returnStr += ' ORDER BY CAST(' + this.orderColumn +
                    ' AS REAL) ' +
                    this
                        .orderDirection;
            } else {
                returnStr += ' ORDER BY ' + this.orderColumn + ' ' + this.orderDirection;
            }
        }

        if (countQuery) {
            returnStr = 'SELECT COUNT(*) FROM (' + returnStr.slice(0,
                    returnStr.indexOf(
                        'ORDER')) + ')';
        }



        if (this.limit > 0) {
            returnStr += ' LIMIT ' + this.limit + ' OFFSET ' + this.offset;
        }

        return returnStr;
    };
};

//Setter/Getter for table name, there are some cascading changes.
Object.defineProperties(RequestObject.prototype, {
    tableName: {
        get: function () {
            return this._tableName;
        },
        set: function (value) {
            var s = '';
            this._tableName = value;
            this.customSQL = this.base_sql[value.toLocaleLowerCase()];
            if (this.customSQL.indexOf('##SCORES##') > -1 && this.score_fields) {
                //replace with score fields
                this.score_fields.map(function(cv){
                   s = s + ', Score."' + cv + '" ';
                });
                this.customSQL = this.customSQL.replace('##SCORES##', s);
            } else {

            }
            this.needCount = true;
        }
    }
});


/**
 * Specified by the Datatables.net server side response spec.
 *
 *
 Parameter name        Type        Description
 draw                integerJS    The draw counter that this object is a response to - from the draw parameter sent as part of the data request. Note that it is strongly recommended for security reasons that you cast this parameter to an integer, rather than simply echoing back to the client what it sent in the draw parameter, in order to prevent Cross Site Scripting (XSS) attacks.
 recordsTotal        integerJS    Total records, before filtering (i.e. the total number of records in the database)
 recordsFiltered    integerJS    Total records, after filtering (i.e. the total number of records after filtering has been applied - not just the number of records being returned for this page of data).
 data                arrayJS        The data to be displayed in the table. This is an array of data source objects, one for each row, which will be used by DataTables. Note that this parameter's name can be changed using the ajaxDT option's dataSrc property.
 error                stringJS    Optional: If an error occurs during the running of the server-side processing script, you can inform the user of this error by passing back the error message to be displayed using this parameter. Do not include if there is no error.
 In addition to the above parameters which control the overall table, DataTables can use the following optional parameters on each individual row's data source object to perform automatic actions for you:
 Parameter name        Type        Description
 DT_RowId            stringJS    Set the ID property of the tr node to this value
 DT_RowClass        stringJS    Add this class to the tr node
 DT_RowData            objectJS    Add the data contained in the object to the row using the jQuery data() method to set the data, which can also then be used for later retrieval (for example on a click event).
 DT_RowAttr            objectJS    Add the data contained in the object to the row tr node as attributes. The object keys are used as the attribute keys and the values as the corresponding attribute values. This is performed using using the jQuery param() method. Please note that this option requires DataTables 1.10.5 or newer.
 *
 * @constructor
 */
var ResponseObject = function () {
    this.draw = 0;
    this.recordsTotal = 0;
    this.recordsFiltered = 0;
    this.data = [];
    this.error = null;
};

//Simple object for holding score filters and providing a WHERE clause
//based on the filter values.
var ScoreFilterObject = function (filterValues) {
    this.filterValues = filterValues;

    this.getScoreFieldNames = function() {
        return Object.keys(this.filterValues);
    };

    this.generateWhereClause = function() {
        var y = this.filterValues;
        var where_clause = '';
        var minRE = /MIN/g;
        var maxRE = /MAX/g;
        var txtRE = /TEXT/g;

        Object.keys(this.filterValues).map(function(cv){
            var field = cv;
            Object.keys(this.filterValues[cv]).map(function(cv2){
                where_clause += ' AND Score."' + field +'" '+ cv2 + ' ' + y[cv][cv2];});
        }.bind(this));

        //Replace MIN with >=, MAX with <= and TEXT with LIKE TODO: handle the text after TEXT!
        where_clause = where_clause.replace(minRE, '>=');
        where_clause = where_clause.replace(maxRE, '<=');
        where_clause = where_clause.replace(txtRE, 'LIKE')

        return where_clause;
    };
};//module for creating the detail table.
//PSM(s) for selected protein or peptide.
var detail_table = {

    type: null,
    select_detail: null,
    ro: null,
    base_div: null,
    galaxy_configuration: null,

    clean_existing_table: function () {
        $('#detail_table').empty();
    },

    //Render the DataTable table filled with PSMs
    render_table: function (selectedRowData) {
        var pdt;

        detail_table.clean_existing_table();

        detail_table.ro = new RequestObject();
        detail_table.ro.table_columns = this.galaxy_configuration.tableColumns;
        detail_table.ro.needCount = false;
        detail_table.ro.tableName = selectedRowData.type;
        detail_table.ro.psmQueryValues = {
            score_columns: this.galaxy_configuration.tableColumns.Score,
            type: selectedRowData.type,
            data: selectedRowData.data
        };

        //Create a data manager for this newly rendered table
        detail_table.data_manager = new DataManager({
            href: detail_table.galaxy_configuration.href,
            dataSetID: detail_table.galaxy_configuration.datasetID,
            historyID: detail_table.galaxy_configuration.historyID,
            tableRowCount: detail_table.galaxy_configuration.tableRowCount,
            tableColumns: detail_table.galaxy_configuration.tableColumns
        });

        $('#detail_table').append($.parseHTML(
            '<table class="table table-striped table-bordered" id="psm_data_table"></table>'
        ));
        $('#psm_data_table').DataTable({
            dom: 'Blftrip',
            select: {style: 'multi'},
            buttons: [
                'csvHtml5',
                {
                    extend: 'collection',
                    text: 'Show columns',
                    buttons: ['columnsVisibility'],
                    visibility: true
                }
            ],
            searching: false,
            scrollX: '100%',
            processing: true,
            serverSide: true,
            ajax: function (data, callback, settings) {
                detail_table.data_manager.ajaxDataProvider(data, settings,
                    detail_table.ro, callback);
            },
            columns: this.ro.generateColumnNames(),
            colReorder: true
        });

        pdt = $('#psm_data_table').DataTable();
        pdt.on('select',  function ( e, dt, type, indexes ){
            if ( type === 'row' ) {
                detail_table.publish('psmRowSelected', {
                    type: 'psm',
                    data: dt.data()
                });
            }
        });
        pdt.on('deselect',  function ( e, dt, type, indexes ){
            if ( type === 'row' ) {
                detail_table.publish('psmRowRemoved', {
                    type: 'psm',
                    data: dt.data()
                });
            }
        });
    },

    //User has set filtering based on PSM scores,
    // now create filter, query and redraw table
    filter_by_score: function(scoreObj) {
        var table = $('#psm_data_table').DataTable();
        detail_table.ro.scoreFilterObject = scoreObj;
        detail_table.ro.needCount = true;
        table.draw();
    },

    clear_score_filter: function() {
        var table = $('#psm_data_table').DataTable();
        if (detail_table.ro.scoreFilterObject) {
            detail_table.ro.scoreFilterObject = null;
            detail_table.ro.needCount = true;
            table.draw();
        }
    },

    clear_selected_row: function(scanId) {
        var scanID = parseInt(scanId);
        var t = $('#psm_data_table').DataTable();
        var selected_rows = t.rows( { selected: true } ).data();
        var the_idx;

        selected_rows.map(function(cv, idx){
           if (cv.pkid === scanID) {
               //this is the row to deselect
               the_idx = idx;
           }
        });

        t.rows({selected: true})[0].map(function(cv, idx){
            if (idx === the_idx) {
                t.row(cv).deselect();
            }
        });

    },
    
    /**
     Module is initialized when a user selects a protein or peptide
     initObj.base_div: DOM id for rendering
     initObj.type: peptide or protein
     initObj.selection: details of the peptide/protein chosen
     */
    init: function (initObj) {
        detail_table.base_div = initObj.base_div;
        detail_table.galaxy_configuration = initObj.galaxy_configuration;


        //Subscribe here to events of interest.
        detail_table.subscribe('overviewRowSelected', function (arg) {
            detail_table.render_table(arg);
        });
        detail_table.subscribe('userChangedTable', function (arg) {
            detail_table.clean_existing_table();
        });
        detail_table.subscribe('userResetTable', function(arg){
            detail_table.clean_existing_table();
        });
        detail_table.subscribe('scoreFilterInvoked', function (arg) {
            detail_table.filter_by_score(arg);
        });
        detail_table.subscribe('scoreFilterCleared', function (arg) {
            detail_table.clear_score_filter();
        });

        detail_table.subscribe('spectrumRemoved', function(arg) {
           detail_table.clear_selected_row(arg.scanId);
        })
    }
};
/**
 * Accesses Galaxy history to find and retrieve tabular text files.
 *
 * @type {{}}
 */
var retrieve_sequences = {

    available_files: {},

    need_sequences: true,

    clear_modal: function() {
        retrieve_sequences.publish('longProcessFinished', {});
    },

    //fill the UI dropdown with the list of available datasets from history
    populate_dropdown: function() {
        Object.keys(retrieve_sequences.available_files).map(function(cv){
            var dataID = retrieve_sequences.available_files[cv].datasetID;
            var elem = '<li value="' +  dataID + '">' + cv + '</li>';
            $('#seq_files').append($.parseHTML(elem));

            $('li[value="' + dataID + '"]').on('click', function(){
                if (retrieve_sequences.need_sequences) {
                    retrieve_sequences.get_peptides({datasetID: dataID});
                } else {
                    $('#sequence_modal').modal({show:true});
                }
            });
        });
    },

    parse_history_contents: function(data) {
        data.map(function(cv){
            var obj = {};
            if ((cv.extension === 'tabular') && !(cv.deleted)) {
                obj.datasetID = cv.id;
                obj.fileName = cv.name;
                obj.datasetURL = cv.url;
                retrieve_sequences.available_files[cv.name] = obj;
            }
        });
        
        if (retrieve_sequences.available_files.length === 0) {
            retrieve_sequences.publish('startingLongProcess', {desc: 'NB: There are no eligible datasets in your history.'});
            window.setTimeout(retrieve_sequences.clear_modal, 5000);
        } else {
            retrieve_sequences.populate_dropdown();
        }
    },

    //Attach divs to the modal div <div id="peptide_seq_list" class="modal-body">
    parse_peptide_file: function(data) {
        data.split('\n').map(function(cv){
            var div_str = '<div class="pep_seq">';
            if(cv.length > 0) {
                div_str += cv;
            }
            div_str += '</div>'
            $('#peptide_seq_list').append($.parseHTML(div_str));
        });

        retrieve_sequences.need_sequences = false;
        $('.pep_seq').on('click', function(){
            $(this).toggleClass('pep_seq_selected');
        });
        $('#sequence_modal').modal({show:true});
    },

    //AJAX back to Galaxy and get the contents of the peptide sequence file
    get_peptides: function(confObj) {
        var url = retrieve_sequences.galaxy_configuration.href + '/api/histories/' +
            retrieve_sequences.galaxy_configuration.historyID + '/contents/' +
            confObj.datasetID + '/display';
        $.get(url, retrieve_sequences.parse_peptide_file);
    },

    //AJAX back to Galaxy and get the contents of the active history
    get_datasets: function() {
        var url = retrieve_sequences.galaxy_configuration.href + '/api/histories/' +
                    retrieve_sequences.galaxy_configuration.historyID + '/contents';
        $.get(url, retrieve_sequences.parse_history_contents);
    },

    //Adds UI element to navbar
    insert_to_div: function() {
        var ui_element = '<li class="dropdown"><a id="hist_seq" href="#" class="dropdown-toggle"' +
                ' data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false"> ' +
                ' Sequences from History<span class="caret"></span></a>' +
                ' <ul id="seq_files" class="dropdown-menu" aria-labelledby="hist_seq"></ul></li> ';

        $('#' + retrieve_sequences.div_element + ' ul').append($.parseHTML(ui_element));
        $('#hist_seq').on('click', function() {
            if (Object.keys(retrieve_sequences.available_files).length === 0) {
                retrieve_sequences.get_datasets();
            }
        });
    },

    init: function(confObj) {
        retrieve_sequences.galaxy_configuration = confObj.galaxy_configuration;
        retrieve_sequences.div_element = confObj.base_div;

        //add click event to squence modal dialog.
        $('#seq_filter_btn').on('click', function() {
            var obj = {seq: []};

            $('.pep_seq_selected').map(function(cv){
                obj.seq.push($(this).text());
            });
            retrieve_sequences.publish('userSelectsSequence', obj);
            $('#sequence_modal').modal('toggle');
        });

        retrieve_sequences.insert_to_div();
    }
};/*
 Module for handling presentation of lorikeet MS/MS spectra annotated with fragment ions.
 Includes all objects needed for creation and presentation.

 Subscribed: psmRowSelected, psmRowRemoved, userChangedTable
 Publish:
 */
//basic lorikeet MS/MS model. Conform to the code library.
var lorikeet_model = function (initObj) {
    this.properties = {
        scanPKID: initObj.pkid,
        sequence: initObj.sequence,
        scanNum: initObj.acquisitionNum,
        charge: initObj.precursorCharge,
        precursorMz: initObj.precursorMZ,
        fileName: initObj.title,
        modNum: initObj.modNum,
        precursorScanNumber: initObj.precursorScanNum,
        showInternalIonOption: true,
        showMHIonOption: true,
        showAllTable: true,
        peakDetect: false,
        staticMods: [],
        variableMods: [],
        ntermMod: 0, // additional mass to be added to the n-term
        ctermMod: 0, // additional mass to be added to the c-term
        peaks: [],
        massError: 0.01,
        ms1peaks: [],
        ms1scanLabel: null,
        precursorPeaks: null,
        precursorPeakClickFn: null,
        zoomMs1: false,
        width: 750, // width of the ms/ms plot
        height: 450, // height of the ms/ms plot
        extraPeakSeries: [],
    };
    this.lorikeetPeaksQuery = 'SELECT ' +
        'p.moz, p.intensity ' +
        'FROM ' +
        'peaks p,peptideevidence pe,spectrumidentification si ' +
        'WHERE ' +
        'si.spectrum_pkid = p.spectrum_pkid AND ' +
        'pe.spectrumidentification_pkid = si.pkid AND ' +
        'si.pkid = SPECTRUM_ID_PKID LIMIT 1';
    this.lorikeetModificationsQuery = 'SELECT DISTINCT ' +
        'm.* FROM peptideevidence pe, modification m, spectrumidentification si ' +
        'WHERE ' +
        'si.pkid = SPECTRUM_ID_PKID AND ' +
        'pe.peptide_pkid = m.peptide_pkid AND ' +
        'pe.spectrumidentification_pkid = si.pkid';
    this.peaksDone = false;
    this.modsDone = false;
};

//Formats raw data returned from Galaxy.
lorikeet_model.prototype.formatAPIData = function (rawData) {
    var x = rawData.data.splice(0, 1);
    var rbv = null;
    var cNames = [];
    var i = 0;

    for (i = 0; i < x[0].length; i += 1) {
        cNames.push({
            'title': x[0][i],
            'visible': x[0][i] === 'pkid' ? false : true
        });
    }

    rbv = {
        'columns': cNames,
        'rows': rawData.data
    };
    return rbv;
};

//ajax method
lorikeet_model.prototype.executeSQL = function (confObj) {
    $.get(confObj.urlValue, function (data) {
        confObj.data = this.formatAPIData(data);
        confObj.callBackFn(confObj);
    }.bind(this));
};

//Sets peaks for either the MS2 or MS1 peaks.
lorikeet_model.prototype.setPeaks = function (confObj) {
    var moz = JSON.parse(confObj.data.rows[0][0]);
    var intensity = JSON.parse(confObj.data.rows[0][1]);
    if (confObj.mslevel === 2) {
        moz.map(function (cv, idx) {
            this.properties.peaks.push([cv, intensity[idx]]);
        }.bind(this));
    } else {
        moz.map(function (cv, idx) {
            this.properties.ms1peaks.push([cv, intensity[idx]]);
        }.bind(this));
    }
    this.peaksDone = true;
    if (this.peaksDone && this.modsDone) {
        this.callBackFn(this.properties.scanPKID);
    }
};

//Get the peaks from data provider
lorikeet_model.prototype.getPeaks = function (urlString) {
    var qry = this.lorikeetPeaksQuery;
    qry = qry.replace('SPECTRUM_ID_PKID', this.properties.scanPKID);
    urlString += qry;
    //ms2
    this.executeSQL({
        urlValue: urlString,
        mslevel: 2,
        callBackFn: this.setPeaks.bind(this),
        data: null
    });
};

lorikeet_model.prototype.setModifications = function (confObj) {
    var indexVals = {};
    var lorikeetMods = [];
    var i;

    confObj.data.columns.map(function (cv, index) {
        indexVals[cv.title] = index;
    });

    for (i = 0; i < confObj.data.rows.length; i += 1) {
        lorikeetMods.push({
            index: confObj.data.rows[i][indexVals.location],
            modMass: confObj.data.rows[i][indexVals.monoisotopicMassDelta],
            aminoAcid: confObj.data.rows[i][indexVals.residues]
        });
    }
    this.properties.variableMods = lorikeetMods;
    this.modsDone = true;
    if (this.peaksDone && this.modsDone) {
        this.callBackFn(this.properties.scanPKID);
    }
};

//determines if we have modifications present
lorikeet_model.prototype.getModifications = function (urlString) {
    var qry;
    qry = this.lorikeetModificationsQuery;
    qry = qry.replace('SPECTRUM_ID_PKID', this.properties.scanPKID);
    urlString += qry;
    this.executeSQL({
        urlValue: urlString,
        callBackFn: this.setModifications.bind(this),
        data: null
    });
};

//Method to start the full creation of lorikeet model.
lorikeet_model.prototype.buildOut = function (confObj) {
    this.callBackFn = confObj.callBackFn;
    this.urlString = confObj.urlString;

    if (this.peaksDone && this.modsDone) {
        //we already exist. Just reveal
        this.callBackFn(this.properties.scanPKID);
        return;
    }

    this.getPeaks(this.urlString);
    if (this.properties.modNum === 0) {
        this.modsDone = true;
    } else {
        this.getModifications(this.urlString);
    }
};

//======================================================================================================================
// Basic manager/factory
// MS/MS graphs will be shown on jquery tabs.
var lorikeet_manager = {

    galaxy_configuration: null,

    //stores lorikeet models as a cache.
    //Key is pkid, value is lorikeet_model instance
    models: {},

    //tracks which models are currently shown on the ui.
    visible_models: [],

    removePanel: function(panelId, tabsDiv) {
        $('li[scan="' + panelId + '"]').remove().attr("aria-controls");
        $("#" + panelId).remove();
        tabsDiv.tabs("refresh");

        //remove from visible_models
        lorikeet_manager.visible_models.length = 0;
        $('#lorikeet_panel ul li').each(function (index, value) {
            lorikeet_manager.visible_models.push(parseInt(($(this).attr('scan'))));
        });

        if ($('#lorikeet_panel ul li').length === 0) {
            $('#ms_title').removeClass('show').addClass('hidden');
        }
        lorikeet_manager.publish('spectrumRemoved', {scanId: panelId});
    },

    //Builds out the DOM with a new tab and lorikeet msms.
    //the created model object is bound to this on invocation.
    revealLorikeetMSMS: function (objScanID) {
        var modelObject = this;
        var liStr = '<li scan="' + objScanID + '"><a href="#' + objScanID + '">' + modelObject.properties.sequence + '</a>' +
            '</a><span class="ui-icon ui-icon-close" role="presentation" ' +
            'style="float: left; margin: 0.4em 0.2em 0 0; cursor: pointer;">' +
            'Remove Tab</span></li>';
        var divStr = '<div id="' + objScanID + '">';
        var tabsDiv = $("#" + lorikeet_manager.div_id);

        if ($('#lorikeet_panel ul li').length === 0) {
            //No MSMS are visible yet.
            $('#ms_title').removeClass('hidden').addClass('show');
        }

        divStr = divStr + '<div id="lorikeet' + objScanID + '"></div></div>';
        $("#" + lorikeet_manager.div_id + " ul").append($.parseHTML(liStr));
        tabsDiv.append($.parseHTML(divStr));

        //on click remove tab
        tabsDiv.tabs().delegate('span.ui-icon-close', 'click', function () {
            var panelId = $(this).closest("li").attr('scan');
            lorikeet_manager.removePanel(panelId, tabsDiv);
        });

        tabsDiv.tabs('refresh');

        $('#lorikeet' + objScanID).specview(modelObject.properties);

        tabsDiv.tabs('refresh');

        lorikeet_manager.visible_models.push(objScanID);
        lorikeet_manager.publish('longProcessFinished', {});
    },

    //peptide sequences may have span elements. Clean them
    clean_sequence: function(seq) {
        var retValue = seq;
        if (seq.indexOf('<span') > -1) {
            elem = $.parseHTML(seq);
            retValue = $(elem).text();
        }
        return retValue;
    },

    init: function (initObj) {
        var tabs, tabsDiv;
        this.galaxy_configuration = initObj.galaxy_configuration;
        this.api_value = '/api/datasets/' + this.galaxy_configuration.datasetID +
            '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        this.div_id = initObj.base_div;
        tabsDiv = $("#" + this.div_id);

        tabsDiv.append($.parseHTML('<ul></ul>'));
        tabs = tabsDiv.tabs();
        tabs.find(".ui-tabs-nav").sortable({
            axis: "x",
            stop: function () {
                tabs.tabs("refresh");
            }
        });


        //Subscriptions
        this.subscribe('psmRowSelected', function (arg) {
            if (arg.data.pkid in this.models) {
                //we can grab the cached object
                console.log("Using cached value for " + arg.data.pkid);
            } else {
                this.models[arg.data.pkid] = new lorikeet_model({
                    pkid: arg.data.pkid,
                    sequence: lorikeet_manager.clean_sequence(arg.data.sequence),
                    acquisitionNum: arg.data.acquisitionNum,
                    precursorCharge: arg.data.precursorCharge,
                    precursorMZ: arg.data.precursorMZ,
                    title: arg.data.title,
                    modNum: arg.data.modNum,
                    precursorScanNum: arg.data.precursorScanNum
                });
            }
            if (this.visible_models.indexOf(arg.data.pkid) > -1) {
                //do nothing, already showing this on screen
            } else {
                lorikeet_manager.publish('startingLongProcess', {
                    desc: 'Generating spectrum for ' + lorikeet_manager.clean_sequence(arg.data.sequence) + '.'}
                );

                //fire off the objects creation, with call back
                // of revealLorikeetMSMS
                this.models[arg.data.pkid].buildOut({
                    callBackFn: lorikeet_manager.revealLorikeetMSMS,
                    urlString: this.galaxy_configuration.href + this.api_value
                });
            }

        }.bind(this));
        this.subscribe('psmRowRemoved', function (arg) {
            var tabsDiv = $("#" + lorikeet_manager.div_id);
            lorikeet_manager.removePanel(arg.data.pkid, tabsDiv);
        });
        this.subscribe('userChangedTable', function (arg) {
            console.log('>>>>lorikeet_manager will now act on: ');
            console.log(arg);
        });
    }

};
//Module for filtering peptides based on presence of modifications
var mod_filter = {

    galaxy_configuration: null,
    ui_btn: null,
    mod_names: [],
    chosen_mods: [],

    sql_names: 'SELECT name, COUNT(name) as count FROM Modification GROUP BY name',

    fill_mod_gui: function () {
        var state_map = {
            'ACCEPT': {
                remove_class: 'label-default',
                label_class: 'label-success',
                text: 'Require'
            },
            'REQUIRE': {
                remove_class: 'label-success',
                label_class: 'label-default',
                text: 'Accept'
            }
        };
        var li_str = '';
        var mods_by_count = {};//hold modifications using count as the key.
        var mod_counts = [];
        mod_filter.mod_names.map(function (cv) {
            mods_by_count[cv.mod_count] = cv;
            mod_counts.push(cv.mod_count);
        });
        mod_counts.sort(function (a, b) {
            return a - b
        });

        //build the ui in modification count order.
        mod_counts.map(function (cv) {
            var a_mod = mods_by_count[cv];
            li_str += '<div class="col-sm-4" mod-name="' + a_mod.mod_name + '"><p class="text-left">' +
                a_mod.mod_name + ': <small><b> ' + a_mod.mod_count.toLocaleString() +
                '</b> instances.</small> <span class="label label-default">Accept</span></p></div>';
        });


        //UI appending
        $('#gui_mods').append('<div class="col-sm-12 btn-group" role="group">' +
            '<button id="mod_filter" type="button" class="btn btn-default">Filter</button>' +
            '<button id="mod_clear" type="button" class="btn btn-default">Clear</button></div>');

        $('#gui_mods').append(li_str);

        //User has chosen to filter on mods.
        //If label-default, we ignore the mod. If it comes along OK.
        //If label-success, we mandate that the mod be present in the sequence
        //For multiple label-success, a peptide MUST have all the mandated mods.
        $('#mod_filter').on('click', function () {
            var include_mods = [];
            $('#gui_mods span.label-success').map(function () {
                include_mods.push($(this).parent().parent().attr('mod-name'));
            });

            if (include_mods.length > 0) {
                mod_filter.publish('userSetModFilter', {
                    include: include_mods
                });
            } else {
                mod_filter.publish('userClearedModFilter', {});
            }
        });

        $('#mod_clear').on('click', function () {

            $('#gui_mods span.label-success').addClass('label-default');
            $('#gui_mods span.label-success').text('Accept');
            $('#gui_mods span.label-success').removeClass('label-success');
            mod_filter.publish('userClearedModFilter', {});

        });

        //Using state map cycle through the available states for a modification.
        $('#gui_mods div.col-sm-4').on('click', function () {
            var state = $(this).find('span').text().toUpperCase();
            var banner_str = '';

            $(this).find('span.label').text(state_map[state].text);
            $(this).find('span.label').removeClass(state_map[state].remove_class);
            $(this).find('span.label').addClass(state_map[state].label_class);

            //Refresh the mod banner.
            if (state_map[state].label_class === 'label-success') {
                mod_filter.chosen_mods.push($(this).attr('mod-name'))
            }
            if (state_map[state].label_class === 'label-default') {
                mod_filter.chosen_mods.splice(mod_filter.chosen_mods.indexOf($(this).attr('mod-name')), 1);
            }

            $('#mod_banner').text('');
            if (mod_filter.chosen_mods.length === 0) {
                $('#mod_banner').text('You are accepting all peptides.');
            } else {
                banner_str += 'You are requiring peptides to have ';
                mod_filter.chosen_mods.map(function (cv, idx) {
                    if (idx === 0) {
                        banner_str += ' an ' + cv + ' ';
                    } else {
                        banner_str += ' AND an ' + cv + ' ';
                    }

                });
                $('#mod_banner').text(banner_str);
            }
        });

    },

    parse_modifications: function (data) {
        data.data.map(function (cv) {
            var o = {};
            o.mod_name = cv[0]['name'];
            o.mod_count = cv[0]['count'];
            mod_filter.mod_names.push(o);
        });

        mod_filter.fill_mod_gui();
    },

    //JQuery ajax call
    execute_sql: function (confObj) {
        $.get(confObj.sql, function (data) {
            confObj.callBackFn(data);
        })
            .error(function (jqXHR) {
                console.log('Error in executing SQL : ' + jqXHR.responseText);
            });
    },

    init: function (confObj) {
        mod_filter.galaxy_configuration = confObj.galaxy_configuration;
        mod_filter.ui_btn = confObj.btn_id;

        //Get the distinct set of modification names.
        mod_filter.execute_sql({
            sql: mod_filter.galaxy_configuration.href + '/api/datasets/' +
            mod_filter.galaxy_configuration.datasetID +
            '?data_type=raw_data&provider=sqlite-dict&query=' + mod_filter.sql_names,
            callBackFn: mod_filter.parse_modifications
        });

        //enable the UI btn
        $('#' + mod_filter.ui_btn).attr({
            'data-toggle': 'collapse',
            'data-target': '#gui_mods',
            'aria-expanded': 'false',
            'aria-controls': 'collapseExample'
        });

        $('#gui_mods').append($.parseHTML('<div id="mod_banner">You are accepting all peptides.</div>'));
    }
};/**
 * The App.js module is a basic mediator pattern. It
 * will control the flow of data between various modules presented to the user.
 *
 */
var MVPApplication = (function (app) {

    app.galaxy_configuration = {};

    app.events = {};

    /**
     * Allows objects to subscribe to an event.
     * @param event name
     * @param fn call back function for event
     * @returns {subscribe}
     */
    app.subscribe = function (event, fn) {
        if (!app.events[event]) {
            app.events[event] = [];
        }
        app.events[event].push({
            context: this,
            callback: fn
        });
        return this;
    };

    /**
     * Allows objects to broadcast the occurrence of an event.
     * All subscribers to the event will have their callback functions
     * called.
     *
     * @param event name
     * @returns {*}
     */
    app.publish = function (event) {
        var args, subscription;

        if (!app.events[event]) {
            return false;
        }
        args = Array.prototype.slice.call(arguments, 1);
        app.events[event].map(function (cv) {
            subscription = cv;
            subscription.callback.apply(subscription.context, args);
        });
        return this;
    };

    /**
     * Adds the subscribe and publish functions to an object
     * @param obj
     */
    app.installTo = function (obj) {
        obj.subscribe = app.subscribe;
        obj.publish = app.publish;
    };


    app.long_process_response = function(obj) {
        if (obj.desc) {
            $('#myModal').find('.modal-header').text(obj.desc);
            $('#myModal').modal('show');
        } else {
            $('#myModal').modal('hide');
        }

    };


    app.subscribe('userSelectsSequence', function(arg) {
       console.log(arg);
    });

    /**
     * We initialize modules here. This includes setting the event subscribe and
     *   publish for each module.
     *
     * @param initObj
     */
    app.init = function (confObj) {
        this.galaxy_configuration = confObj;
        $('#data_file_name').text(confObj.dataName);

        //monitor modules starting/finishing long processes
        app.subscribe('startingLongProcess', function(arg) {
            app.long_process_response(arg);
        });

        app.subscribe('longProcessFinished', function(arg){
            app.long_process_response({});
        });

        //Module: logic for handling peptide to protein relationships
        this.installTo(protein_module);
        protein_module.init({
            galaxy_configuration: this.galaxy_configuration,
            btn_id: 'protein_acc'
        });

        //Module: hold modification information for all peptides.
        this.installTo(sequence_formatter);
        sequence_formatter.init({galaxy_configuration: this.galaxy_configuration});

        //module: data table for peptide/protein
        this.installTo(overview_table);
        overview_table.init(app.galaxy_configuration);

        //module: UI for filtering peptide/protein dataName
        this.installTo(data_filter);
        data_filter.init({
            galaxy_configuration: this.galaxy_configuration,
            domDiv: 'data_filter'
        });

        //module: UI for selecting data type
        this.installTo(available_tables);
        available_tables.init('table_selection');

        //module: PSM DataTable table
        this.installTo(detail_table);
        detail_table.init({
            base_div: 'detail_table',
            galaxy_configuration: this.galaxy_configuration
        });

        //module: PSM score filtering
        this.installTo(score_filter);
        score_filter.init({
            galaxy_configuration: this.galaxy_configuration,
            btn_id: 'peptide_score',
            base_div: 'spark_lines'
        });

        //module: Modification filtering
        this.installTo(mod_filter);
        mod_filter.init({
            galaxy_configuration: this.galaxy_configuration,
            btn_id: 'peptide_modification'
        });

        //module: Sequences from history
        this.installTo(retrieve_sequences);
        retrieve_sequences.init({
            galaxy_configuration: this.galaxy_configuration,
            base_div: 'navbar'
        });

        //module: Lorikeet Management
        this.installTo(lorikeet_manager);
        lorikeet_manager.init({
            base_div: 'lorikeet_panel',
            galaxy_configuration: this.galaxy_configuration
        });
    };

    return {
        run: function (confObj) {
            app.init(confObj);
        }
    };
}(MVPApplication || {}));
//Module for creating a DataTable overview table.
var overview_table = {
    galaxy_configuration: {},
    data_manager: null,
    ro: null,

    clean_existing_table: function () {
        $('#overview_table').empty();
    },

    //Parse filter input from user
    parse_user_input: function (inputValue) {
        var re = /[:|-|,|\s]/; //split on ',' '-' ' ', ':'
        var returnValue = [];

        if (inputValue) {
            inputValue.split(re).map(function (cv) {
                if (cv.length > 0) {
                    returnValue.push(cv);
                }
            });
        } else {
            returnValue = null;
        }
        return returnValue;
    },

    //filter presented data based on user input
    filter_data_values: function (userInput) {
        var table = $('#data_table').DataTable();
        var filterValues = this.parse_user_input(userInput);
        overview_table.ro.needCount = true;
        overview_table.ro.stringFilterObject = filterValues;
        table.draw();
    },

    //render the DataTable table
    render_table: function (confObj) {
        var ot;
        this.ro = new RequestObject();

        overview_table.clean_existing_table();
        //Create a data manager for this newly rendered table
        overview_table.data_manager = new DataManager({
            href: overview_table.galaxy_configuration.href,
            dataSetID: overview_table.galaxy_configuration.datasetID,
            historyID: overview_table.galaxy_configuration.historyID,
            tableRowCount: overview_table.galaxy_configuration.tableRowCount,
            tableColumns: overview_table.galaxy_configuration.tableColumns
        });

        this.ro.score_fields = app_utils.remove_array_values(app_utils.ignore_fields, overview_table.galaxy_configuration.tableColumns.Score);
        this.ro.tableName = confObj.type;

        $('#overview_table').append($.parseHTML(
            '<table class="table table-striped table-bordered" id="data_table"></table>'
        ));
        $('#data_table').DataTable({
            //lftrp
            dom: 'Blftrip',
            buttons: [
                'csvHtml5',
                {
                    text: 'Reset Table',
                    action: function () {
                        overview_table.publish('userResetTable', null);
                        overview_table.render_table({type: overview_table.ro.tableName});
                    }
                },
                {
                    extend: 'collection',
                    text: 'Show columns',
                    buttons: ['columnsVisibility'],
                    visibility: true
                }
            ],
            select: true,
            searching: false,
            scrollX: '100%',
            processing: true,
            serverSide: true,
            ajax: function (data, callback, settings) {
                overview_table.data_manager.ajaxDataProvider(data, settings,
                    overview_table.ro, callback);
            },
            columns: this.ro.generateColumnNames(),
            colReorder: true,
            initComplete: function (settings) {
                var api = new $.fn.dataTable.Api(settings);
                var cleaned_strings = [];
                api.columns().dataSrc().map(function (cv) {
                    cleaned_strings.push(cv.replace(/['"]+/g, '')); //TODO: refactor duplication
                });
                overview_table.publish('columnVisbilityChanged', {visibleColumns: cleaned_strings});
            }
        });

        ot = $('#data_table').DataTable();
        ot.on('select', function (e, dt, type, indexes) {
            if (type === 'row') {
                overview_table.publish('overviewRowSelected', {
                    type: overview_table.ro.tableName,
                    data: dt.data()
                });
            }
        });
        ot.on('deselect', function (e, dt, type, indexes) {
            if (type === 'row') {

            }
        });
        //Publish column visibility changes.
        ot.on('column-visibility.dt', function (e, settings, column, state) {
            var col_names = []; //all column names
            var visible_names = []; //visible columns

            ot.columns().dataSrc().map(function (cv) {
                col_names.push(cv.replace(/['"]+/g, ''));
            });

            ot.columns().visible().map(function (cv, idx) {
                if (cv === true) {
                    visible_names.push(col_names[idx]);
                }
            });

            overview_table.publish('columnVisbilityChanged', {visibleColumns: visible_names});
        });
    },

    //User has set filtering based on score(s),
    // now create filter, query and redraw table
    filter_by_score: function (scoreObj) {
        var table = $('#data_table').DataTable();
        overview_table.ro.scoreFilterObject = scoreObj;
        overview_table.ro.needCount = true;
        table.draw();
    },

    clear_score_filter: function () {
        var table = $('#data_table').DataTable();
        overview_table.ro.stringFilterObject = null;
        overview_table.ro.needCount = true;
        table.draw();
    },

    filter_by_modifications: function (modObj) {
        var table = $('#data_table').DataTable();
        overview_table.ro.modificationFilterObject = modObj;
        overview_table.ro.needCount = true;
        table.draw();
    },

    clear_modification_filter: function() {
        var table = $('#data_table').DataTable();
        overview_table.ro.modificationFilterObject = null;
        overview_table.ro.needCount = true;
        table.draw();
    },

    filter_on_accession: function (obj) {
        var table = $('#data_table').DataTable();
        overview_table.ro.accessionFilter = obj.accession;
        overview_table.ro.needCount = true;
        table.draw();
    },

    //Basic initialization of the overview table module
    init: function (confObj) {
        overview_table.subscribe('userChangedTable', function (arg) {
            overview_table.render_table({
                type: arg
            });
        });
        overview_table.subscribe('userSelectedAccession', function(arg){
            overview_table.filter_on_accession(arg);
        })
        overview_table.subscribe('userSelectedFilter', function (arg) {
            overview_table.filter_data_values(arg);
        });
        overview_table.subscribe('userClearedFilter', function (arg) {
            overview_table.clear_score_filter();
        });
        overview_table.subscribe('filterScoreWith', function (arg) {
            overview_table.filter_by_score(arg);
        });
        overview_table.subscribe('clearScoreFilter', function (arg) {
            overview_table.clear_score_filter();
        });

        overview_table.subscribe('userSetModFilter', function (arg) {
            overview_table.filter_by_modifications(arg);
        });

        overview_table.subscribe('userClearedModFilter', function (arg){
            overview_table.clear_modification_filter();
        });

        overview_table.galaxy_configuration = confObj;
    }
};
//Covers functionality in associating peptides to proteins
var protein_module = {

    galaxy_config: null,

    proteins: {}, //Keyed by accession

    peptide_positions: {}, //Used if protein sequence is not available

    peptide_start_end: function (obj) {
        var sql = 'SELECT Peptide.sequence, pe.start, pe.end FROM PeptideEvidence pe, Peptide WHERE ' +
            'Peptide.sequence IN (<SEQ>) AND pe.peptide_pkid = peptide.pkid';
        var url_value = protein_module.galaxy_configuration.href + '/api/datasets/' +
            protein_module.galaxy_configuration.datasetID + '?data_type=raw_data&provider=sqlite-dict&query=';
        var seq_str = '';
        var coverage = obj;

        coverage.map(function (cv, idx) {
            if (idx > 0) {
                seq_str += ',';
            }
            seq_str += '"' + cv.pep_seq + '"';
        });

        sql = sql.replace('<SEQ>', seq_str);

        $.get({
            url: url_value + sql,
            success: function (data) {
                data.data.map(function (cv) {
                    var val = cv[0];
                    protein_module.peptide_positions[val.sequence] = {
                        start: parseInt(val.start),
                        end: parseInt(val.end)
                    }
                });
                protein_module.format_unkown_sequence(coverage);
            }
        });
    },


    //Build a coverage map for an unknown protein sequence, then publish on completion.
    format_unkown_sequence: function (coverage) {
        var elem_string = '<div>';
        var coverage_by_start = {};
        var pos_array = [];

        coverage.map(function (cv) {
            var start_pos = protein_module.peptide_positions[cv.pep_seq].start;

            coverage_by_start[start_pos] = '<div>XXX <span class="glyphicon glyphicon-scissors" aria-hidden="true"></span> position ' + start_pos +
                ' <span class="pep-cov">' + cv.pep_seq + '</span> (<span class="pep-cov">' + cv.count + '</span> times) position ' +
                protein_module.peptide_positions[cv.pep_seq].end + ' <span class="glyphicon glyphicon-scissors" aria-hidden="true"> XXX</div>';
        });

        Object.keys(coverage_by_start).map(function (cv) {
            pos_array.push(parseInt(cv));
        });

        pos_array.sort(function (a, b) {
            return a - b;
        });

        pos_array.map(function (cv) {
            elem_string += coverage_by_start[cv];
        });

        elem_string += '</div>';
        protein_module.publish('coverageForUnknownProt', {value: elem_string});
    },

    format_peptide_coverage: function (obj) {
        var f_string = obj.sequence;
        var max_count = 0;
        var i;
        var elem_string = '';
        var fake_sequence = f_string.startsWith('NA');
        var peptide_seqs = [];
        var modded;

        if (fake_sequence) {
            this.peptide_start_end(obj.coverage);
            //Will NOT return here AJAX call.
        }

        obj.coverage.map(function (cv) {
            var o = {};
            if (cv.count > max_count) {
                max_count = cv.count;
            }
            o.pkid = cv.pkid;
            o.sequence = cv.sequence;
            peptide_seqs.push(o);
        });

        modded = sequence_formatter.formatted_sequences(peptide_seqs)

        for (i = 1; i <= max_count; i = i + 1) {
            var seq_str = f_string;
            obj.coverage.map(function (cv) {
                var spanned = '<span class="pep-cov">' + cv.pep_seq + '</span>';

                if (i > cv.count) {
                    spanned = spanned.replace('pep-cov', 'pep-cov-hide');
                    seq_str = seq_str.replace(cv.pep_seq, spanned);
                } else {
                    if (cv.pep_seq != modded[cv.pep_seq]) {
                        seq_str = seq_str.replace(cv.pep_seq, '<span title="Modified Peptide" class="pep-cov general_mod"><em>' + cv.pep_seq + '</em></span>');
                    } else {
                        seq_str = seq_str.replace(cv.pep_seq, spanned);
                    }
                }
            });
            if (i > 1) {
                elem_string += '<div><span class="inv">' + seq_str + '</span></div>';
            } else {
                elem_string += '<div>' + seq_str + '</div>';
            }
        }


        return elem_string;
    },

    //Fill the $('#protein_gui') element with selected protein
    render_protein: function (obj) {
        var prot_elem = '';
        var total_pep_count = 0;

        obj.coverage.map(function (cv) {
                total_pep_count += cv.count;
            }
        );

        $('#protein_gui').addClass('jumbotron');

        prot_elem += '<h4>' + obj.accession + '</h4>';
        if (protein_module.proteins[obj.accession].desc) {
            prot_elem += '<h5>' + protein_module.proteins[obj.accession].desc + '</h5>';
        }
        if (obj.coverage.length > 0) {
            prot_elem += '<div id="p_sequence" class="prot-sequence">' + protein_module.format_peptide_coverage(
                    {
                        sequence: protein_module.proteins[obj.accession].sequence,
                        pkid: obj.pkid,
                        coverage: obj.coverage,
                        total_count: total_pep_count
                    }
                ) + '</div>';
        } else {
            prot_elem += '<div id="p_sequence" class="prot-sequence">' + protein_module.proteins[obj.accession].sequence + '</div>';
        }

        $('#protein_gui').append($.parseHTML(prot_elem));

    },

    present_coverage: function (obj) {
        var cov_sql = 'SELECT Peptide.sequence, Peptide.pkid ,Count(Peptide.pkid) AS coverage FROM peptide, peptideevidence pe, DBSequence dbs ' +
            'WHERE pe.dbsequence_pkid = dbs.pkid AND pe.peptide_pkid = peptide.pkid AND ' +
            'dbs.accession = "' + obj.accession + '" GROUP BY Peptide.pkid ORDER BY Peptide.sequence';

        var url_value = protein_module.galaxy_configuration.href + '/api/datasets/' +
            protein_module.galaxy_configuration.datasetID + '?data_type=raw_data&provider=sqlite-dict&query=';

        url_value += cov_sql;

        if (protein_module.proteins[obj.accession].sequence) {
            //we have a sequence, so get coverage from db
            $.get(url_value, function (data) {
                var p_cov = {};
                p_cov.accession = obj.accession;
                p_cov.sequence = protein_module.proteins[obj.accession].sequence;
                p_cov.coverage = [];
                data.data.map(function (cv) {
                    var obj = {};
                    var val = cv[0];
                    obj.pep_seq = val.sequence;
                    obj.pkid = val.pkid;
                    obj.count = val.coverage;
                    p_cov.coverage.push(obj);
                });
                protein_module.render_protein(p_cov);
            }.bind(this));
        } else {
            //no sequence, skip query
            protein_module.render_protein(obj);
        }
    },

    init: function (confObj) {

        protein_module.galaxy_configuration = confObj.galaxy_configuration;
        protein_module.ui_btn = confObj.btn_id;

        //enable the UI btn
        $('#' + protein_module.ui_btn).attr({
            'data-toggle': 'collapse',
            'data-target': '#protein_filter',
            'aria-expanded': 'false',
            'aria-controls': 'collapseExample'
        });

        //Enable autocomplete via jquery-ui
        $("#protein_accession").autocomplete({
            minLength: 3,
            source: function (request, response) {
                $("#protein_filter button").removeClass('btn-success');
                $("#protein_filter button").removeClass('btn-danger');
                $("#p_desc").text('');
                $.ajax({
                    type: 'GET',
                    datatype: 'json',
                    url: protein_module.galaxy_configuration.href + '/api/datasets/' +
                    protein_module.galaxy_configuration.datasetID +
                    '?data_type=raw_data&provider=sqlite-dict&query=' +
                    'SELECT accession, description, sequence, length FROM DBSequence WHERE accession ' +
                    'LIKE %22%25' + request.term + '%25%22',

                    success: function (data) {
                        var return_data = [];
                        var i;
                        data.data.map(function (cv) {
                            var val = cv[0];
                            var obj = {}
                            if (val.sequence) {
                                obj.sequence = val.sequence;
                            } else if (val.length) {
                                obj.sequence = 'NA:' + val.length;
                            } else {
                                obj.sequence = 'NA';
                            }
                            obj.item = val.accession;
                            obj.label = val.accession;
                            obj.desc = val.description;
                            return_data.push(obj);
                            protein_module.proteins[obj.item] = obj;
                        })
                        response(return_data);

                    },
                    error: function (data) {
                        $("#protein_filter button").addClass('btn-danger');
                        console.log('Error on autocomplete SQL');
                    }
                });
            },
            focus: function (event, ui) {
                $("#protein_accession").val(ui.item.label);
                return false;
            },
            select: function (event, ui) {
                $("#protein_filter button").addClass('btn-success');
                $("#protein_accession").val(ui.item.label);
                $("#p_desc").text(ui.item.desc);
                return false;
            }
        })
            .autocomplete("instance")._renderItem = function (ul, item) {
            return $('<li class="p_accession">')
                .append("<a>" + item.label + "<br>" + item.desc + "</a>")
                .appendTo(ul);
        };
        $("#protein_filter button").on('click', function () {
            if ($(this).hasClass('btn-success')) {
                protein_module.publish('userSelectedAccession', {
                    accession: $("#protein_accession").val()
                });
                protein_module.present_coverage({accession: $("#protein_accession").val()});
            }
        });

        protein_module.subscribe('userResetTable', function (arg) {
            $("#protein_filter button").removeClass('btn-success');
            $("#protein_accession").val('');
            $("#p_desc").text('');
            $('#protein_gui').removeClass('jumbotron');
            $('#protein_gui').empty();
        });

        protein_module.subscribe('coverageForUnknownProt', function (arg) {
            $('#p_sequence').empty();
            $('#p_sequence').append($.parseHTML(arg.value));
        }); //{value: str}

    }

};/**
 * Module for presenting and handling score filtering
 * in the UI
 *
 * Subscribe: userResetTable
 *
 * Publish: clearScoreFilter: {}, filterScoreWith: {'filter values'}
 *
 */
var score_filter = {

    where_values: {},

    ignore_fields: [
        'pkid',
        'spectrum_identification_id',
        'SpectrumIdentification_pkid'],

    galaxy_configuration: null,

    //Each score is graphed as a spark line.
    sparkline_width: 500,
    sparkline_height: 60,

    //Build and returns a D3 SVG
    // 1) Line for the score values
    // 2) brush for selecting the values.
    generate_svg: function (initObj) {
        var div_id = initObj.base_div;
        var w = initObj.width;
        var h = initObj.height;
        var dataset = initObj.dataset;
        var low_element = initObj.low_element;
        var high_element = initObj.high_element;
        var score_name = initObj.score_name;

        dataset.sort(function (a, b) {
            return a - b;
        });
        var x = d3.scale.linear()
            //.domain([0, dataset.length - 1])
            .domain([0, dataset.length])
            .range([0, w]);

        var y = d3.scale.linear()
            .domain([d3.min(dataset), d3.max(dataset)])
            .range([h, 0]);

        var line = d3.svg.line()
            .x(function (d, i) {
                return x(i);
            })
            .y(function (d) {
                return y(d);
            });

        var svg = d3.select('#' + div_id)
            .append('svg:svg')
            .attr('width', w)
            .attr('height', h)
            .attr("class", "score-svg-component")
            .append('svg:g');

        svg.append("svg:path").attr('d', line(dataset));

        var brush = d3.svg.brush()
            .x(x)
            .extent([dataset.length * .80, dataset.length * .90]) // initial brush position is at 80 - 90% of the data set.
            .on("brushstart", brushstart)
            .on("brush", brushmove)
            .on("brushend", brushend);
        var brushg = svg.append("g")
            .attr("class", "brush")
            .call(brush);
        brushg.selectAll(".resize").append("path")
            .attr("transform", "translate(0," + h / 2 + ")");

        brushg.selectAll("rect")
            .attr("height", h);
        brushstart();
        brushmove();
        function brushstart() {
            svg.classed("selecting", true);
        }

        function brushmove() {
            var data_slice = dataset.slice(brush.extent()[0], brush.extent()[1]);
            $('#' + low_element).text(data_slice[0]);
            $('#' + high_element).text(data_slice.pop());
        }

        function brushend() {
            var data_slice = dataset.slice(brush.extent()[0], brush.extent()[1]);
            var score_span = $('span[name*="' + score_name + '"]');
            score_filter.where_values[score_name] = {'MIN': data_slice[0], 'MAX': data_slice.pop()}
            score_filter.publish('filterScoreWith', new ScoreFilterObject(score_filter.where_values));
            score_span.removeClass('glyphicon-ban-circle');
            score_span.addClass('glyphicon-ok-circle');
        }

        return svg;
    },

    //Tidy up of returned data.
    parse_score_data: function (data) {
        var field_names = data.data[0];
        var obj = {};
        field_names.map(function (cv) {
            obj[cv] = []
        });
        //the rest of the data array
        data.data.slice(1).map(function (cv) {
            //cv is now a single array of data values
            cv.map(function (cv, idx) {
                if (cv === null && typeof cv === "object") {
                    obj[field_names[idx]].push(0);
                } else {
                    obj[field_names[idx]].push(parseFloat(cv));
                }
            });
        });
        score_filter.scores_by_field = obj;
    },

    //need to know what type a score is. Usually it's a real, but there are text fields as well.
    //Can be INTEGER, REAL or TEXT
    parse_score_types: function (sqlResult) {
        var re = /CREATE\s*TABLE\s*Score\s*\((.*)\)/;
        var str = sqlResult.data[1][0].replace(re, "$1");
        var fields = str.split(',');
        var base_sql = 'SELECT ';

        score_filter.score_fields.map(function (cv) {
            fields.map(function (f_cv) {
                if (f_cv.indexOf('[' + cv + ']') > -1) {
                    score_filter.field_types[cv] = 'NA';
                    if (f_cv.indexOf('REAL') > -1) {
                        score_filter.field_types[cv] = 'REAL';
                    }
                    if (f_cv.indexOf('INTEGER') > -1) {
                        score_filter.field_types[cv] = 'INTEGER';
                    }
                    if (f_cv.indexOf('TEXT') > -1) {
                        score_filter.field_types[cv] = 'TEXT'
                    }
                }
            })
        });

        //now we can fetch the scores for REAL and INTEGER types
        //build SQL
        score_filter.score_fields.map(function (cv, idx) {
            if (score_filter.field_types[cv] === 'TEXT') {
                //do nothing
            } else {
                if (idx > 0) {
                    base_sql = base_sql + ', '
                }
                base_sql = base_sql + 'Score."' + cv + '" ';
            }
        });
        base_sql = base_sql + ' FROM Score';

        //Fetch the score types from data provider.
        score_filter.execute_sql({
            sql: score_filter.galaxy_configuration.href + '/api/datasets/' +
            score_filter.galaxy_configuration.datasetID +
            '?data_type=raw_data&provider=sqlite-table&headers=True&query=' +
            base_sql,
            callBackFn: score_filter.parse_score_data
        });

    },

    //Used to query the scores
    execute_sql: function (confObj) {
        $.get(confObj.sql, function (data) {
                confObj.callBackFn(data);
            })
            .error(function (jqXHR) {
                console.log('Error in executing SQL : ' + jqXHR.responseText);
            });
    },

    //handles the build up of all SVGs, places them into the
    //base div
    render_filter_group: function () {

        //Only present score SVGs if user is showing the score column in the table.

        //TODO: generalize and place in utils.js
        var visible_scores = Object.keys(score_filter.scores_by_field).filter(function(n) {
            return score_filter.visible_scores.indexOf(n) != -1;
        });

        //Object.keys(score_filter.scores_by_field).map(function (cv, idx) {
        visible_scores.map(function(cv, idx){
            var initObj = {};

            initObj.width = score_filter.sparkline_width;
            initObj.height = score_filter.sparkline_height;
            initObj.dataset = score_filter.scores_by_field[cv];
            initObj.low_element = 'score_' + idx + '_low_element';
            initObj.high_element = 'score_' + idx + '_high_element';
            initObj.base_div = 'score_' + idx;
            initObj.score_name = cv;

            $('#svg_elements').append($.parseHTML('<div class="col-sm-6 lead"><span name="' + cv + '" class="glyphicon glyphicon-ban-circle" aria-hidden="true"></span>' + cv + ': <span class="low_score small" id="' +
                initObj.low_element + '"></span> to <span class="high_score small" id="' + initObj.high_element +
                '"></span><div id="' + initObj.base_div + '"></div></div>'));

            //Add click callback to turn filtering off
            $('span[name*="' + cv + '"]').on('click', function (evt) {
                if ($(this).hasClass('glyphicon-ok-circle')) {
                    $(this).removeClass('glyphicon-ok-circle');
                    $(this).addClass('glyphicon-ban-circle');
                }

                delete(score_filter.where_values[$(this).attr('name')]);
                if (Object.keys(score_filter.where_values).length > 0) {
                    //user still has an active where filter
                    score_filter.publish('filterScoreWith', new ScoreFilterObject(score_filter.where_values));
                } else {
                    //user has removed all where clauses.
                    score_filter.publish('clearScoreFilter', null);
                }

            });

            score_filter.generate_svg(initObj);

        });
        score_filter.publish('longProcessFinished', {});
    },

    init: function (confObj) {
        score_filter.galaxy_configuration = confObj.galaxy_configuration;
        score_filter.div_element = confObj.base_div;
        score_filter.ui_btn = confObj.btn_id;
        score_filter.score_fields = app_utils.remove_array_values(this.ignore_fields, this.galaxy_configuration.tableColumns.Score);
        score_filter.field_types = {};

        //Need to know what types the scores are. Some are REAL some TEXT
        score_filter.execute_sql({
            sql: score_filter.galaxy_configuration.href + '/api/datasets/' +
            score_filter.galaxy_configuration.datasetID +
            '?data_type=raw_data&provider=sqlite-table&headers=True&query=' +
            'SELECT sql FROM sqlite_master WHERE name = "Score"',
            callBackFn: score_filter.parse_score_types
        });

        //enable the UI btn
        $('#' + score_filter.ui_btn).attr({
            'data-toggle': "collapse",
            'data-target': "#spark_lines",
            'aria-expanded': "false",
            'aria-controls': "collapseExample"});


        $('#' + score_filter.div_element).on('show.bs.collapse', function () {
            score_filter.publish('startingLongProcess', {desc: 'Generating score filters.'});
        });

        $('#' + score_filter.div_element).on('shown.bs.collapse', function () {

            if ($('#svg_elements').children().length > 0) {
                score_filter.publish('longProcessFinished', {});
            } else {
                score_filter.render_filter_group();
            }

        });
        $('#' + score_filter.div_element).on('hide.bs.collapse', function () {

        });

        score_filter.subscribe('columnVisbilityChanged', function(arg){
            score_filter.visible_scores = arg.visibleColumns;

            if ($('#svg_elements').children().length > 0) {
                //user has changed visibility after filters have been rendered.
                score_filter.publish('startingLongProcess', {desc: 'Generating score filters.'});
                //clear existing scores
                $('#svg_elements').empty();
                //render anew.
                score_filter.render_filter_group();
            }

        });

        score_filter.subscribe('userResetTable', function (arg) {
            //User is clearing the current state of the page. Clear the state of the filters.
            score_filter.where_values = {};
            if ($('#data_filter .btn-primary').attr('aria-expanded') === 'true') {
                $('#data_filter .btn-primary').click();
            }
            $('.glyphicon-ok-circle').map(function () {
                $(this).removeClass('glyphicon-ok-circle');
                $(this).addClass('glyphicon-ban-circle');
            });

        });
    }


};/**
 * Module for presenting and handling score filtering
 * in the UI
 *
 * Subscribe: overviewRowSelected
 *
 * Publish: 'scoreFilterInvoked', 'scoreFilterCleared'
 *
 */
//TODO: Deprecated. remove.
var DEPscore_filter = {

    ignore_fields: [
        'pkid',
        'spectrum_identification_id',
        'SpectrumIdentification_pkid'],

    galaxy_configuration: null,

    //Selects the input fields and builds a data structure of filter values
    //If user has actually entered values, publishes scoreFilterInvoked with object of values.
    build_filter: function () {
        var filter_object = {};

        $('.s_filter').map(function () {
            var name_array;
            if ($(this).val()) {
                name_array = $(this).attr('name').split('::');
                if (!(name_array[1] in filter_object)) {
                    filter_object[name_array[1]] = {};
                }
                filter_object[name_array[1]][name_array[0]] = $(this).val();
            }
        });
        if (Object.keys(filter_object).length > 0) {
            var sf = new ScoreFilterObject(filter_object);
            score_filter.publish('scoreFilterInvoked', sf);
        } else {
            console.log('User is filtering on nothing.');
        }

    },

    clear_filter: function () {
        $('.s_filter').map(function () {
            $(this).val('');
        });

        score_filter.publish('scoreFilterCleared', {});
    },

    render_score_grid: function (argObj) {
        var domStr = '';
        var unBalanced = false;
        var baseDiv = $('#' + score_filter.div_element);
        //empty existing score filter.
        baseDiv.empty();

        //for each field in the score table, create a compound DOM element with min max input fields
        score_filter.score_fields.map(function (cv, idx) {
            if ((idx % 2) === 0) {
                domStr = domStr + '<div class="row">';
                ubBalanced = true;
            }
            domStr = domStr + '<div class="col-sm-6 score-filter">';
            domStr = domStr + cv;
            domStr = domStr + '<div class="row"><div class="col-sm-6">';

            if (score_filter.field_types[cv] === 'TEXT') {
                domStr = domStr + '<input class="s_filter" type="text" placeholder="Search for Text" name="TEXT::' + cv + '"></div>';
            } else {
                domStr = domStr + '<input class="s_filter" type="number" placeholder="Min Value to Show" name="MIN::' + cv + '" step="any"></div>' +
                    '<div class="col-sm-6">' +
                    '<input type="number" class="s_filter" placeholder="Max Value to Show" name="MAX::' + cv + '" step="any"></div>';
            }

            domStr = domStr + '</div></div>';

            if ((idx % 2) != 0) {
                domStr = domStr + '</div>';
                ubBalanced = false;
            }
        });
        if (unBalanced) {
            domStr = domStr + '</div>';
        }

        baseDiv.append($.parseHTML('<h3>Score Filtering</h3>'));
        baseDiv.append($.parseHTML('<button class="btn btn-primary msi_button" type="button" data-toggle="collapse" ' +
            'data-target="#collapse_div" aria-expanded="false" aria-controls="collapseExample">Toggle Filter</button>'));

        baseDiv.append($.parseHTML('<div class="collapse" id="collapse_div"></div>'));

        $('#collapse_div').append($.parseHTML('<button class="btn btn-default" type="submit" id="filter_now">Filter</button>'));
        $('#collapse_div').append($.parseHTML('<button class="btn btn-default" type="submit" id="clear_all">Clear All</button>'));
        $('#collapse_div').append($.parseHTML(domStr));

        $('#filter_now').on('click', score_filter.build_filter);
        $('#clear_all').on('click', score_filter.clear_filter);

    },

    //need to know what type a score is. Usually it's a real, but there are text fields as well.
    //Can be INTEGER, REAL or TEXT
    parseScoreTypes: function (sqlResult) {
        var re = /CREATE\s*TABLE\s*Score\s*\((.*)\)/;
        var str = sqlResult.data[1][0].replace(re, "$1");
        var fields = str.split(',');

        score_filter.score_fields.map(function (cv) {
            fields.map(function (f_cv) {
                if (f_cv.indexOf('[' + cv + ']') > -1) {
                    score_filter.field_types[cv] = 'NA';
                    if (f_cv.indexOf('REAL') > -1) {
                        score_filter.field_types[cv] = 'REAL';
                    }
                    if (f_cv.indexOf('INTEGER') > -1) {
                        score_filter.field_types[cv] = 'INTEGER';
                    }
                    if (f_cv.indexOf('TEXT') > -1) {
                        score_filter.field_types[cv] = 'TEXT'
                    }
                }
            })
        });

        console.log(score_filter.field_types);

    },

    executeSQL: function (confObj) {
        $.get(confObj.sql, function (data) {
                confObj.callBackFn(data);
            })
            .error(function (jqXHR) {
                console.log('Error in executing SQL : ' + jqXHR.responseText);
            });
    },

    init: function (confObj) {
        score_filter.galaxy_configuration = confObj.galaxy_configuration;
        score_filter.div_element = confObj.base_div;
        score_filter.score_fields = app_utils.remove_array_values(this.ignore_fields, this.galaxy_configuration.tableColumns.Score);
        score_filter.field_types = {};

        //Need to know what types the scores are. Some are REAL some TEXT
        score_filter.executeSQL({
            sql: score_filter.galaxy_configuration.href + '/api/datasets/' +
            score_filter.galaxy_configuration.datasetID +
            '?data_type=raw_data&provider=sqlite-table&headers=True&query=' +
            'SELECT sql FROM sqlite_master WHERE name = "Score"',
            callBackFn: score_filter.parseScoreTypes
        });

        //Subscribe
        score_filter.subscribe('overviewRowSelected', function (arg) {
            console.log('score_filter heard something, rendering score grid');
            score_filter.render_score_grid(arg);
        });
    }
};/**
 * Module for holding peptide modification information.
 * Will provide formatted HTML strings
 *
 * The msi.css file holds the formatting for known modifications.
 *
 */
var sequence_formatter = {

    galaxy_congalaxy_configuration: null,
    sql_text: 'SELECT p.pkid, m.Peptide_pkid, p.sequence, p.modnum, m.Peptide_pkid, m.location, m.residues, m.name ' +
    'FROM Modification m, Peptide p WHERE p.pkid = m.Peptide_pkid',

    mods_by_sequence: {},

    parse_data: function (data) {
        data.data.map(function (cv) {
            var mod = {};
            var obj = cv[0];
            if (!(sequence_formatter.mods_by_sequence.hasOwnProperty(obj.pkid))) {
                sequence_formatter.mods_by_sequence[obj.pkid] = [];
            }
            mod.residue = obj.residues;
            mod.location = obj.location > 0 ? obj.location - 1 : 0;
            mod.name = obj.name;
            mod.pep_sequence = obj.sequence;
            sequence_formatter.mods_by_sequence[obj.pkid].push(mod);
        });
        console.log('Parsing of modifications is complete.');
    },

    //JQuery ajax call
    execute_sql: function (confObj) {
        $.get(confObj.sql, function (data) {
                confObj.callBackFn(data);
            })
            .error(function (jqXHR) {
                console.log('Error in executing SQL : ' + jqXHR.responseText);
            });
    },

    /**
     *
     * @param lstSequences - array of peptide sequences
     * @returns {{}} Dictionary with peptide sequence as key,
     *  formatted HTML with modifications as value. If sequence does
     *  not have a modification, returns the plain sequence as value.
     */
    formatted_sequences: function (lstSequences) {
        var returnValue = {};

        lstSequences.map(function (cv) {
                var spans = {};
                var locations = [];
                var formatted_str = '';
                var this_seq = cv.sequence;
                var s_obj = {};
                var mod_seq;

                if (sequence_formatter.mods_by_sequence[cv.pkid]) {
                    returnValue[cv.pkid] = []; //store substrings, they'll be stiched back together.
                    mod_seq = this_seq;
                    s_obj.value = this_seq;
                    sequence_formatter.mods_by_sequence[cv.pkid].map(function (obj) {
                        var aa = obj.residue ? obj.residue : s_obj.value[obj.location];
                        //build span strings per modification
                        var s = '<span title="' + obj.name + '" class="baseMod ' + obj.name.toLowerCase() + '">' + aa + '</span>';
                        spans[obj.location] = s;
                    });

                    Object.keys(spans).map(function(cv){
                        locations.push(parseInt(cv));
                    });

                    locations.sort(function(a,b){return a-b});

                    locations.map(function(cv){
                        mod_seq = mod_seq.substr(0, cv) + cv + mod_seq.substr(cv + 1);
                    });

                    locations.map(function (cv) {
                        var nloc = parseInt(cv);
                        mod_seq = mod_seq.replace(cv, spans[nloc]);
                    });
                    returnValue[cv.pkid] = mod_seq;

                } else {
                    //sequence does not have a modification
                    returnValue[cv.pkid] = this_seq;
                }
            }
        );

        return returnValue;
    },

    init: function (confObj) {
        sequence_formatter.galaxy_configuration = confObj.galaxy_configuration;

        //Get the distinct set of modification names.
        sequence_formatter.execute_sql({
            sql: sequence_formatter.galaxy_configuration.href + '/api/datasets/' +
            sequence_formatter.galaxy_configuration.datasetID +
            '?data_type=raw_data&provider=sqlite-dict&query=' + sequence_formatter.sql_text,
            callBackFn: sequence_formatter.parse_data
        });

        sequence_formatter.subscribe('formatSequencesForList', function (arg) {
            var rt = sequence_formatter.formatted_sequences(arg.sequences);
            sequence_formatter.publish('formattedSequences', {formatted_sequences: rt});
        });
    }
};/**
 * Holds utility functions I may need
 **/

var app_utils = {

    ignore_fields: [
        'pkid',
        'spectrum_identification_id',
        'SpectrumIdentification_pkid'],

    string_of_char: function(length, char) {
        var return_val = '';
        var i;

        for (i = 0; i < length; i = i + 1) {
            return_val += char;
        }

        return return_val;
    },

    /**
     * Removes the values found in arrExclude from arrFrom.
     * Does not alter inputs.
     *
     * @param arrExclude
     * @param arrFrom
     * @returns {Blob|ArrayBuffer|Array.<T>|string|*}
     */
    remove_array_values: function(arrExclude, arrFrom) {
        var returnArray = arrFrom.slice(0);
        arrExclude.map(function(cv){
            var idx = returnArray.indexOf(cv);
            if (idx > -1) {
                returnArray.splice(idx,1);
            }
        });
        return returnArray;
    },

};