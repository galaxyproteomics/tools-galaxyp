define(['plugin/Views/sidebar'],
	function(Sidebar){
		return Backbone.View.extend({
			className :'contentTab',

			events : {
				'click tr' : 'updateTable'
			},

			initialize : function(params){
				this.model = params.model;
				this.name = this.model.get('name');
				this.frameViewer = params.frameViewer;

				this.sidebar = new Sidebar({model: this.model});

				this.loadIndicator();

				this.model.on('change:data', this.loadTable, this);
				this.model.on('change:shownHeaders',this.refreshHeaders, this);
				this.model.on('change:Sorting data', this.renderSidebarLoader,this);
				this.firstRun = true;
			},

			loadIndicator : function(){
            	this.$el.append('<div class="loader"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div>');
			},

			renderSidebarLoader : function(){
				console.log('Rendering sidebar loader');
				if (this.model.has('Unique values')){
					this.sidebar.renderLoader();
					this.$el.html(this.sidebar.el);
					this.model.off('change:Sorting data');
				} else {
					console.log('Finish coding this case!');
				}
			},

			render : function(){
				this.$el.html(this.sidebar.el);
				this.$el.append("<div class='dataTable'><table id='" + this.name + "DataTable'></table></div>");

				if (this.frameViewer) {
					this.$el.append("<iframe id='variantviewer'></iframe><div class='frame-loader'></div>");
				} 
			},

			updateTable : function(event){
				if (this.firstRun){
					$('#' + this.name + 'DataTable tbody tr:first').removeClass('row-selected');
					this.firstRun = false;
				}
				if (this.frameViewer){
					this.setLink(this.dataTable.DataTable().row(event.target).data());
				}
			},

			loadTable : function(){
				this.render();
				this.dataTable = $('#' + this.name + 'DataTable');
				this.dataTable.DataTable({
					data : this.model.get('data'),
					columns : this.formatToDataTableHeader(this.model.allHeaders),
					select : {
						style: 'os',
						className: 'row-selected'
					},
					'scrollX': true
				});


				headers = this.model.shownHeaders;
				if (this.model.get('shownHeaders')){
					this.refreshHeaders();
				}
				$('#' + this.name + 'DataTable tbody tr:first').click();
				this.firstRun = true;
				$('#' + this.name + 'DataTable tbody tr:first').addClass('row-selected');
			},

			refreshHeaders : function(){
				targetVisibility = this.dataTable.DataTable().columns().visible();
				currentVisibility = this.model.columnVisibility();
				
				for (var i = 0; i < targetVisibility.length; i++){
					if (targetVisibility[i] !== currentVisibility[i]){
						col = this.dataTable.DataTable().columns(i);
						col.visible(!col.visible()[0]);
					}
				}
			},

			addData : function(){
				console.log('ADDING DATA');
				data = this.model.get('data');
				//this.formatToDataTableData(data);
				for (var i = 0; i < data.length; i++){
					this.dataTable.DataTable().row.add(data[i]);
				}
				this.dataTable.DataTable().draw();
			},

			formatToDataTableHeader : function(header){
				header_columns = [];
				for (var i = 0; i < header.length; i++){
					header_columns.push({title:header[i]});
				}
				return header_columns;
			},

			setLink : function(row_data){
				chrom = row_data[this.model.allHeaders.indexOf('Chromosome')];
				pos = row_data[this.model.allHeaders.indexOf('Position')];
				ref = row_data[this.model.allHeaders.indexOf('Reference base(s)')];
				alt = row_data[this.model.allHeaders.indexOf('Alternate base(s)')];

				tpl = _.template('http://staging.cravat.us/CRAVAT/variant.html?variant=<%= chr %>_<%= position %>_-_<%= ref_base %>_<%= alt_base %>');

				link = tpl({chr: chrom,
					position: pos,
					ref_base: ref,
					alt_base: alt});
				$('#variantviewer').attr('src',link);

			},

			// Implement cases where the header does not match the length of the data rows
			formatToDataTableData : function(data){
				headers = this.model.get('headers');
				for (var i = 0; i < data.length; i++){
					newRow = {};
					for (var j = 0; j < data[i].length; j++){
						newRow[String(headers[j])] = data[i][j];
					}
					$('#' + this.name + 'DataTable').DataTable().row.add(['1','2','3','4']).draw();
				}
				console.log('DONE FORMATTING');
			}
		});
	});
