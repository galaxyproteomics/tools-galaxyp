//*************************************************** Data Requesting
/**
 * Data request object.
 * Requestor can ask for a canned table query,
 * with limits and filters OR
 * ask for a fully custom SQL result.
 * @constructor
 */

var RequestObject = function() {
  'use strict';
  this.customSQL = '';
  this.tableName = '';
  this.limit = 1000;
  this.offset = 0;
  this.draw = 0;
  this.callBackFn = null;
  this.orderColumn = null;
  this.orderDirection = null;
  this.needCount = false;
  this.actualRecordCount = 0;

  this.makeNameArray = function(rawArray) {
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
};

(function() {
  'use strict';

  RequestObject.prototype.setFullDataCount = function(dataSet) {
    this.actualRecordCount = dataSet.data[1][0];
  };

  RequestObject.prototype.generateColumnNames = function() {
    var returnArray = [];
    var rawColumns = null;

    if (this.customSQL.length > 0) {
      //Column names are in the SELECT --- FROM string
      var str = this.customSQL.slice(this.customSQL.indexOf('SELECT') + 6,
        this.customSQL.indexOf('FROM'));
      rawColumns = str.split(',');
    } else {
      rawColumns = DataManager.tableColumns[this.tableName].map(function(
        currentValue) {
        if ((currentValue.indexOf(':') > -1) || (currentValue.indexOf(
            ' ') > -1)) {
          return this.tableName + '."' + currentValue + '"';
        } else {
          return this.tableName + '.' + currentValue;
        }
      }, this);
    }
    returnArray = this.makeNameArray(rawColumns);
    return returnArray;
  };

  RequestObject.prototype.generateSQL = function(isCount) {
    var returnStr;
    var countQuery = isCount || false;

    if (this.customSQL.length > 0) {
      returnStr = this.customSQL;
    } else {
      returnStr = 'SELECT * FROM ' + this.tableName;
    }
    if (this.orderColumn) {
      if (this.orderColumn.indexOf('Score') > -1) {
        returnStr += ' ORDER BY CAST(' + this.orderColumn + ' AS REAL) ' +
          this.orderDirection;
      } else {
        returnStr += ' ORDER BY ' + this.orderColumn + ' ' +
          this.orderDirection;
      }
    }
    if (this.limit > 0) {
      returnStr += ' LIMIT ' + this.limit + ' OFFSET ' + this.offset;
    }

    if (isCount) {
      returnStr = 'SELECT COUNT(*) FROM (' + this.generateSQL().slice(0,
        this.generateSQL().indexOf('ORDER')) + ')';
    }

    return returnStr;
  };
})();
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
 * Config variables for the current Galaxy data set.
 */
var ConfigurationObject = function() {
  this.href = ''; //href': 'http://localhost:8080',
  this.tableRowCount = {}; //row counts for each table, from the data set
  this.tableColumns = {}; //columns found in each table, from the data set
  this.dataSetID = ''; //'datasetID': '55504e7a2466a2e3',
};

/**
 * Manages data requests from requestor to the SQLite data type
 *
 */
var DataManager = (function(dm) {
  'use strict';

  // dm.fillROWithRowCount = function(rawData, confObj) {
  //     console.log("Yoo Hoo");
  // };

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
      ro.recordsFiltered = ro.recordsTotal;
    } else {
      ro.recordsTotal = confObj.actualRecordCount;
      ro.recordsFiltered = confObj.actualRecordCount;
    }
    ro.data = dataArray;
    return ro;
  };

  dm.executeSQL = function(confObj, urlValue) {
    $.get(urlValue, function(data) {
        confObj.callBackFn(dm.generateResponseObject(data, confObj));
      })
      .error(function(jqXHR, textStatus, errorThrown) {
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
        console.log('ERROR: failed in returning url: ' + urlValue);
        console.log('ERROR: ' + jqXHR.responseText);
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
        requestObject.setFullDataCount(data);
        dm.getData(requestObject);
      });
  };

  /**
   * We have full data count, now get limited and offset data.
   *
   * @param {Object} requestObject
   */
  dm.getData = function(requestObject) {
    var url = DataManager.urlString;

    url += requestObject.generateSQL();
    dm.executeSQL(requestObject, url);
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
    ajaxDataProvider: function(requestData, tableSettings, requestObject,
      callBackFn) {
      var ro = requestObject;

      ro.callBackFn = callBackFn;
      ro.limit = requestData.length;
      ro.offset = requestData.start;
      ro.draw = requestData.draw;

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

//Add some prettiness, helps user read the text
var PrettySQL = (function(ps) {

  var wordList = {
    SELECT: '<font size="4" color="#6A5ACD"><tt>SELECT</tt></font>',
    FROM: '<font size="4" color="#6A5ACD"><tt>FROM</tt></font>',
    WHERE: '<font size="4" color="#6A5ACD"><tt>WHERE</tt></font>',
    'ORDER BY': '<font size="4" color="#6A5ACD"><tt>ORDER BY</tt></font>',
    ASC: '<font size="4" color="#6A5ACD"><tt>ASC</tt></font>',
    DESC: '<font size="4" color="#6A5ACD"><tt>DESC</tt></font>',
    IN: '<font size="4" color="#6A5ACD"><tt>IN</tt></font>',
    AND: '<font size="4" color="#6A5ACD"><tt>AND</tt></font>',
  };

  ps.formatSQL = function(qStr) {

    Object.keys(wordList).map(function(cv) {
      var re = new RegExp('\\b' + cv + '\\b', 'i');
      var repStr = wordList[cv];
      qStr = qStr.replace(re, repStr);
    });
    return qStr;
  };

  return ps;
}(PrettySQL || {}));

var SavedQueryManager = (function(sqm) {

  var DELIM = '<NEWQUERY>';

  sqm.getExistingQueries = function(apiID) {
    var existingQueries = [];
    if (localStorage[apiID]) {
      existingQueries = localStorage[apiID].split(DELIM);
    }
    return existingQueries;
  };

  sqm.resetQueries = function(apiID, qArray) {
    var qStr = '';

    if (qArray.length > 0) {
      qArray.map(function(cv) {
        qStr += cv + DELIM;
      });
      //trim trailing DELIM
      qStr = qStr.slice(0, qStr.lastIndexOf('<NEWQUERY>'));
    } else {
      qStr = '';
    }

    localStorage[apiID] = qStr;
    sqm.initQueryOptionMenu();
  };

  sqm.isDropInList = function(uiObj) {
    var retValue = false;
    var sqlListBoundingRect = {
      top: 0,
      bottom: 0,
      left: 0,
      right: 0
    };
    var topVal = false;
    var leftVal = false;

    sqlListBoundingRect.top = $('#sqlContent').offset().top;
    sqlListBoundingRect.bottom = $('#sqlContent').offset().top + $(
      '#sqlContent').height();
    sqlListBoundingRect.left = $('#sqlContent').offset().left;
    sqlListBoundingRect.right = $('#sqlContent').offset().left + $(
      '#sqlContent').width();
    if (
      (uiObj.position.top >= sqlListBoundingRect.top) &&
      (uiObj.position.top <= sqlListBoundingRect.bottom)) {
      topVal = true;
    }
    if (
      (uiObj.position.left >= sqlListBoundingRect.left) &&
      (uiObj.position.left <= sqlListBoundingRect.right)) {
      leftVal = true;
    }

    retValue = topVal & leftVal;
    return retValue;
  };

  //Will delete a saved query from localStorage and the DOM
  sqm.dropBehavior = function(ui, event) {
    var qStr = event.target.textContent;
    var thisAPI = DataManager.dataID;
    var existingQueries = sqm.getExistingQueries(thisAPI);

    //if drop is back in the sql list, user has changed their mind--dont delete
    if (sqm.isDropInList(ui)) {
      //User does not want the query deleted.
      return;
    }

    if (existingQueries.length > 0) {
      existingQueries.map(function(cv, idx) {
        if (cv === qStr) {
          existingQueries.splice(idx, 1);
        }
      });
      sqm.resetQueries(thisAPI, existingQueries);
    }
  };

  sqm.queryClick = function(event) {
    $('#sqlText').val(event.target.textContent);
  };

  sqm.generateQueryElement = function(textString) {
    var lElem = $('<li/>').attr('class', 'sQuery').attr('style',
      'cursor: pointer').on('click', function(
      event) {
      sqm.queryClick(event);
    }).draggable({
      helper: 'clone',
      stop: function(event, ui) {
        sqm.dropBehavior(ui, event);
      }
    }).html(PrettySQL.formatSQL(textString));
    return lElem;
  };

  sqm.initQueryOptionMenu = function() {
    'use strict';

    var existingQueries;
    var thisAPI = DataManager.dataID;

    $('#queryList').empty();

    if (localStorage[thisAPI]) {
      existingQueries = localStorage[thisAPI].split(DELIM);
    }

    if (existingQueries) {
      existingQueries.map(function(cv) {
        if (cv.length > 0) {
          $('#queryList').append(sqm.generateQueryElement(cv));
        }
      });
    }
  };

  sqm.populateQueryOptionMenu = function(qStr) {
    $('#queryList').append(sqm.generateQueryElement(qStr));
  };

  //Standardizes query and protects against malefeance.
  sqm.standardizeQuery = function(rawStr) {
    var repls = ['select', 'from', 'where', 'in', 'order by', 'asc',
      'desc'
    ];
    repls.map(function(cv) {
      var re = new RegExp('\\b' + cv + '\\b', 'i');
      rawStr = rawStr.replace(re, cv.toUpperCase());
    });
    return rawStr;
  };

  sqm.saveQuery = function(elmID) {
    'use strict';

    var existingQueries;
    var thisAPI = DataManager.dataID;

    if (localStorage[thisAPI]) {
      existingQueries = localStorage[thisAPI];
      existingQueries += DELIM + sqm.standardizeQuery($('#' + elmID).val());
    } else {
      existingQueries = sqm.standardizeQuery($('#' + elmID).val());
    }

    localStorage[thisAPI] = existingQueries;

    //Now refresh the option element.
    sqm.populateQueryOptionMenu($('#' + elmID).val());
  };

  return sqm;
}(SavedQueryManager || {}));

var TableSchemaWidget = (function(tsw) {
  'use strict';

  //Just building a simple ul for schema
  tsw.buildElement = function(data) {
    var container;
    var li;
    var li2;
    var ul;

    container = $('<ul/>', {
      id: 'chemaContainer'
    });

    Object.keys(data).map(function(x) {
      li = $('<li/>', {
        name: x,
        text: x,
        style: 'cursor: pointer',
        class: 'tableName'
      });
      li.on('click', function(event) {
        if (event.target.firstElementChild.style.display ===
          'none') {
          event.target.firstElementChild.style.display =
            'block';
        } else {
          event.target.firstElementChild.style.display =
            'none';
        }
      });
      li.draggable({
        helper: 'clone'
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
  'use strict';

  //TODO: lets pull this to a utility
  sep.escapeDBFieldNames = function(fName) {
    var charsToEscape = [';', ' ', ':'];
    var dirty = false;
    var retStr = fName;

    charsToEscape.map(function(cv) {
      if (fName.indexOf(cv) > -1) {
        dirty = true;
      }
    });
    if (dirty) {
      retStr = '"' + fName + '"';
    }
    return retStr;
  };

  sep.droppedTableName = function(element) {
    var retStr = 'SELECT ';
    var tblName = element.attr('name');

    element.children().children().each(function(idx) {
      retStr += tblName + '.' + sep.escapeDBFieldNames(this
          .id) +
        ', ';
    });
    retStr = retStr.slice(0, retStr.lastIndexOf(',')) +
      ' FROM ' +
      tblName;
    return retStr;
  };

  sep.dropBehavior = function(event, ui) {
    var currentText = this.value;
    var selClause;
    var sIdx;
    var fromClause;
    var fIdx;
    var whereClause;
    var wIdx;

    //Has user dragged the whole table to the text area
    if (ui.draggable.hasClass('tableName')) {
      this.value = sep.droppedTableName(ui.draggable);
    } else {
      if (currentText.length === 0) {
        this.value = 'SELECT ' + ui.draggable[0].parentNode.id.replace(
          'ul_', '') + '."' + ui.draggable.text() + '" ';
        this.value += ' FROM ' + ui.draggable[0].parentNode.id.replace(
          'ul_', '');
      } else {
        sIdx = currentText.toLocaleUpperCase().indexOf(
          ' SELECT ');
        fIdx = currentText.toLocaleUpperCase().indexOf(' FROM ');
        wIdx = currentText.toLocaleUpperCase().indexOf(
          ' WHERE ');

        selClause = currentText.slice(sIdx + 8, fIdx);
        fromClause = currentText.slice(fIdx + 6, wIdx > -1 ?
          wIdx :
          currentText.length);
        whereClause = wIdx > -1 ? currentText.slice(wIdx + 7,
          currentText
          .length) : '';

        selClause += ', ' + ui.draggable[0].parentNode.id.replace(
          'ul_',
          '') + '."' + ui.draggable.text() + '" ';
        if (fromClause.indexOf(ui.draggable[0].parentNode.id.replace(
            'ul_', '')) === -1) {
          fromClause += ', ' + ui.draggable[0].parentNode.id.replace(
            'ul_', '');
        }
        this.value = 'SELECT ' + selClause + 'FROM ' +
          fromClause +
          ' WHERE ' + whereClause;
      }
    }
  };

  return sep;

}(SQLEditorPopulator || {}));

/**
 * Created by mcgo0092 on 6/3/15.
 */
var SQLDataViewer = (function(sdv) {
  'use strict';

  sdv.createTable = function(requestObject) {

    //clear if table already exists, user has selected a new table for viewing.
    if ($.fn.DataTable.isDataTable('#data_table')) {
      $('#dataGrid').empty();
      $('#copyData').hide();
    }

    $('#copyData').show();
    $('#dataGrid').html(
      '<table cellpadding="0" cellspacing="0" border="0" class="display" ' +
      'id="data_table"></table>'
    );
    $('#data_table').dataTable({
      dom: 'C<"top"i>tr<"bottom"flp><"clear">',
      scrollX: '100%',
      processing: true,
      serverSide: true,
      ajax: function(data, callback, settings) {
        DataManager.ajaxDataProvider(data, settings, requestObject,
          callback);
      },
      columns: requestObject.generateColumnNames(),
    });
  };

  //TODO: refactor
  sdv.createTableForCustomSQL = function(sqlText) {
    //TODO: some security screening here since we have user supplied text.
    var ro = new RequestObject();
    ro.customSQL = sqlText;
    ro.needCount = true;
    sdv.createTable(ro);
  };

  sdv.createTableForSelection = function(tableName) {
    var ro = new RequestObject();
    ro.tableName = tableName;
    ro.sqlEditorBox = $('#sqlText');
    sdv.createTable(ro);
  };

  sdv.configurePageElements = function() {
    $('#copyData').hide();
    $('#copyData').on('click', function() {
      var data = $('#data_table').DataTable();
      var columnNames;
      var copiedData = '';

      data.data().map(function(row) {
        var tmpStr = '';
        Object.keys(row).map(function(cv) {
          tmpStr += row[cv] + ',';
        });
        columnNames = Object.keys(row).toString();
        copiedData += '\n' + tmpStr.slice(0, -1);
      });

      copiedData = columnNames + copiedData;
      window.prompt('Copy to clipboard: Cmd+C, Enter', copiedData);
    });

    $('#tableSchema').append(TableSchemaWidget.generateSchemaWidget(
      DataManager.tableColumns));

    $('#sqlText').droppable({
      accept: '.tableName',
      drop: SQLEditorPopulator.dropBehavior
    });

    $('#savedQueries').on('click', function() {
      $('#sqlContent').slideToggle(500, function() {});
    });

    SavedQueryManager.initQueryOptionMenu();
  };

  sdv.produceVisualization = function(confObj) {

    var dco = new ConfigurationObject();
    var tableSelectElement = $('#availableTables');
    var tableNames = Object.keys(confObj.tableRowCount);
    var i;
    var tableOption;

    $('#mainTitle').text('SQLite Data Type Viewer - ' + confObj.dataName);

    //configure the data management
    dco.dataSetID = confObj.datasetID;
    dco.href = confObj.href;
    dco.tableColumns = confObj.tableColumns;
    dco.tableRowCount = confObj.tableRowCount;
    DataManager.configure(dco);

    //configure the table select options
    for (i = 0; i < tableNames.length; i += 1) {
      tableOption = $('<option/>', {
        value: tableNames[i],
        text: tableNames[i]
      });
      tableSelectElement.append(tableOption);
    }

    tableSelectElement.on('change', function(event) {
      sdv.createTableForSelection(event.target.value);
    });

    $('#fireSQL').on('click', function() {
      sdv.createTableForCustomSQL($('#sqlText')[0].value);
    });

    $('#clearSQL').on('click', function() {
      $('#sqlText').val('');
    });

    //Uses local storage for saving and retrieving custom queries.
    $('#saveSQL').on('click', function() {
      SavedQueryManager.saveQuery('sqlText');
    });

    sdv.configurePageElements();

  };

  return sdv;
}(SQLDataViewer || {}));
