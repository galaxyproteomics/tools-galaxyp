//Lorikeet tab management code
var MSMSTabManager = (function (msTM) {
    msTM.MAX_TABS = 10;
    msTM.activeTabs = {};

    if (Object.keys(msTM.activeTabs).length === 0) {
        $("#tabs").tabs({
            activate: function (event, ui) {
                var active = $('#tabs').tabs('option', 'active');
            }
        });

    }

    msTM.activateTab = function (sequence, scanNum) {
        var liElement,
            divElement,
            divSpecViewer,
            tabText = sequence + " <small>" + scanNum + "</small>";

        if (Object.keys(msTM.activeTabs).length < this.MAX_TABS) {
            if (tabText in msTM.activeTabs) {
                console.log('Scan is already graphed. Nothing to do');
                return null;
            }
            liElement = $('<li/>', {'id': tabText});
            liElement.append("<a href='#tab" + Object.keys(msTM.activeTabs).length + "'>" + tabText + "</a>");
            $("div#tabs ul").append(liElement);
            divElement = $('<div/>', {'id': 'tab' + Object.keys(msTM.activeTabs).length});
            divSpecViewer = $('<div/>', {'id': 'lorikeet' + Object.keys(msTM.activeTabs).length});
            divElement.append(divSpecViewer);
            $("div#tabs").append(divElement);
            $("div#tabs").tabs({
                event: "mouseover"
            });
            $("div#tabs").tabs().find( ".ui-tabs-nav" ).sortable({
                axis: "x",
                stop: function() {
                    $("div#tabs").tabs( "refresh" );
                }
            });
            $("div#tabs").tabs("refresh");
            msTM.activeTabs[tabText] = {'liElement': liElement, 'divElement': divElement};
            return divSpecViewer;

        } else {
            console.log('ERROR: Opening too many tabs. Limit is ' + msTM.MAX_TABS);
            return null;
        }
    };

    msTM.deactivateTab = function (sequence, scanNum) {
        var liElement,
            divElement,
            tabText = sequence + " <small>" + scanNum + "</small>";
        if (tabText in msTM.activeTabs) {
            liElement = msTM.activeTabs[tabText]['liElement'];
            divElement = msTM.activeTabs[tabText]['divElement'];
            liElement.remove();
            divElement.remove();
            delete msTM.activeTabs[tabText];
        } else {
            console.log('ERROR: ' + tabText + ' not present in activeTabs');
        }
    };

    msTM.clearAllActiveTabs = function () {
        var tabText = "",
            divElement,
            liElement;

        for (tabText in msTM.activeTabs) {
            liElement = msTM.activeTabs[tabText]['liElement'];
            divElement = msTM.activeTabs[tabText]['divElement'];
            liElement.remove();
            divElement.remove();
            delete msTM.activeTabs[tabText];
        }
    }

    return msTM;
}(MSMSTabManager || {}));

var ScoreFilterManager = (function (sfm) {
    //Score array will have min and max input elements ready for table packaging.
    sfm.generateScoreFilterTable = function (scoreArray, callBackFn) {
        var contain = $('<div/>',{
                id: 'score_table',
                class: 'grid-100 grid-parent'
            }),
            filterButton = $('<button>', {
                class: 'submit',
                text: 'Filter By Scores'
            }),
            i, anElem, label;

        filterButton.on('click', callBackFn);

        $('<p class="grid-100"><strong>Filter PSMs by Score</strong></p>').appendTo(contain);
        $('<div class="clear"></div>').appendTo(contain);


        for (i = 0; i < scoreArray.length; i += 2) {
            label = scoreArray[i][0].name;
            label = label.slice(label.indexOf("_") + 1);
            anElem = $('<div/>', {
                class: 'grid-50 suffix-50'
            });
            anElem.append(label);
            contain.append(anElem);

            anElem = $('<div/>', {
                class: 'grid-5'
            });
            label = scoreArray[i][0].name.split("_")[0];
            anElem.append(label);
            contain.append(anElem);

            anElem = $('<div/>', {
                class: 'grid-45'
            });
            anElem.append(scoreArray[i]);
            contain.append(anElem);

            anElem = $('<div/>', {
                class: 'grid-5'
            });
            label = scoreArray[i + 1][0].name.split("_")[0];
            anElem.append(label);
            contain.append(anElem);

            anElem = $('<div/>', {
                class: 'grid-45'
            });
            anElem.append(scoreArray[i + 1]);
            contain.append(anElem);

            $('<div class="clear"></div>').appendTo(contain);

        }

        anElem = $('<div/>', {
            class: 'grid-50'
        });
        anElem.append(filterButton);
        contain.append(anElem);

        return contain;
    };

    return sfm;
} (ScoreFilterManager || {}));

