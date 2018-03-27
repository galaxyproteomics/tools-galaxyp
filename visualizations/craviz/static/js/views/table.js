
define([],
	function(){
		return Backbone.View.extend({

			events: {
				'click tbody tr' : 'loadViewer',
			},

			initialize: function(options){
				this.tableName = options.name + 'DataTable';
				this.idName = '#' + options.name;
				this.default_headers = options.default_headers;

				//_.bindAll(this,'loadViewer');

			},

			getLength : function(){
				return this.data.length;
			},


			formatToDataTableHeader : function(header){
				header_columns = [];
				for (var i = 0; i < header.length; i++){
					header_columns.push({title:header[i]});
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


			renderTable: function(tableData,headerData){
				//console.log('Rendering table for ' + this.idName)
				this.$el.append('<table id="' + this.tableName + '" class="dataTable"></table>');
				//this.$el.append('<iframe id="variantviewer"></iframe>')
				/*header_columns = []
				for (var i = 0; i < this.target_headers.length; i++){
					header_columns.push({title:this.target_headers[i]});
				}*/

				console.log('RENDERING"""')
				console.log($('#' + this.tableName));
				$('#' + this.tableName).DataTable({
					data: tableData,
					columns: headerData,
					fixedHeader: true,
					select: {
						style: 'os',
						className: 'row-selected'
					},
					'scrollX': true
				});
				if (this.idName == '#Variant'){
					this.renderFrame();

					//$('#VariantDataTable tbody tr:first').addClass('row-selected');

					default_headers = ['Chromosome',
						'Position',
						'Strand',
						'Reference base(s)',
						'Alternate base(s)',
						'Sample ID',
						'HUGO symbol',
						'Sequence ontology',
						'Protein sequence change',
						'CHASM score',
						'COSMIC variant count',
						'gnomAD AF Total',
						'GWAS Phenotype (GRASP)'];
					//this.displayColumns(default_headers);
				}
				this.displayColumns(this.default_headers);


				//this.hideColumn('Input line');
				//this.hideColumn('ID');
				//this.hideColumn('S.O. transcript');
				//this.hideColumn('S.O. transcript strand');

				
			},


			renderFrame: function(){
				this.$el.append('<iframe id="variantviewer"></iframe>');
			},


			loadViewer : function(events){
				console.log('Loading viewer: ');
				console.log(events);

				if (this.firstRun){
					$(this.idName + ' tbody tr:first').removeClass('row-selected');
				}
				this.firstRun = false;

				
				var row = $('.row-selected').html().split('</td><td>');
				
				
				$('#variantviewer').attr('src',this.getLink(events.target));
			},

			getLink : function(target){
				console.log(target);
				console.log(target);
				var table = $(this.idName + 'DataTable').DataTable();
				row_data = table.row(target).data();
				chrom = row_data[this.headers.indexOf('Chromosome')];
				pos = row_data[this.headers.indexOf('Position')];
				ref = row_data[this.headers.indexOf('Reference base(s)')];
				alt = row_data[this.headers.indexOf('Alternate base(s)')];

				tpl = _.template('http://staging.cravat.us/CRAVAT/variant.html?variant=<%= chr %>_<%= position %>_-_<%= ref_base %>_<%= alt_base %>');

				link = tpl({chr: chrom,
					position: pos,
					ref_base: ref,
					alt_base: alt})

				return link
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
				all_headers = this.headers;
				for (var i = 0; i < all_headers.length; i++){
					header = all_headers[i];
					// If this header is not within the new header config, then hide it.
					if (new_headers.indexOf(header) < 0){
						this.hideColumn(header);
					} else {
						this.showColumn(header);
					}
				}
			}
		});
	})