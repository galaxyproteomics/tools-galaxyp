define([],
	function(){
		return Backbone.View.extend({
			//template: _.template("<button><%= tab1 %></button><button><%= tab2 %></button><button class='active'><%= tab3 %></button><button><%= tab4 %></button><button><%= tab5 %></button>"),
			
			className : 'nav-tabs',

			initialize: function(options){
				this.tabNames = ['Summary', 'Gene', 'Variant', 'Noncoding', 'Error'];
				this.panels = options.panels;
				this.index = options.index + 1;
				this.render();
			},


			render: function(){

				//this.$el.html(this.template({tab1:this.tabNames[0], tab2: this.tabNames[1], tab3: this.tabNames[2], tab4: this.tabNames[3], tab5: this.tabNames[4]}))
				var button;
				for (var i = 0; i < this.tabNames.length; i++){
					button = new TabButton({name: this.tabNames[i], panel: this.panels[i]});
					this.$el.append(button.el);
				}
				//this.setDefault(2);
				//$('.nav-tabs button:eq(' + this.index + ')').click();
			}
		});
	});

var TabButton = Backbone.View.extend({

			tagName : 'button',

			className : 'loading',

			events: {
					'click' : 'switchTab'
				},

			initialize: function(options){
				this.name = options.name;
				this.panel = options.panel;
				this.render();
			},

			render: function(){
				this.$el.html(this.name);
			},

			switchTab: function() {
				$('.' + this.panel.className).hide();
				this.panel.$el.show();
				$('.nav-tabs button').removeClass('active');
				this.$el.addClass('active');
				if (this.panel.dataTable){
					if (this.panel.id != 'Summary'){
						this.panel.dataTable.draw();
					}
				}
			}
		});