var TextFilterManager = (function (tfm) {
    //TODO: task marked for refactor. Between peptide and protein
    tfm.generatePeptideFilterDiv = function () {
        var divElement = $('<div/>', {
                id: 'textFilter',
                class: 'grid-50 grid-parent'
            }),
            filterButton = $('<button>', {
                class: 'submit',
                text: 'Filter Peptides',
            }),
            inputSequence = $('<input/>', {
                type: 'search',
                title: 'Enter one sequence or a comma separated list of sequences.',
                id: 'filter_text',
                width: '100%'
            }),
            labelSequence = $('<label/>', {
                text: "Find peptides by sequence(s)"
            }),content = $('<table>'),
            anElem;

        inputSequence.on('search', function () {
            if (!inputSequence.val()) {
                console.log("Clearing search");
                ViewSelectFunctions.preparePeptideView();
            }
        })

        filterButton.on("click", function() {
            DataProvider.retrieveSpecificPeptide($('#filter_text').val());
        });

        $('<p class="grid-100 align-center"><strong>Filter Peptides</strong></p>').appendTo(divElement);

        anElem = $('<div/>', {class: "grid-25"});
        anElem.append(labelSequence);
        anElem.after(divElement).appendTo(divElement);
        anElem = $('<div/>', {class: "grid-75"});
        anElem.append(inputSequence);
        anElem.appendTo(divElement);
        $('<div class="clear"></div>').appendTo(divElement);


        $('<div class="clear"></div>').appendTo(divElement);
        anElem = $('<div/>', {class: "grid-50"});
        anElem.append(filterButton);
        anElem.after(divElement).appendTo(divElement);

        return divElement;

    };

    tfm.generateProteinFilterDiv = function () {
        var divElement = $('<div/>', {
                id: 'textFilter',
                class: 'grid-50 grid-parent'
            }),
            filterButton = $('<button>', {
                class: 'submit',
                text: 'Filter Proteins',
            }),
            inputAccession = $('<input/>', {
                type: 'search',
                title: 'Enter one accession or comma separated list of accessions.',
                id: 'input_accession',
                width: '100%'
            }),
            labelAccession = $('<label/>', {
                text: "Find protein by accession(s)"
            }),
            inputDescription = $('<input/>', {
                type: 'search',
                id: 'input_description',
                placeholder: 'Not Implemented'
            }),
            labelDescription = $('<label/>', {
                text: "Find protein by description"
            }),
            anElem;

        filterButton.on("click", function() {
            DataProvider.retrieveSpecificProtein({accession: $('#input_accession').val()});
        });

        inputAccession.on('search', function() {
            console.log('Search event fired');
            if (!inputAccession.val()) {
                console.log("Clearing search");
                ViewSelectFunctions.prepareProteinView();
            }
        });

        $('<p class="grid-100 align-center"><strong>Filter Proteins</strong></p>').appendTo(divElement);
        anElem = $('<div/>', {class: "grid-25"});
        anElem.append(labelAccession);
        anElem.after(divElement).appendTo(divElement);
        anElem = $('<div/>', {class: "grid-75"});
        anElem.append(inputAccession);
        anElem.appendTo(divElement);

        anElem = $('<div/>', {class: "grid-25"});
        anElem.append(labelDescription);
        anElem.after(divElement).appendTo(divElement);
        anElem = $('<div/>', {class: "grid-75"});
        anElem.append(inputDescription);
        anElem.appendTo(divElement);
        anElem = $('<div/>', {class: "grid-50"});
        anElem.append(filterButton);
        anElem.after(divElement).appendTo(divElement);
        return divElement;

    };

    return tfm;
} (TextFilterManager || {}));

var GridToggle = (function (gt) {

    myDivs = {
        'toggleDataGrid': { visible: "Hide", divs: ['dataGrid', 'score_table', 'pageSlider']},
        'toggleProtPepGrid': {visible: "Hide", divs: ['protPepGrid', 'textFilter' ]}
    };

    isVisible = true;

    gt.toggleDivs = function (event) {
        var elem = $('#' + event.toElement.id),
            command = event.toElement.textContent,
            idName = event.toElement.id,
            divs = myDivs[event.toElement.id].divs;

        if (command === "Show") {
            myDivs[idName].visible = 'Show';
            elem.html("Hide");
        } else {
            myDivs[idName].visible = 'Hide';
            elem.html("Show")
        }


        divs.map(function (cv, idx, array) {
            var elem = document.getElementById(cv);
            if (elem) {
                if (myDivs[idName].visible === "Show") {
                    elem.style.display = 'block';
                } else {
                    elem.style.display = 'none';
                }
            }
        });
    };


    return gt;
} (GridToggle || {}));