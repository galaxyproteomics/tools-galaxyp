/**
 * Holds objects designed to manage data collection for the app
 */

var SQLText = (function (sqlt) {

    var proteinView = "SELECT " +
            "dbs.accession AS Accession, dbs.description AS Description, count(si.pkid) AS ScanCount " +
            "FROM " +
            "spectrum, peptide, DBSequence dbs, peptideevidence pe, spectrumidentification si, score " +
            "WHERE " +
            "pe.dbsequence_pkid = dbs.pkid AND " +
            "pe.peptide_pkid = peptide.pkid AND " +
            "pe.spectrumidentification_pkid = si.pkid AND " +
            "si.spectrum_pkid = spectrum.pkid AND " +
            "score.spectrumidentification_pkid = si.pkid " +
            "GROUP BY dbs.accession ";
        peptideView = "SELECT " +
            "peptide.sequence As Sequence,count(si.pkid) AS ScanCount " +
            "FROM " +
            "spectrum, peptide, DBSequence dbs, peptideevidence pe, spectrumidentification si, score " +
            "WHERE " +
            "pe.dbsequence_pkid = dbs.pkid AND " +
            "pe.peptide_pkid = peptide.pkid AND " +
            "pe.spectrumidentification_pkid = si.pkid AND " +
            "si.spectrum_pkid = spectrum.pkid AND " +
            "score.spectrumidentification_pkid = si.pkid " +
            "GROUP BY peptide.sequence ";
            //"ORDER BY ScanCount DESC";
        psmFromPeptide = " , pe.isDecoy AS Decoy, si.pkid FROM " +
            "spectrum, peptide, peptideevidence pe, spectrumidentification si, score " +
            "WHERE " +
            "peptide.sequence = REPLACE_PEP_PROT_TEXT AND " +
            "pe.peptide_pkid = peptide.pkid AND " +
            "pe.spectrumidentification_pkid = si.pkid AND " +
            "si.spectrum_pkid = spectrum.pkid AND " +
            "score.spectrumidentification_pkid = si.pkid",
        psmFromProtein = ",dbs.accession, pe.isDecoy AS Decoy, si.pkid " +
            "FROM " +
            "spectrum, peptide, DBSequence dbs, peptideevidence pe, spectrumidentification si, score " +
            "WHERE " +
            "pe.dbsequence_pkid = dbs.pkid AND " +
            "dbs.description = REPLACE_PEP_PROT_TEXT AND " +
            "pe.peptide_pkid = peptide.pkid AND " +
            "pe.spectrumidentification_pkid = si.pkid AND " +
            "si.spectrum_pkid = spectrum.pkid AND " +
            "score.spectrumidentification_pkid = si.pkid",
        psm = ",dbs.accession, si.pkid, pe.isDecoy AS Decoy " +
            "FROM " +
            "spectrum, peptide, DBSequence dbs, peptideevidence pe, spectrumidentification si, score " +
            "WHERE " +
            "pe.dbsequence_pkid = dbs.pkid AND " +
            "pe.peptide_pkid = peptide.pkid AND " +
            "pe.spectrumidentification_pkid = si.pkid AND " +
            "si.spectrum_pkid = spectrum.pkid AND " +
            "score.spectrumidentification_pkid = si.pkid",
        lorikeetPeaksQuery = "SELECT " +
            "p.moz, p.intensity " +
            "FROM " +
            "peaks p,peptideevidence pe,spectrumidentification si " +
            "WHERE " +
            "si.spectrum_pkid = p.spectrum_pkid AND pe.spectrumidentification_pkid = si.pkid AND " +
            "si.pkid = SPECTRUM_ID_PKID LIMIT 1",
        lorikeetModificationsQuery = "SELECT " +
            "m.* FROM peptideevidence pe, modification m, spectrumidentification si " +
            "WHERE " +
            "si.pkid = SPECTRUM_ID_PKID AND pe.peptide_pkid = m.peptide_pkid AND pe.spectrumidentification_pkid = si.pkid",

        queryList = {
            peptide: peptideView,
            protein: proteinView,
            psm: psm,
            psmFromProtein: psmFromProtein,
            psmFromPeptide: psmFromPeptide,
            peaks: lorikeetPeaksQuery,
            modifications: lorikeetModificationsQuery
        };

    sqlt.getQuery = function (queryName) {
        return queryList[queryName].replace(/\s+/g, '+');
    }

    /**
     * Creates a WHERE clause based on filter object created
     * when the user set filter parms
     * @param obj
     */
    sqlt.createWhereClause = function (obj) {
        var wClause = " AND ",
            ops = {
                'MAX': '<=',
                'MIN': '>='},
            prop = null;

        for (prop in obj) {
            if (obj[prop].MAX) {
                wClause += " Score." + "'" + prop + "'" + ops.MAX + obj[prop].MAX + " AND ";
            }
            if (obj[prop].MIN) {
                wClause += " Score." + "'" + prop + "'" + ops.MIN + obj[prop].MIN + " AND ";
            }
        }
        return wClause.slice(0,-5).replace(/\s+/g, '+'); //remove trailing AND, remove spaces
    };

    return sqlt;

} (SQLText || {}));

