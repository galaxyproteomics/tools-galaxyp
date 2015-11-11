/**
 * Functions for accessing Galaxy history.
 *
 * Primarily to read user spevified datasets.
 */
var GalaxyHistoryReader = (function(ghr) {
  var historyID;
  var href;

  return {
    configure: function(confObj) {
      this.historyID = confObj.historyID;
    }
  };
}(GalaxyHistoryReader || {}));

var ConfigurationObject = function() {
  this.href = ''; //href': 'http://localhost:8080',
  this.tableRowCount = {}; //row counts for each table, from the data set
  this.tableColumns = {}; //columns found in each table, from the data set
  this.dataSetID = ''; //'datasetID': '55504e7a2466a2e3',
};

var SQLDataViewer = (function(sdv) {
  sdv.dataTables = ['psmDT', 'overviewDT'];
  sdv.gridsToClear = ['#psmDataTable', '#overviewDataTable',
    '#overviewDataTableFilters', '#psmScoreFilters',
    '#psmDataTableFilters'
  ];
  sdv.dataGrids = {
    PSM: {
      grid: 'psmDataTable',
      table: 'psmDT'
    },
    Proteins: {
      grid: 'overviewDataTable',
      table: 'overviewDT'
    },
    Peptides: {
      grid: 'overviewDataTable',
      table: 'overviewDT'
    }
  };

  sdv.detailRequestObject = null;
  sdv.overviewRequestObject = null;

  sdv.tablesExist = function() {
    var retValue = false;
    SQLDataViewer.dataTables.map(function(cv) {
      if ($.fn.DataTable.isDataTable($('#' + cv))) {
        retValue = true;
      }
    });

    return retValue;
  };

  sdv.cleanTables = function() {
    if (SQLDataViewer.tablesExist()) {
      SQLDataViewer.gridsToClear.map(function(cv) {
        $(cv).empty();
      });
    }
  };

  /**
   * Varying functions for users selecting a table row.
   * Select a protein or peptide, we will show you all the PSMs derived from that prot/pep.
   * Select a PSM, we will generate a Lorikeet graph.
   */
  sdv.rowSelectionFunctions = function(dataTableName) {
    var funcs = {
      prep: {
        psmDT: function(t) {
          $(t).toggleClass('selected');
        },
        overviewDT: function(t) {
          $('#' + dataTableName + ' tr ').not(t).removeClass(
            'selected');
          $(t).toggleClass('selected');
        }
      },
      create: {
        psmDT: function(selectedRow) {
          LorikeetFactory.createLorikeetModel({
            rowData: $('#' + dataTableName).DataTable().row(
              selectedRow).data(),
            callBackFn: function(lModelOptions) {
              var specElement;
              //we have lorikeet data, now create the tab etc.
              specElement = MSMSTabManager.activateTab(
                lModelOptions.sequence, lModelOptions.scanNum
              );
              $(specElement).specview(lModelOptions);
              $('#score_table').hide();
            },
            url: DataManager.urlString
          });
          $(selectedRow).toggleClass('selected')
            .animate({
              'background-color': '#fbec88'
            }, 'slow', 'swing')
            .delay(1000)
            .animate({
              'background-color': ''
            }, 'slow', 'swing', function() {
              $(selectedRow).removeAttr('style');
            });
          GUIUtils.goToElement('tabs');
        },
        overviewDT: function(selectedRow) {
          DataManager.createPSMFromOverview($('#' + dataTableName).DataTable()
            .row(selectedRow).data());
          GUIUtils.goToElement('psmDataTable');
        }
      },
      clean: {
        psmDT: function() {},
        overviewDT: function() {
          if ($.fn.DataTable.isDataTable($('#psmDT'))) {
            $('#psmScoreFilters').empty();
            $('#psmDataTableFilters').empty();
            $('#psmDataTable').empty();
          }
        }
      }
    };

    $('#' + dataTableName + ' tbody').on('click', 'tr', function() {

      funcs.prep[dataTableName](this);
      if (this.classList.contains('selected')) {
        funcs.clean[dataTableName]();
        funcs.create[dataTableName](this);
      } else {
        funcs.clean[dataTableName]();
      }
    });

  };

  sdv.createTable = function(requestObject) {
    var roGrid = SQLDataViewer.dataGrids[requestObject.tableName].grid;
    var roTable = SQLDataViewer.dataGrids[requestObject.tableName].table;

    requestObject.filterGridFunction();

    $('#' + roGrid).html(
      '<table cellpadding="0" cellspacing="0" border="0" class="display" id="' +
      roTable + '"></table>'
    );
    $('#' + roTable).dataTable({
      searching: false,
      dom: 'C<"top"i>tr<"bottom"flp><"clear">',
      scrollX: '100%',
      processing: true,
      serverSide: true,
      ajax: function(data, callback, settings) {
        DataManager.ajaxDataProvider(data, settings, requestObject,
          callback);
      },
      columns: requestObject.generateColumnNames()
    });

    sdv.rowSelectionFunctions(roTable);
  };

  sdv.createTableForSelection = function(tableName) {
    var ro = new RequestObject();
    ro.tableName = tableName;
    if (tableName === 'PSM') {
      sdv.detailRequestObject = ro;
    } else {
      sdv.overviewRequestObject = ro;
    }
    sdv.createTable(ro);
  };

  sdv.produceVisualization = function(confObj) {

    var dco = new ConfigurationObject();
    var tableSelectElement = $('#availableTables');
    var tableNames = Object.keys(confObj.tableRowCount);
    var i;
    var tableOption;

    $('#mainTitle').text(confObj.pageTitle + ' - ' + confObj.dataName);

    console.log('History ID this dataset resides in: ' + confObj.historyID);

    //configure the data management
    dco.dataSetID = confObj.datasetID;
    dco.href = confObj.href;
    dco.tableColumns = confObj.tableColumns;
    dco.tableRowCount = confObj.tableRowCount;
    DataManager.configure(dco);

    //configure the table select options
    if (confObj.isPSM) {
      tableNames = ['PSM', 'Proteins', 'Peptides'];
    }
    for (i = 0; i < tableNames.length; i += 1) {
      tableOption = $('<option/>', {
        value: tableNames[i],
        text: tableNames[i]
      });
      tableSelectElement.append(tableOption);
    }
    //Default to Proteins
    tableSelectElement.val('Proteins');

    tableSelectElement.on('change', function(event) {
      sdv.cleanTables();
      sdv.createTableForSelection(event.target.value);
    });

    //fill for proteins The starting point for users.
    sdv.createTableForSelection('Proteins');

  };

  return sdv;
}(SQLDataViewer || {}));

