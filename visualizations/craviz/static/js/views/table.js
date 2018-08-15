define([],
	function(){
		return Backbone.View.extend({

			className : 'right-cell',

			events: {
				//'click tbody tr' : 'loadViewer',
			},

			initialize: function(options){
				this.name = options.name;
				this.model.on('change:shownHeaders',this.refreshHeaders, this);
				this.firstRun = true;
				this.frameViewer = options.frameViewer;
				this.render();
				if (this.model.name == 'Gene'){
					//this.model.collection.at(2).on('change:Gene Data', this.loadGeneTable, this);
				}
				//this.dataTable = $('#' + this.name).DataTable();
			},

			render : function(){
				$view = $('<div>', {'class' : 'table-view'});
				$table = $('<div>', {'class' : 'dataTableView'});

				this.$selectedPanel = $('<div>', {'class' : 'selected-panel'});
				$table.append(this.$selectedPanel);
				var panelClass = this.frameViewer ? ' top-panel' : '';
				$table.append('<div id="' + this.name + 'DataTable" class="data-table ' + panelClass +'" style="display: none;"><table id="' + this.name + '"></table></div>');	
				//$table = $('<div>', {'class' : 'table-view'});
				/*if (this.name == 'Gene'){
				} else {
				}*/
				$view.append($table);
				if (this.model.name == 'Variant'){
					$view.append("<div class='frame'><iframe id='variantviewer'></iframe></div>");
					//$('.frame').
				} else if (this.model.name == 'Gene'){
					$view.append('<table id="example"></table>');
					console.log('Rendered gene table');
					//this.loadGeneTable();
				}
				this.$el.append($view);
				//$('.dataTableView').resizable();

				//var content = '<thead><tr><th>Name</th><th>Position</th><th>Office</th><th>Extn.</th><th>Start date</th><th>Salary</th></tr></thead><tfoot><tr><th>Name</th><th>Position</th><th>Office</th><th>Extn.</th><th>Start date</th><th>Salary</th></tr></tfoot>';
				//this.$el.append('<div id="' + this.name + 'DataTable" class="data-table ' + panelClass +'" style="display: none;"><table id="' + this.name + '">' + content + '</table></div>');	
			},

			loadingIndicator : function(){
				console.log('Loading indicator');
				this.$el.html('<div class="indicator"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div>');
			},

			loadGeneTable : function(row_data){
				console.log('Loading gene table!');
				if (row_data.length >= 8){
					var gene = row_data[8];
				} else {
					// Initialize table
					console.log('Initializing table');
					var dataset = this.model.collection.at(2).get('Gene data');
					if (dataset){
						var headers = this.formatToDataTableHeader(dataset.shift());
						$('table#example').DataTable({
							data : dataset,
							columns : headers
						});
					}
				}
				
				/*$('#gene-table').DataTable( {
					data : dataset,
					columns: headers
				});*/
			},

			loadTable : function(ID){
				// Initializes the table
				this.dataTable = $('#' + this.name);
				console.log('Loading data for ' + this.name);

				var view = this;
				var data = this.model.get('data');
				//var tableData = (data.length > 100) ? data.slice(0, 100) : data;
				var tableData = data;

					//$(document).ready(function() {
		                //$('#' + this.name).DataTable( {

				if ( $.fn.dataTable.isDataTable( this.dataTable ) ){
					this.dataTable.DataTable().destroy();
					console.log('Destroying ' + this.name);
				}

		        var allHeaders = this.model.get('All headers');
		        /*if (allHeaders.indexOf('Chromosome') > 0){
		        	allHeaders[allHeaders.indexOf('Chromosome')] = 'Chromosome';
		        	//this.model.set('All headers', allHeaders);
		        }*/
		        var headers = '<tr><th>' + allHeaders.join('</th><th>') + '</th></tr>';
		        //headerHTML = '<thead>' + headers + '</thead><tfoot>' + headers + '</tfoot>';
		        headerHTML = '<thead>' + headers + '</thead>';
		        $('#' + this.name + 'DataTable').show();
		        $('#' + this.name).html(headerHTML);

		        var data = [];
		        for ( var i=0 ; i<50000 ; i++ ) {
		            data.push( [ i, i, i, i, i ] );
		        }

		        jQuery.fn.dataTableExt.oSort['mystring-asc'] = function(x,y) {
					var retVal;
					x = $.trim(x);
					y = $.trim(y);

					if (x==y) retVal= 0;
					else if (x == "" || x == " ") retVal= 1;
					else if (y == "" || y == " ") retVal= -1;
					else if (x > y) retVal= 1;
					else retVal = -1; // <- this was missing in version 1

					return retVal;
				}
				jQuery.fn.dataTableExt.oSort['mystring-desc'] = function(y,x) {
					var retVal;
					x = $.trim(x);
					y = $.trim(y);

					if (x==y) retVal= 0; 
					else if (x == "" || x == " ") retVal= -1;
					else if (y == "" || y == " ") retVal= 1;
					else if (x > y) retVal= 1;
					else retVal = -1; // <- this was missing in version 1

					return retVal;
				}
				sorting_index = allHeaders.indexOf('VEST p-value') >= 0 ? allHeaders.indexOf('VEST p-value') : 0;


                this.dataTable.DataTable( {
                    "ajax": {
                        "url": '/api/datasets/' + this.model.get('ID'),
                        //"url" : 'templates/arrays.txt',
                        contentType: 'application/json; charset=utf-8',
                        dataType : 'json',
                        "data": {data_type : 'raw_data',
                            provider : 'column',
                            limit : 100000,
                            offset: 1},
	                    'dataSrc' : function (json) {
	                    	// Fill ins missing trailing data with blanks

	                    	var returned_data = new Array();
	                    	var length = allHeaders.length;
	                    	var diff;
	                    	var data = json.data;
	                    	for (var i = 0; i < data.length; i++){
	                    		diff = length - data[i].length;
	                    		if (diff > 0){
	                    			for (var n = 0; n < diff; n++){
	                    				data[i].push('');
	                    			}
	                    		}
	                    		returned_data.push(data[i]);
	                    	}
	                    	//var new_json = {data : returned_data};
	                    	return returned_data
	                    },
                    },
                    deferRender:    true,
		            scrollY:        '200px',
		            scrollCollapse: true,
		            //scroller:       true,
		            select : true,
		            "order": [[sorting_index, "asc"]],
		            scrollX: '100%',
		            "processing": true,
                    /*"bProcessing": true,
                    deferRender: true,
                    //"bServerSide": true,
                    //"serverSide": true,
                    //"processing": true,
                    select : true,
					'scrollX': true,
					scrollY: 200,
					scrollCollapse: true,
					scroller: true,
					/*scroller: {
						loadingIndicator: true
					},
					'autoWidth' : false,
					fixedHeader : {
						header: true,
						footer: true
					},*/
					language: {
					   emptyTable: "No data available in table", // 
					   loadingRecords: "Please wait .. ", // default Loading...
					   zeroRecords: "No matching records found"
					  },
					columnDefs: [ {
					 	targets : '_all',
					 	"type" : "mystring",
						render: function ( data, type, row ) {
							var limit = 8;
							var output = data;
							var re = new RegExp('[A-Z]+');
							var m;
							var index = row.indexOf(data);
							var positions = [];
							var position;
							var variant = output;
							if (type === 'display'){
								/*output = data.length > limit ?
									data.substr( 0, limit - 3 ) +'…' :
						        	data;*/
						        m = data.match(re);
						        if (m && index == 13){
						        	// Account for large insertions and deletions
						        	reference = row[12];
						        	variant = row[13];
						        	for (var i = 0; i < variant.length; i++){
						        		if (variant[i] != reference[i]){
						        			positions.push(i);
						        		}
						        	}
						        	positions = positions.sort(function(a,b){
						        		return a < b;
						        	});
						        	for (var i = 0; i < positions.length; i++){
						        		position = positions[i];
						        		variant = variant.slice(0,position) + '<font color="#ff5151"><b>' + variant.slice(position, position+1) + '</b></font>' + variant.slice(position+1,variant.length);
						        	}
						        }
							}
							return variant;
							/*return type === 'display' && data.length > limit ?
						        data.substr( 0, limit - 3 ) +'…' :
						        data;*/
						    }
						},
					],

                    'initComplete': function(settings, json) {
                    	console.log(view.name + ' COMPLETE');
						$('#' + view.name + 'DataTable').show();
						view.dataTable.DataTable().row(':eq(0)').select();

						if ($(view.dataTable.DataTable().column( 2 ).header()).html() == 'Chromosome'){
							$(view.dataTable.DataTable().column( 2 ).header()).html('Chromo<br />some');
						}
					}
                } );


				//$($.fn.dataTable.tables(true)).DataTable().columns.adjust();


				if (this.frameViewer){
					view = this;
					this.dataTable.DataTable().on('select', function (e, dt, type, indexes) {
						if (type === 'row' ){
							var row_pos = view.dataTable.DataTable().row(indexes[0]).index();
							var row_data = view.dataTable.DataTable().row(row_pos).data();
							view.loadViewer(row_data);
						}
						//view.loadGeneTable(row_data);
					});
				}
				$('#' + this.name + ' tbody').on('click', 'td', function () {
					view.dataTable.DataTable().cells('.selected').deselect();
					view.dataTable.DataTable().cell( this ).select();
					var datum = $(this).html();
					if (datum.indexOf('<') < 0){
						datum = view.dataTable.DataTable().cell( this ).data();
					}
					view.$selectedPanel.html(datum);
				});

				if (this.model.get('shownHeaders')){
					this.refreshHeaders();
				}
				this.firstRun = true;
			},

			refreshHeaders : function(){
				var targetVisibility = this.dataTable.DataTable().columns().visible();
				var currentVisibility = this.model.columnVisibility();
				var col;
				for (var i = 0; i < targetVisibility.length; i++){
					if (targetVisibility[i] !== currentVisibility[i]){
						col = this.dataTable.DataTable().columns(i);
						col.visible(!col.visible()[0]);
					}
				}
			},

			draw : function(){
				if ($.fn.DataTable.isDataTable(this.dataTable)){
					this.dataTable.DataTable().draw();
					this.dataTable.DataTable().columns.adjust();
				}
			},

			formatToDataTableHeader : function(header){
				var header_columns = [];
				var value;
				for (var i = 0; i < header.length; i++){
					value = header[i];
					/*if (value == 'Chromosome'){
						value = 'Chromo some';
					}*/
					header_columns.push({title:value});
				}
				return header_columns;
			},

			loadTableData: function(ID){
				var view = this;
				var xhr = jQuery.getJSON("/api/datasets/" + ID, {
					data_type : 'raw_data',
					provider : 'column'
				})
				console.log('Loading table data for ' + ID)
				xhr.done( function( response ){
					view.headers = response.data.shift();
					view.data = response.data;
					view.fillOutEndData();
					view.renderTable(view.data, view.formatToDataTableHeader(view.headers));
				});
			},

			fillOutEndData: function(){
				for (var i = 0; i < this.data.length; i++){
					missing_len = this.headers.length - this.data[i].length;
					if (missing_len > 0){
						for (var j = 0; j < missing_len; j++){
							this.data[i].push("");
						}
					}
				}
			},

			renderFrame: function(){
				//this.$el.append('<div class="frame"></div>');
				//console.log(this.$el);
			},


			loadViewer : function(row_data){
				var headers = this.model.get('All headers');
				var chrom = row_data[headers.indexOf('Chromosome')];
				var pos = row_data[headers.indexOf('Position')];
				var strand = row_data[headers.indexOf('Strand')];
				var ref = row_data[headers.indexOf('Reference base(s)')];
				var alt = row_data[headers.indexOf('Alternate base(s)')];

				tpl = _.template('http://www.cravat.us/CRAVAT/variant.html?variant=<%= chr %>_<%= position %>_<%= strand %>_<%= ref_base %>_<%= alt_base %>');
				
				link = tpl({chr: chrom,
					strand: strand,
					position: pos,
					ref_base: ref,
					alt_base: alt});
				$('#variantviewer').attr('src',link);
			},


			hideColumn : function(header){
				var table = $(this.idName + 'DataTable').DataTable();
				index = this.headers.indexOf(header);
				table.column(index).visible(false);
			},

			showColumn : function(header){
				var table = $(this.idName + 'DataTable').DataTable();
				index = this.headers.indexOf(header);
				table.column(index).visible(true);
			},

			displayColumns : function(new_headers){
				var all_headers = this.headers;
				// If this header is not within the new header config, then hide it.
				var header;
				for (var i = 0; i < all_headers.length; i++){
					header = all_headers[i];
					new_headers.indexOf(header) < 0 ? this.hideColumn(header) : this.showColumn(header);
				}
			}
		});
	})