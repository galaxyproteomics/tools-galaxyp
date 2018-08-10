define(['views/sidebar', 'views/table'],
	function(Sidebar, Table){
		return Backbone.View.extend({
			className :'contentTab',

			events : {
				//'click tr' : 'updateTable'
				'click .load' : 'tableLoadingIndicator'
			},

			initialize : function(params){
				this.model = params.model;
				this.name = this.model.get('name');
				this.index = params.n;
				this.frameViewer = params.frameViewer;
				this.dataTable = new Table({name : this.model.name + '-datatable', model : this.model, frameViewer : this.frameViewer});

				this.sidebar = new Sidebar({model: this.model});

				this.loadIndicator();

				//this.model.on('change:data', this.loadTable, this);
				this.model.on('change:ID', this.loadTable, this);
				this.model.on('change:Unique values', this.renderSidebarLoader,this);
				this.firstRun = true;
			},

			loadIndicator : function(){
            	this.$el.append('<div class="indicator"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div>');
            	// this.$el.append('<div class="outer"><div class="middle"><div class="inner"><div class="indicator"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div></div></div></div>');
			},

			tableLoadingIndicator : function(){

                var data = this.model.get('Sorted data');
                if (data.length <= 100000){
					//this.loadIndicator(); 
                   this.model.set('data', data);
                }
			},

			renderSidebarLoader : function(){
				console.log('Rendering sidebar loader');
				if (this.model.has('Unique values')){
					this.sidebar.renderLoader();
					this.$el.html(this.sidebar.el);
					this.$el.append(this.dataTable.el);
					this.model.off('change:Unique values');
				} else {
					console.log('Finish coding this case!');
				}
			},

			loadTable : function(){
				if (!this.model.has('Unique values')){
					this.$el.html(this.sidebar.el);
					this.$el.append(this.dataTable.el);
				}
				if (this.frameViewer) {
					//this.dataTable.$el.append("<div class='frame'><iframe id='variantviewer'></iframe></div>");
				} 
				this.updateButton();
				this.dataTable.loadTable(this.model.get('ID'));
			},

			updateButton : function(){
				$('.nav-tabs button:eq(' + this.index + ')').removeClass('loading');
				$('.nav-tabs button:eq(' + this.index + ')').addClass('loaded');
			}
		});
	});