/**
 * Data request object.
 * Requestor can ask for a canned table query,
 * with limits and filters OR
 * ask for a fully custom SQL result.
 * @constructor
 */

var RequestObject = function() {
  this.customSQL = '';
  this.scoreRangeObject = {};
  this.scoreFilterObject = null;
  this.limit = 1000;
  this.offset = 0;
  this.draw = 0;
  this.callBackFn = null;
  this.orderColumn = null;
  this.orderDirection = null;
  this.needCount = false;
  this.actualRecordCount = 0;
  this.filteredRecordCount = 0;
  var tableName = '';

  //Used in filtering data based on user inputs.
  this.filterGridFunction = function() {};
  this.overviewFilter = {
    Proteins: null,
    Peptides: null
  };

  Object.defineProperty(this, 'tableName', {
    set: function(name) {
      tableName = name;

      switch (name) {
        case 'PSM':
          DataManager.createScoreRangeObject(this.setScoreRangeObject.bind(
            this));
          break;
        case 'Proteins':
        case 'Peptides':
          this.setFilterGridFunction(DataManager.createOverviewFilters);
          break;
      }
      this.needCount = true;
      this.customSQL = SQLText.generateQuery(this.tableName);
    },
    get: function() {
      return tableName;
    }
  });
};

/**
 * User has asked for a peptide sequence(s) or protein id(s).
 * Gets set here so that the generation of SQL will be correct.
 *
 * @param {Object} confObj
 */
RequestObject.prototype.setOverviewFilter = function(confObj) {
  this.needCount = true;
  this.overviewFilter[confObj.type] = confObj.value;
};

RequestObject.prototype.clearOverviewFilter = function() {
  this.needCount = true;
  this.overviewFilter = {
    Proteins: null,
    Peptides: null
  };
};

RequestObject.prototype.makeNameArray = function(rawArray) {
  var returnArray = [];
  rawArray.map(function(cv) {
    var obj = {};
    obj.data = cv.trim().split('.')[1];
    obj.name = cv.trim();
    obj.title = cv.trim();
    returnArray.push(obj);
  });
  return returnArray;
};

RequestObject.prototype.setScoreRangeObject = function(obj) {
  this.scoreRangeObject = obj;
  //Create the score filtering widget
  //div id="psmScoreFilters" class="grid-80 suffix-20">PSM Score Filters</div>
  $('#psmScoreFilters').append(
    '<button id="score_toggle" class="grid-10">Toggle View</button>');
  $('#score_toggle').on('click', function() {
    $('#score_table').toggle(500);
  });
  $('#psmScoreFilters').append(ScoreFilterManager.generateScoreFilterTable(
    this.scoreRangeObject,
    function() {
      var table = $('#psmDT').DataTable();
      SQLDataViewer.detailRequestObject.scoreFilterObject =
        ScoreFilterManager.filterValues();
      SQLDataViewer.detailRequestObject.needCount = true;
      table.draw();
    }));

};

//Object.defineProperty(RequestObject.prototype, 'tableName', {
//    set: function (name) {
//        tableName = name;
//
//        switch (name) {
//            case 'PSM':
//                DataManager.createScoreRangeObject(this.setScoreRangeObject.bind(this));
//                break;
//            case 'Proteins':
//            case 'Peptides':
//                this.setFilterGridFunction(DataManager.createOverviewFilters);
//                break;
//        }
//        this.needCount = true;
//        this.customSQL = SQLText.generateQuery(this.tableName);
//    },
//    get: function () {
//        return  tableName;
//    }
//})

RequestObject.prototype.setFilterGridFunction = function(fn) {
  this.filterGridFunction = fn;
};

RequestObject.prototype.setFullDataCount = function(dataSet) {
  this.actualRecordCount = dataSet.data[1][0];
};

RequestObject.prototype.setFilteredDataCount = function(dataSet) {
  this.filteredRecordCount = dataSet.data[1][0];
};

//Need to clean some column names esp. foo.bar AS 'YEAHaw'
RequestObject.prototype.cleanRawColumnNames = function(nameArray) {
  var returnArray = [];
  nameArray.map(function(cv) {
    if (cv.indexOf('CAST') > -1) {
      returnArray.push(cv.split(/AS REAL\) AS /)[1].slice(1, -1)); //get rid of the AS parens.
    } else if (cv.indexOf('AS') > -1) {
      returnArray.push(cv.split('AS')[0].trim());
    } else {
      returnArray.push(cv);
    }
  });
  return returnArray;
};

RequestObject.prototype.generateColumnNames = function() {
  var returnArray = [];
  var rawColumns = null;

  if (this.customSQL.length > 0) {
    //Column names are in the SELECT --- FROM string
    var str = this.customSQL.slice(this.customSQL.indexOf('SELECT') + 6, this
      .customSQL.indexOf('FROM'));
    rawColumns = this.cleanRawColumnNames(str.split(','));
  } else {
    rawColumns = DataManager.tableColumns[this.tableName].map(function(
      currentValue) {
      if (currentValue.indexOf(':') > -1) {
        return this.tableName + '."' + currentValue + '"';
      } else {
        return this.tableName + '.' + currentValue;
      }
    }, this);
  }

  returnArray = this.makeNameArray(rawColumns);
  return returnArray;
};

//Creates the query to find peptides or proteins based in user input
RequestObject.prototype.generateProtPepQuery = function() {
  var typeConfig = {
    Proteins: {
      column: 'dbsequence.accession',
      likeClause: 'SELECT dbsequence.accession ' +
        'FROM dbsequence WHERE dbsequence.accession LIKE ',
      queryStr: 'SELECT ' +
        'dbs.accession, dbs.description, count(si.pkid)' +
        'FROM ' +
        'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
        'spectrumidentification si, score ' +
        'WHERE ' +
        'pe.dbsequence_pkid = dbs.pkid AND ' +
        'pe.peptide_pkid = peptide.pkid AND ' +
        'pe.spectrumidentification_pkid = si.pkid AND ' +
        'si.spectrum_pkid = spectrum.pkid AND ' +
        'score.spectrumidentification_pkid = si.pkid ' +
        ' AND Accession in (LIST_VALUES) ' +
        'GROUP BY dbs.accession '
    },
    Peptides: {
      column: 'peptide.sequence',
      likeClause: 'SELECT peptide.sequence FROM peptide ' +
        'WHERE peptide.sequence LIKE ',
      queryStr: 'SELECT peptide.sequence, count(si.pkid)' +
        'FROM ' +
        'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
        'spectrumidentification si, score ' +
        'WHERE ' +
        'pe.dbsequence_pkid = dbs.pkid AND ' +
        'pe.peptide_pkid = peptide.pkid AND ' +
        'pe.spectrumidentification_pkid = si.pkid AND ' +
        'si.spectrum_pkid = spectrum.pkid AND ' +
        'score.spectrumidentification_pkid = si.pkid AND ' +
        'peptide.sequence in (LIST_VALUES) ' +
        ' GROUP BY peptide.sequence'
    }
  };
  var itemList = this.overviewFilter[this.tableName];

  itemList.map(function(cv) {
    typeConfig[this.tableName].likeClause += '"%25' + cv + '%25" OR ' +
      typeConfig[this.tableName].column + ' LIKE ';
  });
  typeConfig[this.tableName].likeClause = typeConfig[this.tableName].likeClause
    .slice(0, typeConfig[this.tableName].likeClause.lastIndexOf('OR'));
  typeConfig[this.tableName].queryStr =
    typeConfig[this.tableName].queryStr.replace(
      'LIST_VALUES', typeConfig[this.tableName].likeClause);
  return typeConfig[this.tableName].queryStr;
};