var SQLCreation = (function (sqlc) {

    var tableByColumn = {};//Used to keep track of column ownership. Needed in order by clause for instance.

    sqlc.generateScoreQuery = function (input, type) {
        var removeFields = ["spectrum_identification_id", "SpectrumIdentification_pkid", "pkid"],
            i = 0,
            scoreQuery = "",
            type = type || "REGULAR";

        for (i = 0; i < input.length; i += 1) {
            if (removeFields.indexOf(input[i]) === -1) {
                tableByColumn[input[i]] = 'Score';
                switch (type) {
                    case "MIN_MAX":
                        scoreQuery += "MAX(CAST(Score.'" + input[i] + "'+as+Number))+AS+'MAX " + input[i] + "',MIN(CAST(Score.'" + input[i] + "'+as+Number))+AS+'MIN " + input[i] + "',";
                        break;
                    case "REGULAR":
                        scoreQuery += "CAST(Score.'" + input[i] + "'+as+Number)+AS+'" + input[i] +  "',";
                        break
                }
            }
        }
        return scoreQuery;
    };

    sqlc.generateScoreRangeQuery = function (confObj) {
        var queryString = 'SELECT ';

        queryString += sqlc.generateScoreQuery(confObj.tableColumns.Score, 'MIN_MAX');
        //remove trailing ","
        queryString = queryString.slice(0,-1);
        queryString += "+FROM+Score+";
        return queryString;
    }

    sqlc.generateDetailQuery = function (configObject) {
        var spectrumFields = [],
            peptideFields = [],
            queryString = 'SELECT ';

        queryString += sqlc.generateScoreQuery(configObject.tableColumns.Score);

        configObject.tableColumns.Spectrum.forEach(function (val) {
            if (!((val === 'pkid') || (val === 'id'))) {
                tableByColumn[val] = 'Spectrum';
                queryString += 'Spectrum.' + val + ",";
            }
        });
        configObject.tableColumns.Peptide.forEach(function (val) {
            if (!((val === 'pkid') || (val === 'id'))) {
                tableByColumn[val] = 'Peptide';
                queryString += 'Peptide.' + val + ",";
            }
        });

        //remove trailing ","
        queryString = queryString.slice(0,-1);
        queryString += SQLText.getQuery(configObject.type);
        return queryString;
    };

    sqlc.tableForColumn = function (colName) {
        return tableByColumn[colName];
    }

    return sqlc;
} (SQLCreation || {}));

