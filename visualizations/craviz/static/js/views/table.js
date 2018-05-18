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
				//this.dataTable = $('#' + this.name).DataTable();
			},

			render : function(){
				$view = $('<div>', {'class' : 'dataTableView'});

				var panelClass = this.frameViewer ? ' top-panel' : '';
				$view.append('<div id="' + this.name + 'DataTable" class="data-table ' + panelClass +'" style="display: none;"><table id="' + this.name + '"></table></div>');	
				this.$el.append($view);
				//var content = '<thead><tr><th>Name</th><th>Position</th><th>Office</th><th>Extn.</th><th>Start date</th><th>Salary</th></tr></thead><tfoot><tr><th>Name</th><th>Position</th><th>Office</th><th>Extn.</th><th>Start date</th><th>Salary</th></tr></tfoot>';
				//this.$el.append('<div id="' + this.name + 'DataTable" class="data-table ' + panelClass +'" style="display: none;"><table id="' + this.name + '">' + content + '</table></div>');	
			},

			loadingIndicator : function(){
				console.log('Loading indicator');
				this.$el.html('<div class="indicator"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div>');
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
		        //if (allHeaders.indexOf('Chromosome') > 0){
		        //	this.model.allHeaders[allHeaders.indexOf('Chromosome')] = 'Chromo some';
		        //}
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
		            scrollY:        '2000px',
		            scrollCollapse: true,
		            //scroller:       true,
		            select : true,
		            "order": [[sorting_index, "asc"]],
		            scrollX: true,
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
					columnDefs: [ {
					 	targets : '_all',
					 	"type" : "mystring",
						render: function ( data, type, row ) {
							var limit = 15;
							return type === 'display' && data.length > limit ?
						        data.substr( 0, limit - 3 ) +'…' :
						        data;
						    }
						},
					],

                    'initComplete': function(settings, json) {
                    	console.log(view.name + ' COMPLETE');
						$('#' + view.name + 'DataTable').show();
						view.dataTable.DataTable().row(':eq(0)').select();
						//$('#' + view.name + 'DataTable').draw();
						}
                } );


				//$($.fn.dataTable.tables(true)).DataTable().columns.adjust();


				if (this.frameViewer){
					view = this;
					this.dataTable.DataTable().on('select', function (e, dt, type, indexes) {
						if (type === 'row' ){
							var pos = view.dataTable.DataTable().row(indexes[0]).index();
							var data = view.dataTable.DataTable().row(pos).data();
							view.loadViewer(data);
						}
					});
				}

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
				}
			},

			formatToDataTableHeader : function(header){
				var header_columns = [];
				var value;
				for (var i = 0; i < header.length; i++){
					value = header[i];
					if (value == 'Chromosome'){
						value = 'Chromo some';
					}
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
				this.$el.append('<div class="frame"></div>');
				console.log(this.$el);
			},


			loadViewer : function(row){
				$('#variantviewer').attr('src',this.getLink(row));
			},

			getLink : function(row_data){
				var headers = this.model.get('All headers');
				var chrom = row_data[headers.indexOf('Chromosome')];
				var pos = row_data[headers.indexOf('Position')];
				var ref = row_data[headers.indexOf('Reference base(s)')];
				var alt = row_data[headers.indexOf('Alternate base(s)')];

				tpl = _.template('http://staging.cravat.us/CRAVAT/variant.html?variant=<%= chr %>_<%= position %>_-_<%= ref_base %>_<%= alt_base %>');
				
				link = tpl({chr: chrom,
					position: pos,
					ref_base: ref,
					alt_base: alt});
				return link;
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