RequestObject.prototype.generateSQL = function(isCount) {
  var returnStr;
  var countQuery = isCount || false;

  if (this.customSQL.length > 0) {
    returnStr = this.customSQL;
  } else {
    returnStr = 'SELECT * FROM ' + this.tableName;
  }

  //If we are in overview and user is asking for specific items,
  //this overwrites the base returnStr
  if (this.overviewFilter[this.tableName]) {
    returnStr = this.generateProtPepQuery();
  }

  if (this.scoreFilterObject) {
    returnStr += SQLText.createWhereFromFilter(this.scoreFilterObject);
  }

  if (this.orderColumn) {
    if (this.orderColumn.indexOf('Score') > -1) {
      returnStr += ' ORDER BY CAST(' + this.orderColumn + ' AS REAL) ' + this
        .orderDirection;
    } else {
      returnStr += ' ORDER BY ' + this.orderColumn + ' ' + this.orderDirection;
    }
  }
  if (this.limit > 0) {
    returnStr += ' LIMIT ' + this.limit + ' OFFSET ' + this.offset;
  }

  if (countQuery) {
    returnStr = 'SELECT COUNT(*) FROM (' + returnStr.slice(0, returnStr.indexOf(
      'ORDER')) + ')';
  }

  return returnStr;
};

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
var ResponseObject = function() {
  this.draw = 0;
  this.recordsTotal = 0;
  this.recordsFiltered = 0;
  this.data = [];
  this.error = null;
};

/**
 * Manages data requests from requestor to the SQLite data type
 *
 */
var DataManager = (function(dm) {

  dm.getScoreRange = function(query, callBackFn) {
    var url = DataManager.urlString;
    var buildObject = function(rawData) {
      var retObj = {};
      rawData.data[0].map(function(cv, idx) {
        var scoreType = cv.slice(0, 3);
        var scoreName = cv.slice(4);
        if (!(scoreName in retObj)) {
          retObj[scoreName] = {};
        }
        retObj[scoreName][scoreType] = rawData.data[1][idx];
      });
      callBackFn(retObj);
    };

    url += query;
    $.get(url, function(data) {
      buildObject(data);
    });
  };

  dm.generateScoreRangeObject = function(callBackFn) {
    var query = SQLText.generateScoreRangeQuery();
    dm.getScoreRange(query, callBackFn);
  };

  /**
   *
   * @param {Object} rawData record set from ajax call
   * @param {Object} confObj request object responsible for call.
   * @returns {ResponseObject}
   */
  dm.generateResponseObject = function(rawData, confObj) {
    var colNames = [];
    var dataArray = [];
    var ro = new ResponseObject();

    confObj.generateColumnNames().map(function(cv) {
      colNames.push(cv.data);
    });
    rawData.data.splice(0, 1); //removes the column name elements from the record set.
    rawData.data.map(function(x) {
      var tObj = {};
      colNames.map(function(cv, idx) {
        tObj[cv] = x[idx];
      });
      dataArray.push(tObj);
    });

    ro.draw = parseInt(confObj.draw);
    if (DataManager.tableRowCount[confObj.tableName]) {
      ro.recordsTotal = DataManager.tableRowCount[confObj.tableName];
      ro.recordsFiltered = ro.recordsTotal; //#TODO:260 if fitlered this is different
    } else {
      ro.recordsTotal = confObj.actualRecordCount;
      ro.recordsFiltered = confObj.actualRecordCount;
    }

    if (confObj.scoreFilterObject) {
      ro.recordsFiltered = confObj.filteredRecordCount;
    }
    ro.data = dataArray;
    return ro;
  };

  dm.executeSQL = function(confObj, urlValue) {
    $.get(urlValue, function(data) {
        confObj.callBackFn(dm.generateResponseObject(data, confObj));
      })
      .error(function(jqXHR) {
        //Flash a quick modal message here
        var dg = $('<div>', {
          id: 'ajax_error',
          title: 'Query Error'
        });
        var msg = $('<p>', {
          text: jqXHR.responseText
        });

        dg.dialog({
          minWidth: 200,
          height: 200
        });
        dg.append(msg);
        setTimeout(function() {
          dg.dialog('close');
        }, 5000);
      });
  };

  /**
   * For paging, we need the full data count.
   *
   * @param {Object} requestObject
   */
  dm.getDataCount = function(requestObject) {
    $.get(DataManager.urlString + requestObject.generateSQL(true),
      function(data) {

        if (requestObject.scoreFilterObject) {
          requestObject.setFilteredDataCount(data);
        } else {
          requestObject.setFullDataCount(data);
        }
        requestObject.needCount = false;
        dm.getData(requestObject);
      });
  };

  /**
   * We have full data count, now get limited and offset data.
   *
   @param {Object} requestObject
   */
  dm.getData = function(requestObject) {
    var url = DataManager.urlString;
    url += requestObject.generateSQL();
    dm.executeSQL(requestObject, url);
  };

  /**
   * User has chosen a peptide or protein. Now get all the psms based on the choice.
   */
  dm.psmFromOverview = function(rowObject) {
    var psmFromQuery = SQLText.generateQuery('accession' in rowObject ?
      'psmFromProtein' : 'psmFromPeptide');
    var ro;
    psmFromQuery = psmFromQuery.replace('REPLACE_PEP_PROT_TEXT',
      'accession' in rowObject ?
      '"' + rowObject.description + '"' :
      '"' + rowObject.sequence + '"');
    ro = new RequestObject();
    ro.tableName = 'PSM';
    ro.customSQL = psmFromQuery;
    SQLDataViewer.detailRequestObject = ro;
    SQLDataViewer.createTable(ro);
  };

  //publicly available functions
  return {
    configure: function(confObj) {
      DataManager.hrefValue = confObj.href;
      DataManager.dataID = confObj.dataSetID;
      DataManager.tableRowCount = confObj.tableRowCount;
      DataManager.tableColumns = confObj.tableColumns;

      DataManager.urlString = confObj.href + '/api/datasets/' +
        confObj.dataSetID +
        '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
    },
    createOverviewFilters: function() {
      $('#overviewDataTableFilters').append(
        OverviewFilterManager.generateOverviewFilterTable()
      );
    },
    createScoreRangeObject: function(callBackFn) {
      dm.generateScoreRangeObject(callBackFn);
    },
    createPSMFromOverview: function(rowObject) {
      dm.psmFromOverview(rowObject);
    },
    ajaxDataProvider: function(requestData, tableSettings, requestObject,
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
        dm.getDataCount(ro);
      } else {
        dm.getData(ro);
      }
    }
  };

}(DataManager || {}));