var DataProvider = (function (dp) {

    dp.formatSQLiteTable = function (rawData) {
        var x = rawData.data.splice(0, 1),
            rbv = null,
            cNames = [],
            i = 0;

        for (i = 0; i < x[0].length; i += 1) {
            cNames.push({
                "title": x[0][i],
                "visible": x[0][i] === 'pkid' ? false : true
            });
        }

        rbv = { 'columns': cNames, 'rows': rawData.data};
        return rbv;
    };

    dp.executeSQL = function (callBack, urlValue, additionalData) {
        var extraReturnData = additionalData || null;
        $.get(urlValue, function (data) {
            var fData = DataProvider.formatSQLiteTable(data);
            if (extraReturnData) {
                callBack(fData, extraReturnData);
            } else {
                callBack(fData);
            }
        })
            .error(function (jqXHR, textStatus, errorThrown) {
                SQLDataTypeViewer.currentDataView().busySpinner.stop();
                //Flash a quick modal message here
                var dg = $('<div>', {
                    id: "ajax_error",
                    title: "Query Error",
                }),
                    msg = $('<p>', {
                        text: jqXHR.responseText
                    });

                dg.dialog({
                    minWidth: 200,
                    height: 200
                });
                dg.append(msg);
                setTimeout(function() { dg.dialog('close'); }, 5000);
                console.log("ERROR: failed in returning url: " + urlValue);
                console.log("ERROR: " + jqXHR.responseText);
            });
    };

    /**
     * Retrieve modification data for a scan
     */
    dp.retrieveModificationData = function (confObj) {
        var url = confObj.href + '/api/datasets/' + confObj.datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        url += SQLText.getQuery('modifications');
        url = url.replace("SPECTRUM_ID_PKID", confObj.lmID);
        DataProvider.executeSQL(confObj.callBack, url, confObj);
    };

    /**
     * Ajax call to Galaxy to retrieve scan peak data.
     * @param confObj
     */
    dp.retrieveScanPeaks = function (confObj) {
        var url = confObj.href + '/api/datasets/' + confObj.datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        url += SQLText.getQuery('peaks');
        url = url.replace("SPECTRUM_ID_PKID", confObj.lmID);
        DataProvider.executeSQL(confObj.callBack, url, confObj);
    };

    /**
     * Ajax call to retrive PSM values based on a specific
     * protein or peptide
     *
     * @param callBackfn
     */
    dp.retrievePSMDetail = function (callBackfn) {
        var url,
            queryString = "SELECT ";

        url = SQLDataTypeViewer.currentDataView().href + '/api/datasets/' +
            SQLDataTypeViewer.currentDataView().datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        queryString += SQLCreation.generateScoreQuery(SQLDataTypeViewer.currentDataView().tableColumns.Score);

        SQLDataTypeViewer.currentDataView().tableColumns.Spectrum.forEach(function (val) {
            if (!((val === 'pkid') || (val === 'id'))) {
                queryString += 'Spectrum.' + val + ",";
            }
        });
        SQLDataTypeViewer.currentDataView().tableColumns.Peptide.forEach(function (val) {
            if (!((val === 'pkid') || (val === 'id'))) {
                queryString += 'Peptide.' + val + ",";
            }
        });

        //remove trailing ","
        queryString = queryString.slice(0,-1);
        queryString += SQLText.getQuery(SQLDataTypeViewer.currentDataView().name);
        queryString = queryString.replace("REPLACE_PEP_PROT_TEXT", ('"' + SQLDataTypeViewer.currentDataView().pepProtText + '"'));
        url += queryString.replace(/\s+/g, '+');
        SQLDataTypeViewer.currentDataView().name = 'psm';
        DataProvider.executeSQL(callBackfn, url);
    };

    /**
     * Ajax call to Galaxy data provider.
     *  - Query for record set OR
     *  - Query for score range OR
     *  - Query for record set with WHERE clause
     *
     * @param confObj
     */
    dp.retrieveData = function (confObj) {
        //build URL
        var url = confObj.href + '/api/datasets/' + confObj.datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=',
            QUERY_LIMIT = confObj.limit || 0,
            QUERY_OFFSET = confObj.offset || 0,
            WHERE_CLAUSE_OBJ = confObj.whereFilter || null,
            COUNT_ONLY = confObj.countOnly || false,
            ORDER_BY = confObj.orderBy || null;

        if (confObj.scoreRange) {
             url += SQLCreation.generateScoreRangeQuery({'tableColumns': confObj.tableColumns});
        } else if ((confObj.type === 'protein') || (confObj.type === 'peptide')) {
            var queryStr = SQLText.getQuery(confObj.type);
            if (COUNT_ONLY) {
                queryStr = "SELECT+COUNT(*)+FROM+(" + queryStr + ")";
                COUNT_ONLY = false;
            }
            url += queryStr;
        } else {
            url += SQLCreation.generateDetailQuery({
                'tableColumns': confObj.tableColumns,
                'type': confObj.type})
        }

        if (WHERE_CLAUSE_OBJ) {
            url +=  SQLText.createWhereClause(WHERE_CLAUSE_OBJ);
        }

        if (ORDER_BY) {
            switch (ORDER_BY[0]) {
                case 'ScanCount':
                case 'Accession':
                case 'Sequence':
                case 'Description':
                case 'Decoy':
                    url += '+ORDER+BY+' + ORDER_BY[0] +  '+' + ORDER_BY[1];
                    break;
                default:
                    url += '+ORDER+BY+' + SQLCreation.tableForColumn(ORDER_BY[0]) + '."' + ORDER_BY[0] + '"+' + ORDER_BY[1];
            }
        }

        if (QUERY_LIMIT != 0) {
            url += "+LIMIT+" + QUERY_LIMIT;
        }
        if (QUERY_OFFSET != 0) {
            url += "+OFFSET+" + QUERY_OFFSET;
        }

        if (COUNT_ONLY) {
            url = [url.slice(0, url.indexOf('SELECT') + 7), 'COUNT(*)', url.slice(url.indexOf('+FROM'))].join('')
        }

        console.log("URL IS NOW" + url);

        DataProvider.executeSQL(confObj.callBack, url);
    };

    //User wants peptides containing sepcified sequence.
    dp.retrieveSpecificPeptide = function (targetSequence) {
        var currentState = SQLDataTypeViewer.currentDataView(),
            sequenceList, queryStr,
            likeClause = "select peptide.sequence from peptide where peptide.sequence LIKE ", i,
            url;

        url = currentState.href + '/api/datasets/' + currentState.datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        queryStr = "SELECT DISTINCT peptide.sequence AS Sequence FROM peptide WHERE Sequence in (LIST_VALUES)";

        if (targetSequence) {
            //User has provided a list of 1 or more target sequences
            sequenceList = targetSequence.split(',').map(function (cv,index,array) {return cv.trim()});
            for (i = 0; i < sequenceList.length; i += 1) {
                likeClause += "'%25" + sequenceList[i] + "%25' OR peptide.sequence LIKE ";
            }
            likeClause = likeClause.slice(0, likeClause.lastIndexOf('OR'));
            queryStr = queryStr.replace("LIST_VALUES", likeClause);
            url += queryStr;
            console.log('Query with ' + url);
            currentState.busySpinner.spin(document.getElementById('spinHere'));
            DataProvider.executeSQL(SQLDataTypeViewer.manageReturnedData, url);

        }

    };

    //User wants proteins based on accession values or description
    dp.retrieveSpecificProtein = function (confObj) {
        var currentState = SQLDataTypeViewer.currentDataView(),
            accessionList, queryStr,
            likeClause = "select dbsequence.accession from dbsequence where dbsequence.accession LIKE '",
            url;

        url = currentState.href + '/api/datasets/' + currentState.datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        queryStr = "SELECT DISTINCT dbs.accession AS Accession, dbs.description AS Description FROM DBSequence dbs WHERE " +
                        "Accession in (LIST_VALUES)";



        if (confObj.accession) {
            //User is filtering on accession. Create a trimmed list of 1 or more accessions
            accessionList = confObj.accession.split(',').map(function (cv,index,array) {return cv.trim()});
            for (i = 0; i < accessionList.length; i += 1) {
                likeClause += accessionList[i] + "%'" + " OR dbsequence.accession LIKE '";
            }
            likeClause = likeClause.slice(0, likeClause.lastIndexOf('OR'));
            queryStr = queryStr.replace("LIST_VALUES", likeClause);
            url += queryStr;
            console.log('Query with ' + url);
            currentState.busySpinner.spin(document.getElementById('spinHere'));
            DataProvider.executeSQL(SQLDataTypeViewer.manageReturnedData, url);
        }

        if (confObj.description) {
            console.log('Description: ' + confObj.description);
        }

    };

    return dp;
} (DataProvider || {}));

