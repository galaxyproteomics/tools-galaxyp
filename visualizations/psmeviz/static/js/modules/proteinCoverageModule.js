var SQLFunctions = (function (sf) {

    sf.proteinPepCoverage = "SELECT " +
            "dbs.accession, dbs.description, dbs.pkid, pe.dbsequence_pkid, pe.start, pe.end, " +
            "pe.pre, pe.post,peptide.sequence as PeptideSeq, dbs.sequence as Protsequence, SCORE_COLUMNS " +
            "FROM " +
            "spectrum, peptide, DBSequence dbs, peptideevidence pe, spectrumidentification si, score " +
            "WHERE " +
            "pe.dbsequence_pkid = dbs.pkid AND pe.peptide_pkid = peptide.pkid AND " +
            "pe.spectrumidentification_pkid = si.pkid AND si.spectrum_pkid = spectrum.pkid AND " +
            "score.spectrumidentification_pkid = si.pkid AND " +
            "dbs.accession = 'PROTEIN_ACCESSION'";

    sf.cleanScoreFields = function () {
        var scoreColumns = SQLDataTypeViewer.currentDataView().tableColumns.Score,
        //["pkid", "spectrum_identification_id", "SpectrumIdentification_pkid", "Mascot:identity threshold", "Mascot:score", "Scoffold:Peptide Probability"]
            dropColumns = ["pkid", "spectrum_identification_id", "SpectrumIdentification_pkid"],
            editedColumns = [],
            returnStr = '';
        scoreColumns.filter(function (value) {
            if (dropColumns.indexOf(value) === -1) {
                editedColumns.push(value);
            }
        });
        //Array to select string
        editedColumns.map(function(cv,index,array) {
            returnStr += "Score.'" + cv + "' AS 'Score%" + cv + "',"});
        //remove trailing ','
        return returnStr.slice(0,-1);;
    };

    sf.formatCoverageData = function (rawData) {
        var fmtData = DataProvider.formatSQLiteTable(rawData),
            protCoverage = ProteinCoverageManager.buildProteinCoverage(fmtData);

        return protCoverage;
    };

    sf.executeSQL = function (callBack, urlValue, additionalData) {
        var extraReturnData = additionalData || null;
        $.get(urlValue, function (data) {
            var obj = SQLFunctions.formatCoverageData(data)
            if (extraReturnData) {
                callBack(obj, extraReturnData);
            } else {
                callBack(obj);
            }
        })
            .fail(function () {
                console.log("ERROR: failed in returning url: " + urlValue);
            });
    };



    return sf;
} (SQLFunctions || {}));

var ProteinCoverageManager = (function (pcm) {

    //Object for peptides
    function Peptide(rawObj) {
    //rawObj keys-> ["accession", "description", "pkid", "DBSequence_pkid", "start", "end", "pre", "post", "PeptideSeq", "Protsequence", "Score%Mascot:identity threshold", "Score%Mascot:score", "Score%Scoffold:Peptide Probability"]
    //Only want peptide information.
        var prop;

        this.sequence = rawObj.PeptideSeq;
        this.start = rawObj.start;
        this.end = rawObj.end;
        this.pre = rawObj.pre;
        this.post = rawObj.post;
        this.scores = {};

        for (prop in rawObj) {
            if (prop.search('Score%') > -1) {
                this.scores[prop.slice(6)] = rawObj[prop];
            }
        }
    }

    Peptide.prototype.scoresAsString = function () {
        var rtString = '',
            prop;
        for (prop in this.scores) {
            rtString += prop + " : " + this.scores[prop] + " ";
        }
        return rtString;
    }

    //Basic object holding all the peptide coverage information for a given protein.
    function ProteinCoverage() {
        this.proteinAccessionNumber = null;
        this.proteinSequence = null;
        this.proteinDescription = null;
        //peptides associated with this protein
        this.peptides = [];
    }

    ProteinCoverage.prototype.maximumPepOffset = function () {
        var maxOffset = 0;
        this.peptides.map(function (cv, index, arr) {
            if (cv.end > maxOffset) {
                maxOffset = cv.end;
            }
        });
      return maxOffset;
    };

    /**
     * Proteins may or may not have a sequence found in the original data.
     * If sequence is present, return sequence
     * Else,
     * Return a string of X characters that is one longer the the maximum
     * peptide end offset.
     */
    ProteinCoverage.prototype.sequence = function () {
        var seqStr = '',
            pepOffset = 0,
            i = 0;
        if (this.proteinSequence) {
            seqStr = this.proteinSequence;
        } else {
            pepOffset = this.maximumPepOffset();
            for (i = 0; i < (pepOffset + 2); i += 1) {
                seqStr += "X";
            }
        }
        return seqStr;
    };

    pcm.coverageObjects = {};

    /**
     * Creates an obj
     * @param dataSet is formatted from SQLite table return
     */
    pcm.buildProteinCoverage = function (fmtData) {
        var colNames = [],
            newPC = new ProteinCoverage(),
            tmpObj;

        fmtData.columns.map(function(cv,idx,arr){
            colNames.push(cv.title)
        });
        fmtData.rows.map(function(cv,idx,arr) {
            newPC.peptides.push(new Peptide(_.object(colNames, cv)));
        });

        tmpObj = _.object(colNames,fmtData.rows[0])
        newPC.proteinAccessionNumber = tmpObj.accession;
        newPC.proteinDescription = tmpObj.description;
        newPC.proteinSequence = tmpObj.Protsequence;


        return newPC;
    };

    pcm.coverageForProtein = function (accessionNumber, callBackFn) {
        var url = SQLDataTypeViewer.currentDataView().href + '/api/datasets/' +
            SQLDataTypeViewer.currentDataView().datasetID + '?data_type=raw_data&provider=sqlite-table&headers=True&query=';
        url += SQLFunctions.proteinPepCoverage;
        url = url.replace("PROTEIN_ACCESSION", accessionNumber);
        url = url.replace("SCORE_COLUMNS", SQLFunctions.cleanScoreFields());

        SQLFunctions.executeSQL(callBackFn, url);
    };

    return pcm;
} (ProteinCoverageManager || {}));