//General GUI utils
var GUIUtils = (function(gu) {

  /**
   * Animated scroll to the element elemID
   *
   * @param {String} elemID
   */
  gu.goToElement = function(elemID) {
    $('html, body').animate({
      scrollTop: ($('#' + elemID).offset().top)
    }, 500);
  };

  return gu;
}(GUIUtils || {}));

//Lorikeet tab management code
var MSMSTabManager = (function(msTM) {
  msTM.MAX_TABS = 20;
  msTM.activeTabs = {};

  if (Object.keys(msTM.activeTabs).length === 0) {
    $('#tabs').tabs({
      activate: function() {
        $('#tabs').tabs('option', 'active');
      }
    });
  }

  msTM.activateTab = function(sequence, scanNum) {
    var liElement;
    var divElement;
    var divSpecViewer;
    var tabText = sequence + ' <small>' + scanNum + '</small>';

    if (Object.keys(msTM.activeTabs).length === 0) {
      //first scan graph, add a clear all button
      $('#tabs').tabs().prepend(
        '<button id="clear_all_btn" class="grid-5 suffix-95 submit">' +
        '<small>Clear All</small></button>'
      );
      $('#clear_all_btn').on('click', msTM.clearAllActiveTabs);
    }

    if (Object.keys(msTM.activeTabs).length < this.MAX_TABS) {
      if (tabText in msTM.activeTabs) {
        return null;
      }
      liElement = $('<li/>', {
        'id': tabText
      });
      liElement.append('<a href="#tab' + Object.keys(msTM.activeTabs).length +
        '">' + tabText +
        '</a><span class="ui-icon ui-icon-close" role="presentation" ' +
        'style="float: left; margin: 0.4em 0.2em 0 0; cursor: pointer;">' +
        'Remove Tab</span>'
      );
      $('div#tabs ul').append(liElement);
      divElement = $('<div/>', {
        'id': 'tab' + Object.keys(msTM.activeTabs).length
      });
      divSpecViewer = $('<div/>', {
        'id': 'lorikeet' + Object.keys(msTM.activeTabs).length
      });
      divElement.append(divSpecViewer);
      $('div#tabs').append(divElement);
      $('div#tabs').tabs({
        event: 'mouseover'
      });
      $('div#tabs').tabs().find('.ui-tabs-nav').sortable({
        axis: 'x',
        stop: function() {
          $('div#tabs').tabs('refresh');
        }
      });
      // close icon: removing the tab on click
      $('div#tabs').tabs().delegate('span.ui-icon-close', 'click',
        function() {
          var liClose = $(this).closest('li');
          var msTabID = liClose[0].id;
          var panelId = $(this).closest('li').remove().attr(
            'aria-controls');
          $('#' + panelId).remove();
          delete msTM.activeTabs[msTabID];
          if (Object.keys(msTM.activeTabs).length === 0) {
            $('#clear_all_btn').remove();
          }
          $('div#tabs').tabs('refresh');
        });

      $('div#tabs').tabs('refresh');
      msTM.activeTabs[tabText] = {
        'liElement': liElement,
        'divElement': divElement
      };
      return divSpecViewer;

    } else {
      return null;
    }
  };

  msTM.deactivateTab = function(sequence, scanNum) {
    var liElement;
    var divElement;
    var tabText = sequence + ' <small>' + scanNum + '</small>';
    if (tabText in msTM.activeTabs) {
      liElement = msTM.activeTabs[tabText].liElement;
      divElement = msTM.activeTabs[tabText].divElement;
      liElement.remove();
      divElement.remove();
      delete msTM.activeTabs[tabText];
    }
    if (Object.keys(msTM.activeTabs).length === 0) {
      $('#clear_all_btn').remove();
    }
  };

  msTM.clearAllActiveTabs = function() {
    var tabText = '';
    var divElement;
    var liElement;

    for (tabText in msTM.activeTabs) {
      liElement = msTM.activeTabs[tabText].liElement;
      divElement = msTM.activeTabs[tabText].divElement;
      liElement.remove();
      divElement.remove();
      delete msTM.activeTabs[tabText];
    }
    if (Object.keys(msTM.activeTabs).length === 0) {
      $('#clear_all_btn').remove();
    }
  };

  return msTM;
}(MSMSTabManager || {}));