/**
 * Lorikeet data factory.
 */
var LorikeetFactory = (function (lf) {

    lf.inProgressModel = null;
    lf.completeFunction = null;
    lf.configurationSteps = [];

    function LorikeetModel() {
        this.properties = {
            showInternalIonOption: true,
            showMHIonOption: true,
            showAllTable: true,
            peakDetect: false,
            "scanPKID": null,
            "sequence": null,
            "staticMods": [],
            "variableMods": [],
            "ntermMod": 0, // additional mass to be added to the n-term
            "ctermMod": 0, // additional mass to be added to the c-term
            "peaks": [],
            "massError": 0.5,
            "scanNum": null,
            "fileName": null,
            "charge": null,
            "precursorMz": null,
            "ms1peaks": [],
            "ms1scanLabel": null,
            "precursorPeaks": null,
            "precursorPeakClickFn": null,
            "zoomMs1": false,
            "width": 750, 	  // width of the ms/ms plot
            "height": 450, 	  // height of the ms/ms plot
            "extraPeakSeries": []
        };
    }

    //determines if we have modifications present
    LorikeetModel.prototype.setModification = function () {
        if (this.modNum > 0) {
            console.log("We have modifications -- need to query");
        }
    };

    //Sets peaks for either the MS2 or MS1 peaks.
    LorikeetModel.prototype.setPeaks = function (mozArray, intensityArray, mslevel) {
        if (mslevel === 2) {
            this.properties.peaks = _.zip(mozArray, intensityArray);
        } else {
            this.properties.ms1peaks = _.zip(mozArray, intensityArray);
        }
    }

    //Lorikeet visualization code needs a JSON object
    LorikeetModel.prototype.getOptions = function () {
        var options = {},
            prop = null;
        for (prop in this.properties) {
            options[prop] = this.properties[prop];
        }
        return options;
    };

    lf.configurationComplete = function () {
        //this is done on completion.
        LorikeetFactory.completeFunction(LorikeetFactory.inProgressModel);
        LorikeetFactory.configurationSteps = [];
        LorikeetFactory.inProgressModel = null;
    };

    lf.configurePeaks = function (peakData, confObj) {
        var moz = JSON.parse(peakData.rows[0][0]),
            intensity = JSON.parse(peakData.rows[0][1]);
        LorikeetFactory.inProgressModel.setPeaks(moz, intensity, confObj.msLevel); //mslevel will vary

        if (LorikeetFactory.configurationSteps.length > 0) {
            LorikeetFactory.setPeaksAndMods();
        } else {
            LorikeetFactory.configurationComplete();
        }

    };

    lf.configureModifications = function(data, confObj) {
        var indexVals = {},
            lorikeetMods = [],
            i;

        data.columns.map(function(cv, index, array) {
            indexVals[cv.title] = index;
        });

        for (i = 0; i < data.rows.length; i += 1) {
            lorikeetMods.push({
                index: data.rows[i][indexVals.location],
                modMass: data.rows[i][indexVals.monoisotopicMassDelta],
                aminoAcid: data.rows[i][indexVals.residues]
            });
        }

        LorikeetFactory.inProgressModel.properties.variableMods = lorikeetMods;

        if (LorikeetFactory.configurationSteps.length > 0) {
            LorikeetFactory.setPeaksAndMods();
        } else {
            LorikeetFactory.configurationComplete();
        }
    };

    lf.setPeaksAndMods = function () {

        var step = LorikeetFactory.configurationSteps.shift(),
            msLevel = {'ms2': 2, 'ms1': 1};

        console.log("Performing configuration step: " + step);

        if ((step === 'ms2') || (step === 'ms1')) {
            //Get MS2 peaks first, then MS1 if it exists.
            DataProvider.retrieveScanPeaks({
                href: SQLDataTypeViewer.currentDataView().href,
                datasetID: SQLDataTypeViewer.currentDataView().datasetID,
                callBack: LorikeetFactory.configurePeaks,
                lmID: LorikeetFactory.inProgressModel.properties.scanPKID,
                msLevel: msLevel[step]
            });
            if (step === 'ms1') {
                LorikeetFactory.inProgressModel.properties.zoomMs1 = true;
            }
        }

        if (step === 'mods') {
            console.log('Looking for mods');
            DataProvider.retrieveModificationData({
                href: SQLDataTypeViewer.currentDataView().href,
                datasetID: SQLDataTypeViewer.currentDataView().datasetID,
                callBack: LorikeetFactory.configureModifications    ,
                lmID: LorikeetFactory.inProgressModel.properties.scanPKID,
            });
        }
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

     * @returns {LorikeetModel}
     */
    lf.createLorikeetModel = function (dataRow, callBackFn) {
        var lm = new LorikeetModel();

        lm.properties.scanPKID = dataRow.pkid;
        lm.properties.sequence = dataRow.sequence;
        lm.properties.scanNum = dataRow.acquisitionNum;
        lm.properties.charge = dataRow.precursorCharge;
        lm.properties.precursorMz = dataRow.precursorMZ;
        lm.properties.fileName = dataRow.title;
        lm.properties.modNum = dataRow.modNum;
        lm.properties.precursorScanNumber = dataRow.precursorScanNum;

        LorikeetFactory.completeFunction = callBackFn;
        LorikeetFactory.inProgressModel = lm;
        LorikeetFactory.configurationSteps.push('ms2');

        if (lm.properties.precursorScanNumber > 0) {
            LorikeetFactory.configurationSteps.push('ms1');
        }

        if (lm.properties.modNum > 0) {
            LorikeetFactory.configurationSteps.push('mods');
        }

        LorikeetFactory.setPeaksAndMods();
    }

    return lf;
}(LorikeetFactory || {}));