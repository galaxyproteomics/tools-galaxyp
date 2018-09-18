define([],
	function(){
		return Backbone.View.extend({

			className : 'right-cell',

			initialize: function(options){
				this.name = options.name;
				this.model.on('change:shownHeaders',this.refreshHeaders, this);
				this.firstRun = true;
				this.frameViewer = options.frameViewer;
				this.render();
				if (this.model.name == 'Gene'){
					//this.model.collection.at(2).on('change:Gene Data', this.loadGeneTable, this);
				}
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

		        // Functions for sorting without including blank cells
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

                var oTable = this.dataTable.DataTable( {
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
		            //scrollCollapse: true,
		            scroller:       true,
		            select : true,
		            "order": [[sorting_index, "asc"]],
		            "sScrollX" : "100%",
		            //scrollX: '100%',
		            //'scrollX': true,
		            "processing": true,
		            'bAutoWidth': false,
		            'bPaginate': true,
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
							var n = 3;
							var output = data;
							var re = new RegExp('[A-Z]+');
							var m;
							var index = row.indexOf(data);
							var variant = data;
				
							if (type === 'display'){
								/*output = data.length > limit ?
									data.substr( 0, limit - 3 ) +'…' :
						        	data;*/
						        m = data.match(re);
						        if (m && index == view.model.get('All headers').indexOf('Variant peptide')){
						        	// Account for large insertions and deletions
						        	reference = row[view.model.get('All headers').indexOf('Reference peptide')];
						        	variant = row[view.model.get('All headers').indexOf('Variant peptide')];
						        	variant = view.highlight_mutated_amino_acid(reference, variant, limit);
						        	return variant
						        }
							}

							//return variant;
							if (type === 'display' && variant.length > limit){
								variant = variant.substr( 0, limit);
								return variant + '...';
							} else{
								return variant;
							}
						  }
							/*return type === 'display' && datalen > limit ?
						        variant.substr( 0, limit - 3 ) +'…' :
						        variant;
						    }*/
						},
					],

					'drawCallback': function( settings ) {
						$(".dataTables_scrollHeadInner").css({"width":"100%"});
						$(".dataTables_scrollBody ").css({"width":"100%"});
					},

                    'initComplete': function(settings, json) {
                    	console.log(view.name + ' COMPLETE');
						$('#' + view.name + 'DataTable').show();
						view.dataTable.DataTable().row(':eq(0)').select();

						if ($(view.dataTable.DataTable().column( 2 ).header()).html() == 'Chromosome'){
							$(view.dataTable.DataTable().column( 2 ).header()).html('Chromo<br />some');
						}

						if (!!window.webkitURL){
							view.fixHeaderWidth();
						}

						$(window).bind('resize', function () {
							view.fixHeaderWidth();
						});

						
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
				// 
				$('#' + this.name + ' tbody').on('click', 'td', function () {
					view.dataTable.DataTable().cells('.selected').deselect();
					view.dataTable.DataTable().cell( this ).select();
					var datum = $(this).html();
					if (view.dataTable.DataTable().cell( this ).index().column == view.model.get('All headers').indexOf('Variant peptide')){
						variant_peptide = view.dataTable.DataTable().cell( this ).data();
						reference_peptide = view.dataTable.DataTable().row(view.dataTable.DataTable().cell( this ).index().row).data()[view.model.get('All headers').indexOf('Reference peptide')];
						datum = view.highlight_mutated_amino_acid(reference_peptide, variant_peptide, 100);
					}
					view.$selectedPanel.html(datum);
				});

				if (this.model.get('shownHeaders')){
					this.refreshHeaders();
				}
				this.firstRun = true;
			},

			highlight_mutated_amino_acid : function(reference, variant, limit){
				var positions = [];
				var pos;
				var variable = '<%= varAA %>';
				var front_tag = '<span style="color:#ff5151;font-weight:bold;">';
				var back_tag = '</span>';
				var template = front_tag + variable + back_tag;
				var replacement = 'N'
				var data_length;
				var tpl = _.template(template);
				var n = 3;
				var displayed_variant = variant;

	        	data_length = variant.length
	        	for (var i = 0; i < variant.length; i++){
	        		if (variant[i] != reference[i]){
	        			positions.push(i);
	        		}
	        	}
	        	positions = positions.sort(function(a,b){
	        		return a < b;
	        	});
	        	var adjuster = 0;
	        	for (var i = 0; i < positions.length; i++){
	        		pos = positions[i];
	        		//variant = variant.slice(0,position) + '<font color="#ff5151"><b>' + variant.slice(position, position+1) + '</b></font>' + variant.slice(position+1,variant.length);
	        		replacement = variant.slice(pos, pos+1)
	        		//datalen = template.length  + replacement.length - variable.length;
	        		if (pos < limit){ // If the mutated position is within the limit...
	        			displayed_variant = variant.slice(0,pos) + tpl({varAA: replacement}) + variant.slice(pos+1,limit);
	        		} else {
	        			displayed_variant = variant.slice(0,limit)
	        		}
	        	}
	        	if (limit < variant.length){
    				displayed_variant += '...';
    			}
	        	return displayed_variant;
			},



			fixHeaderWidth : function(){
				console.log('Fixing header width');
				var children = $('#' + this.name + ' > tbody > tr.odd.selected').children();
				var totalWidth = 0;
				for (var i = 0; i < children.length; i++){
					totalWidth += children[i].offsetWidth;
				}
				$('#' + this.name + '_wrapper > div.dataTables_scroll > div.dataTables_scrollHead > div > table').css('min-width', totalWidth + 'px');
				$('#' + this.name + '_wrapper > div.dataTables_scroll > div.dataTables_scrollHead > div > table').css('width', '100%');
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
				this.draw();
			},

			draw : function(){
				if ($.fn.DataTable.isDataTable(this.dataTable)){
					this.dataTable.DataTable().draw();
					this.fixHeaderWidth();
					//this.dataTable.DataTable().columns.adjust();
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