//Creates html score filter elements.
var ScoreFilterManager = (function(sfm) {

  /**
   * Returns user entered values from the score grid
   */
  sfm.filterValues = function() {
    var isFilterDirty = false;
    var filterValue;
    var propName;
    var scoreType;
    var retValue;
    var filterObject = {};

    $('.scoreFilter').map(function() {
      propName = this.name.replace(/_/, ' ');
      scoreType = propName.slice(0, 3); // MIN || MAX
      propName = propName.slice(4); //just the field name now

      if (isNaN(parseFloat(this.value))) {
        //DO NOTHING, USER IS __NOT__ FILTERING ON THIS VALUE
      } else {
        if (!(propName in filterObject)) {
          filterObject[propName] = {};
        }
        filterValue = parseFloat(this.value);
        isFilterDirty = true;
        filterObject[propName][scoreType] = filterValue;
      }
    });

    if (isFilterDirty) {
      //filterObject.resultCount = null;
      retValue = filterObject;
    } else {
      retValue = null;
    }
    return retValue;
  };

  //Score array will have min and max input elements ready for table packaging.
  sfm.generateScoreFilterTable = function(scoreRangeObject, callBackFn) {
    var contain = $('<div/>', {
      id: 'score_table',
      class: 'grid-100 grid-parent'
    });
    var filterButton = $('<button>', {
      class: 'submit',
      text: 'Filter By Scores'
    });
    var clearFilterButton = $('<button>', {
      class: 'submit',
      text: 'Clear Filtering'
    });
    var key;
    var parentElem;
    var anElem;

    filterButton.on('click', callBackFn);
    clearFilterButton.on('click', function() {
      $('.scoreFilter').val('');
      callBackFn();
    });

    $(
      '<div class="grid-100 align-center">' +
      '<strong>Filter PSMs by Score</strong></div>'
    ).appendTo(contain);
    $('<div class="clear"></div>').appendTo(contain);

    for (key in scoreRangeObject) {
      parentElem = $('<div/>', {
        class: 'grid-50 grid-parent'
      });
      parentElem.append($('<div/>', {
        text: key,
        class: 'grid-100 align-center'
      }));

      parentElem.append($('<div/>', {
        text: 'MAX',
        class: 'grid-50'
      }));

      parentElem.append($('<div/>', {
        text: 'MIN',
        class: 'grid-50'
      }));

      parentElem.append(
        $('<input/>', {
          class: 'scoreFilter grid-50',
          id: 'MAX_' + key,
          name: 'MAX_' + key,
          placeholder: scoreRangeObject[key].MAX
        })
      );

      parentElem.append(
        $('<input/>', {
          class: 'scoreFilter grid-50',
          id: 'MIN_' + key,
          name: 'MIN_' + key,
          placeholder: scoreRangeObject[key].MIN
        })
      );
      contain.append(parentElem);

    }

    anElem = $('<div/>', {
      class: 'grid-50'
    });

    anElem.append(filterButton);
    anElem.append(clearFilterButton);
    contain.append(anElem);

    return contain;
  };

  return sfm;
}(ScoreFilterManager || {}));

//Creates a filter for the overview table
var OverviewFilterManager = (function(ofm) {
  ofm.parseUserInput = function() {
    var inputValue = $('#filter_value').val();
    var re = /[:|-|,|\s]/; //split on ',' '-' ' ', ':'
    var returnValue = [];

    if (inputValue) {
      inputValue.split(re).map(function(cv) {
        if (cv.length > 0) {
          returnValue.push(cv);
        }
      });
    } else {
      returnValue = null;
    }
    return returnValue;
  };

  /**
   * Creates a user available peptide/protein filter table.
   */
  ofm.generateOverviewFilterTable = function() {
    var divElement;
    var filterButton;
    var clearFilterButton;
    var inputField;
    var labelInputField;
    var anElem;
    var filterTypes = {
      Proteins: {
        fButtonText: 'Filter Proteins',
        inputField: 'Enter one accession or ' +
          'comma separated list of accessions.',
        labelInputField: 'Find protein by accession(s)'
      },
      Peptides: {
        fButtonText: 'Filter Peptides',
        inputField: 'Enter one sequence or ' +
          'a comma separated list of sequences.',
        labelInputField: 'Find peptides by sequence(s)'
      }
    };

    divElement = $('<div/>', {
      id: 'textFilter',
      class: 'grid-50 grid-parent'
    });

    filterButton = $('<button>', {
      class: 'submit',
      text: filterTypes[SQLDataViewer.overviewRequestObject.tableName]
        .fButtonText
    });
    clearFilterButton = $('<button>', {
      class: 'submit',
      text: 'Clear Filtering'
    });
    inputField = $('<input/>', {
      type: 'search',
      title: filterTypes[SQLDataViewer.overviewRequestObject.tableName]
        .inputField,
      id: 'filter_value',
      width: '100%'
    });
    labelInputField = $('<label/>', {
      text: filterTypes[SQLDataViewer.overviewRequestObject.tableName]
        .labelInputField
    });

    filterButton.on('click', function() {
      var userInput = ofm.parseUserInput();
      var table = $('#overviewDT').DataTable();
      SQLDataViewer.overviewRequestObject.setOverviewFilter({
        type: SQLDataViewer.overviewRequestObject.tableName,
        value: userInput
      });
      table.draw();
    });
    clearFilterButton.on('click', function() {
      var table = $('#overviewDT').DataTable();
      $('#filter_value').val('');
      SQLDataViewer.overviewRequestObject.clearOverviewFilter();
      table.draw();
    });

    $(
      '<p class="grid-100 align-center"><strong>Filter Proteins</strong></p>'
    ).appendTo(divElement);
    anElem = $('<div/>', {
      class: 'grid-25'
    });
    anElem.append(labelInputField);
    anElem.after(divElement).appendTo(divElement);
    anElem = $('<div/>', {
      class: 'grid-75'
    });
    anElem.append(inputField);
    anElem.appendTo(divElement);

    anElem.append(filterButton);
    anElem.append(clearFilterButton);
    anElem.appendTo(divElement);
    return divElement;
  };
  return ofm;
}(OverviewFilterManager || {}));

var TableSchemaWidget = (function(tsw) {

  //Just building a simple ul for schema
  tsw.buildElement = function(data) {
    var container;
    var li;
    var li2;
    var ul;

    container = $('<ul/>', {
      id: 'schemaContainer'
    });

    Object.keys(data).map(function(x) {
      li = $('<li/>', {
        name: x,
        text: x,
        style: 'cursor: pointer'
      });
      li.on('click', function(event) {
        if (event.target.firstElementChild.style.display ===
          'none') {
          event.target.firstElementChild.style.display = 'block';
        } else {
          event.target.firstElementChild.style.display = 'none';
        }
      });

      ul = $('<ul/>', {
        id: 'ul_' + x,
        style: 'display: none',
        name: x
      });

      data[x].map(function(y) {
        li2 = $('<li/>', {
          id: y,
          name: y,
          text: y
        });
        li2.draggable({
          helper: 'clone'
        });
        ul.append(li2);
      });
      li.append(ul);
      container.append(li);
    });

    return container;
  };

  return {
    /**
     * Will return an HTML element with tableand row names
     *
     * @param {Object} schemaObj
     */
    generateSchemaWidget: function(schemaObj) {
      return tsw.buildElement(schemaObj);
    }
  };
}(TableSchemaWidget || {}));

var SQLEditorPopulator = (function(sep) {

  sep.dropBehavior = function(event, ui) {
    var currentText = this.value;
    var selClause;
    var sIdx;
    var fromClause;
    var fIdx;
    var whereClause;
    var wIdx;

    if (currentText.length === 0) {
      this.value = 'SELECT ' + ui.draggable[0].parentNode.id.replace(
        'ul_', '') + '."' + ui.draggable.text() + '" ';
      this.value += ' FROM ' + ui.draggable[0].parentNode.id.replace(
        'ul_', '');
    } else {
      sIdx = currentText.toLocaleUpperCase().indexOf(' SELECT ');
      fIdx = currentText.toLocaleUpperCase().indexOf(' FROM ');
      wIdx = currentText.toLocaleUpperCase().indexOf(' WHERE ');

      selClause = currentText.slice(sIdx + 8, fIdx);
      fromClause = currentText.slice(fIdx + 6, wIdx > -1 ? wIdx :
        currentText.length);
      whereClause =
        wIdx > -1 ? currentText.slice(wIdx + 7, currentText.length) :
        '';

      selClause += ', ' + ui.draggable[0].parentNode.id.replace('ul_', '') +
        '."' + ui.draggable.text() + '" ';
      if (fromClause.indexOf(ui.draggable[0].parentNode.id.replace('ul_',
          '')) === -1) {
        fromClause += ', ' + ui.draggable[0].parentNode.id.replace('ul_',
          '');
      }
      this.value = 'SELECT ' + selClause + 'FROM ' + fromClause +
        ' WHERE ' + whereClause;
    }

  };

  return sep;

}(SQLEditorPopulator || {}));

/**
 * Lorikeet data factory.
 */
var LorikeetFactory = (function(lf) {

  //Will store created models. Quick caching.
  //Key is pkid
  var LorikeetModels = {};
  //window.setInterval(function () {
  //    console.log('Clearing the model cache');
  //    LorikeetModels =  {};
  //}, 1000 * 60 * 10); //clear cache every 10 minutes.
  function LorikeetModel() {
    this.configSteps = [0, 0, 0];
    this.fnOnConfigured = null;
    this.properties = {
      showInternalIonOption: true,
      showMHIonOption: true,
      showAllTable: true,
      peakDetect: false,
      scanPKID: null,
      sequence: null,
      staticMods: [],
      variableMods: [],
      ntermMod: 0, // additional mass to be added to the n-term
      ctermMod: 0, // additional mass to be added to the c-term
      peaks: [],
      massError: 0.01,
      scanNum: null,
      fileName: null,
      charge: null,
      precursorMz: null,
      ms1peaks: [],
      ms1scanLabel: null,
      precursorPeaks: null,
      precursorPeakClickFn: null,
      zoomMs1: false,
      width: 750, // width of the ms/ms plot
      height: 450, // height of the ms/ms plot
      extraPeakSeries: []
    };
  }

  LorikeetModel.prototype.isConfigured = function() {
    var result = this.configSteps.reduce(function(a, b) {
      return a + b;
    });
    if (result === this.configSteps.length) {
      LorikeetModels[this.properties.scanPKID] = this;
      this.fnOnConfigured(this.getOptions()); //configured, we're out of here.
    }
  };

  //Lorikeet visualization code needs a JSON object
  LorikeetModel.prototype.getOptions = function() {
    var options = {};
    var prop = null;
    for (prop in this.properties) {
      options[prop] = this.properties[prop];
    }
    return options;
  };

  LorikeetModel.prototype.getLorikeetSQL = function(type) {
    var lorikeetPeaksQuery = 'SELECT p.moz, p.intensity ' +
      'FROM peaks p,peptideevidence pe,spectrumidentification si ' +
      'WHERE si.spectrum_pkid = p.spectrum_pkid AND ' +
      'pe.spectrumidentification_pkid = si.pkid AND ' +
      'si.pkid = SPECTRUM_ID_PKID LIMIT 1';
    //ms1PeaksQuery = 'SELECT p.moz, p.intensity ' +
    //    'FROM peaks p,peptideevidence pe,spectrumidentification si, spectrum' +
    //    'WHERE si.spectrum_pkid = p.spectrum_pkid AND pe.spectrumidentification_pkid = si.pkid AND ' +
    //    'spectrum.accquisitionNum = SPECTRUM_NUM AND si.spectrum_pkid = spectrum.pkid saLIMIT 1',
    var lorikeetModificationsQuery = 'SELECT m.* ' +
      ' FROM peptideevidence pe, modification m, spectrumidentification si ' +
      'WHERE ' +
      'si.pkid = SPECTRUM_ID_PKID AND' +
      ' pe.peptide_pkid = m.peptide_pkid AND ' +
      'pe.spectrumidentification_pkid = si.pkid';
    var returnValue = '';

    switch (type) {
      case 'peaks':
        returnValue = lorikeetPeaksQuery;
        break;
      case 'mods':
        returnValue = lorikeetModificationsQuery;
        break;
    }
    return returnValue;
  };

  LorikeetModel.prototype.executeSQL = function(confObj) {
    $.get(confObj.urlValue, function(data) {
      var formattedData = LorikeetFactory.formatAPIData(data);
      confObj.data = formattedData;
      confObj.callBackFn(confObj);
    });
  };

  LorikeetModel.prototype.setModifications = function(confObj) {
    var indexVals = {};
    var lorikeetMods = [];
    var i;

    confObj.data.columns.map(function(cv, index) {
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
    this.configSteps[2] = 1;
    this.isConfigured();
  };

  //Sets peaks for either the MS2 or MS1 peaks.
  LorikeetModel.prototype.setPeaks = function(confObject) {
    var moz = JSON.parse(confObject.data.rows[0][0]);
    var intensity = JSON.parse(confObject.data.rows[0][1]);
    if (confObject.mslevel === 2) {
      moz.map(function(cv, idx) {
        this.properties.peaks.push([cv, intensity[idx]]);
      }.bind(this));
      this.configSteps[0] = 1;
    } else {
      moz.map(function(cv, idx) {
        this.properties.ms1peaks.push([cv, intensity[idx]]);
      }.bind(this));
      this.configSteps[1] = 1;
    }
    this.isConfigured();
  };

  //Sets peaks for either the MS2 or MS1 peaks.
  LorikeetModel.prototype.getPeaks = function(urlString) {
    var qry = this.getLorikeetSQL('peaks');
    qry = qry.replace('SPECTRUM_ID_PKID', this.properties.scanPKID);
    urlString += qry;
    //ms2
    this.executeSQL({
      urlValue: urlString,
      mslevel: 2,
      callBackFn: this.setPeaks.bind(this),
      data: null
    });
    //ms1??
    if (!(this.properties.precursorScanNumber)) {
      this.configSteps[1] = 1;
    }
  };

  //determines if we have modifications present
  LorikeetModel.prototype.getModifications = function(urlString) {
    var qry;
    if (this.properties.modNum > 0) {
      qry = this.getLorikeetSQL('mods');
      qry = qry.replace('SPECTRUM_ID_PKID', this.properties.scanPKID);
      urlString += qry;
      //ms2
      this.executeSQL({
        urlValue: urlString,
        callBackFn: this.setModifications.bind(this),
        data: null
      });
    } else {
      this.configSteps[2] = 1;
      this.isConfigured();
    }
  };

  /**
   * Formats Galaxy API returned data.
   *
   * @param {Object} rawData
   * @returns {*}
   */
  lf.formatAPIData = function(rawData) {
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

  /**
   The required options(key/value pairs) are:
   ------------------------------------------
   1. sequence: the sequence of the peptide
   2. peaks: an array of peaks in the MS/MS scan.
   Example: [ [602.17,209860.34], [691.67,33731.58],[871.42,236841.11],[888.50,1005389.56] ]

   Other options (not required):
   ----------------------------
   1. charge: The charge of the precursor. This information is displayed at the top of the scan.
   2. precursorMz: The m/z of the precursor. This information is displayed at the top of the scan.
   This value is required for labeling the precursor peak in the MS1 scan if
   it is rendered.
   3. scanNum:  The scan number of the MS/MS scan. This information is displayed at the top of the scan.
   4. fileName: Name of the file that contains the MS/MS scan. This information is displayed at the top of the scan.
   5. staticMods: An array of static modifications. Each modification is a set of key/value pairs.
   Example: [{"modMass":57.0,"aminoAcid":"C"}];
   4. variableMods: An array of variable modifications. Each modification is a set of key/value pairs.
   Example: [ {index: 14, modMass: 16.0, aminoAcid: 'M'} ] // index is the index (1-based)
   // of the modification in the sequence.
   5. ntermMod: additional mass to be added to the N-terminus.
   6. ctermMod: additional mass to be added to the C-terminus.
   7. massError: mass tolerance used for labeling peaks in the MS/MS scan.
   8. ms1Peaks:  peaks in the MS1 scan. Format is the same as the "peaks" option.
   9. precursorPeaks:  Any precursor peaks in the MS1 scan that will be highlighted.
   Same format is the same as the "peaks" option.
   10. zoomMs1: If the value is "true" the MS1 scan, upon initialization, is zoomed around the peak
   that is the closest match to the "precursorMz" option. Default is "false".
   11. ms1scanLabel: Label for the MS1 scan.
   12. precursorPeakClickFn: This is the function that will be called when a precursor peak is clicked.
   13. width: width of the MS/MS plot area. Default is 750.
   14. height: height of the MS/MS plot area. Default is 450.
   15. extraPeakSeries: An array of user defined peak series.  Each series should be a set of key value pairs.
   Example: {data: [[10.0,2.0],[20.0,3.0]], color: "#00aa00",labelType: 'mz',labels: ['one','two']}
   "labelType" should not be used if custom labels are provided as value to the "labels" key.
   If "labelType" is 'mz', custom labels are ignored.

   Data row object :
   Object {Mascot:identity threshold: 41.73769, Mascot:score: 56.26, Scoffold:Peptide Probability: 0.95, acquisitionNum: 3340, msLevel: 2…}
   Mascot:identity threshold: 41.73769
   Mascot:score: 56.26
   Scoffold:Peptide Probability: 0.95
   accession: "IPI00220701"
   acquisitionNum: 3340
   basePeakIntensity: null
   basePeakMZ: null
   collisionEnergy: null
   highMZ: null
   ionisationEnergy: null
   lowMZ: null
   modNum: 0
   msLevel: 2
   peaksCount: 300
   pkid: 13
   polarity: null
   precursorCharge: 2
   precursorIntensity: null
   precursorMZ: 450.9005000290985
   precursorScanNum: null
   retentionTime: null
   sequence: "QDVVNAVR"
   title: "20111214_RL40.6352.6352.2.dta"
   totIonCurrent: null

   confObject = {
      rowData: data from selected row,
      callBackFn: function to invoke on completion
      url: galaxy url for query
   }
   * @returns {LorikeetModel}
   */
  lf.createLorikeetModel = function(confObject) {
    var lm;
    var dataRow = confObject.rowData;
    var callBackFn = confObject.callBackFn;
    var url = confObject.url;

    if (LorikeetModels[dataRow.pkid]) {
      callBackFn(LorikeetModels[dataRow.pkid].getOptions());
    } else {
      lm = new LorikeetModel();
      lm.properties.scanPKID = dataRow.pkid;
      lm.properties.sequence = dataRow.sequence;
      lm.properties.scanNum = dataRow.acquisitionNum;
      lm.properties.charge = dataRow.precursorCharge;
      lm.properties.precursorMz = dataRow.precursorMZ;
      lm.properties.fileName = dataRow.title;
      lm.properties.modNum = dataRow.modNum;
      lm.properties.precursorScanNumber = dataRow.precursorScanNum;

      lm.fnOnConfigured = callBackFn;
      lm.getPeaks(url);
      lm.getModifications(url);
    }
  };

  return lf;
}(LorikeetFactory || {}));

var SQLText = (function(sqltxt) {
  var proteinView = 'SELECT ' +
    'dbs.accession, dbs.description, count(si.pkid)' +
    'FROM ' +
    'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
    'spectrumidentification si, score ' +
    'WHERE ' +
    'pe.dbsequence_pkid = dbs.pkid AND ' +
    'pe.peptide_pkid = peptide.pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid AND ' +
    'si.spectrum_pkid = spectrum.pkid AND ' +
    'score.spectrumidentification_pkid = si.pkid ' +
    'GROUP BY dbs.accession ';
  var peptideView = 'SELECT ' +
    'peptide.sequence,count(si.pkid)' +
    'FROM ' +
    'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
    'spectrumidentification si, score ' +
    'WHERE ' +
    'pe.dbsequence_pkid = dbs.pkid AND ' +
    'pe.peptide_pkid = peptide.pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid AND ' +
    'si.spectrum_pkid = spectrum.pkid AND ' +
    'score.spectrumidentification_pkid = si.pkid ' +
    'GROUP BY peptide.sequence ';
  var psmFromPeptide =
    ',Spectrum.precursorCharge,Spectrum.precursorIntensity,Spectrum.title, ' +
    'Peptide.sequence,Peptide.modNum,dbs.accession, si.pkid ' +
    ',pe.isDecoy,Spectrum.acquisitionNum,Spectrum.msLevel,' +
    'Spectrum.polarity,Spectrum.peaksCount,Spectrum.totIonCurrent,' +
    'Spectrum.retentionTime,Spectrum.basePeakMZ,Spectrum.basePeakIntensity,' +
    'Spectrum.collisionEnergy,Spectrum.ionisationEnergy,' +
    'Spectrum.lowMZ,Spectrum.highMZ,Spectrum.precursorScanNum,' +
    'Spectrum.precursorMZ' +
    ' FROM ' +
    'spectrum, peptide, peptideevidence pe, DBSequence dbs, ' +
    'spectrumidentification si, score ' +
    'WHERE ' +
    'pe.dbsequence_pkid = dbs.pkid AND ' +
    'peptide.sequence = REPLACE_PEP_PROT_TEXT AND ' +
    'pe.peptide_pkid = peptide.pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid AND ' +
    'si.spectrum_pkid = spectrum.pkid AND ' +
    'score.spectrumidentification_pkid = si.pkid';
  var psmFromProtein =
    ',Spectrum.precursorCharge,Spectrum.precursorIntensity,Spectrum.title, ' +
    'Peptide.sequence,Peptide.modNum,dbs.accession, si.pkid ' +
    ',pe.isDecoy,Spectrum.acquisitionNum,Spectrum.msLevel,' +
    'Spectrum.polarity,Spectrum.peaksCount,Spectrum.totIonCurrent,' +
    'Spectrum.retentionTime,Spectrum.basePeakMZ,Spectrum.basePeakIntensity,' +
    'Spectrum.collisionEnergy,Spectrum.ionisationEnergy,' +
    'Spectrum.lowMZ,Spectrum.highMZ,Spectrum.precursorScanNum,' +
    'Spectrum.precursorMZ' +
    ' FROM ' +
    'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
    'spectrumidentification si, Score ' +
    'WHERE ' +
    'pe.dbsequence_pkid = dbs.pkid AND ' +
    'dbs.description = REPLACE_PEP_PROT_TEXT AND ' +
    'pe.peptide_pkid = peptide.pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid AND ' +
    'si.spectrum_pkid = spectrum.pkid AND ' +
    'score.spectrumidentification_pkid = si.pkid';
  var psm =
    ',Spectrum.precursorCharge,Spectrum.precursorIntensity,Spectrum.title, ' +
    'Peptide.sequence,Peptide.modNum,dbs.accession, si.pkid ' +
    ',pe.isDecoy,Spectrum.acquisitionNum,Spectrum.msLevel,' +
    'Spectrum.polarity,Spectrum.peaksCount,Spectrum.totIonCurrent,' +
    'Spectrum.retentionTime,Spectrum.basePeakMZ,Spectrum.basePeakIntensity,' +
    'Spectrum.collisionEnergy,Spectrum.ionisationEnergy,' +
    'Spectrum.lowMZ,Spectrum.highMZ,Spectrum.precursorScanNum,' +
    'Spectrum.precursorMZ' +
    ' FROM ' +
    'spectrum, peptide, DBSequence dbs, peptideevidence pe, ' +
    'spectrumidentification si, Score ' +
    'WHERE ' +
    'pe.dbsequence_pkid = dbs.pkid AND ' +
    'pe.peptide_pkid = peptide.pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid AND ' +
    'si.spectrum_pkid = spectrum.pkid AND ' +
    'score.spectrumidentification_pkid = si.pkid';
  //Move these to Lorikeet factory
  var lorikeetPeaksQuery = 'SELECT ' +
    'p.moz, p.intensity ' +
    'FROM ' +
    'peaks p,peptideevidence pe,spectrumidentification si ' +
    'WHERE ' +
    'si.spectrum_pkid = p.spectrum_pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid AND ' +
    'si.pkid = SPECTRUM_ID_PKID LIMIT 1';
  var lorikeetModificationsQuery = 'SELECT ' +
    'm.* FROM peptideevidence pe, modification m, spectrumidentification si ' +
    'WHERE ' +
    'si.pkid = SPECTRUM_ID_PKID AND ' +
    'pe.peptide_pkid = m.peptide_pkid AND ' +
    'pe.spectrumidentification_pkid = si.pkid';
  var queryList = {
    peptides: peptideView,
    proteins: proteinView,
    psm: psm,
    psmFromProtein: psmFromProtein,
    psmFromPeptide: psmFromPeptide,
    peaks: lorikeetPeaksQuery,
    modifications: lorikeetModificationsQuery
  };

  sqltxt.generateScoreQuery = function(qType) {
    var removeFields = ['spectrum_identification_id',
      'SpectrumIdentification_pkid', 'pkid'
    ];
    var scoreQuery = 'SELECT ';
    var queryType = qType || 'REGULAR';

    DataManager.tableColumns.Score.map(function(columnName) {
      if (removeFields.indexOf(columnName) === -1) {
        switch (queryType) {
          case 'MIN_MAX':
            scoreQuery += 'MAX(CAST(Score."' + columnName +
              '" AS REAL)) AS "MAX ' + columnName + '"' +
              ', MIN(CAST(Score."' + columnName +
              '" AS REAL)) AS "MIN ' + columnName + '",';
            break;
          default:
            scoreQuery += 'CAST(Score."' + columnName +
              '" AS REAL) AS \'Score."' + columnName + '"\', ';
            break;
        }
      }

    });

    return scoreQuery.slice(0, scoreQuery.lastIndexOf(',')); //remove trailing ,
  };

  sqltxt.createPSMQuery = function(baseString) {
    var qStr = sqltxt.generateScoreQuery();
    qStr += baseString;
    return qStr;
  };

  sqltxt.createPSMFromPeptideQuery = function(baseString) {
    var qStr = sqltxt.generateScoreQuery();
    qStr += baseString;
    return qStr;
  };

  sqltxt.getQuery = function(queryName) {
    switch (queryName) {
      case 'psm':
        return sqltxt.createPSMQuery(queryList.psm);
      case 'psmfrompeptide':
        return sqltxt.createPSMFromPeptideQuery(queryList.psmFromPeptide);
      case 'psmfromprotein':
        return sqltxt.createPSMFromPeptideQuery(queryList.psmFromProtein);
    }
    return queryList[queryName];
  };

  return {
    createWhereFromFilter: function(fObj) {
      var wClause = ' AND ';
      var ops = {
        'MAX': '<=',
        'MIN': '>='
      };
      var key;
      var type;

      for (key in fObj) {
        for (type in fObj[key]) {
          wClause += ' Score."' + key + '" ' + ops[type] + ' ' + fObj[key]
            [type] + ' AND ';
        }
      }
      return wClause.slice(0, -5).replace(/\s+/g, '+'); //remove trailing AND, remove spaces

    },
    generateQuery: function(qryName) {
      return sqltxt.getQuery(qryName.toLocaleLowerCase());
    },
    generateScoreRangeQuery: function() {
      return sqltxt.generateScoreQuery('MIN_MAX') +
        ' FROM Score';
    }

  };

}(SQLText || {}));
