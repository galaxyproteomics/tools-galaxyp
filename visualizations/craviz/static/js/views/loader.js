
define([],
      function(){
            return Backbone.View.extend({

                  className : 'sidebar-view',

                  events : {
                    'change' : 'addCategory'
                  },


                  initialize : function(options){

                    this.loadMessage = new Message({model : this.model});
                    this.filterCategories = new FilterCategories({model : this.model});
                    //this.filterCategory = new FilterCategory({model : this.model});
                    this.dropdown = new Dropdown({model : this.model});

                    this.render();
                  },

                  addCategory : function(event){
                    console.log('SD:FLKJS:DFKj');
                  },

                  addFilterCategory : function(event){
                    console.log('Adding filter category');
                    this.filterCategories.addFilter(event);
                    this.dropdown.select(0);
                    //this.render();
                  },

                  render : function(){
                    this.$el.append(this.loadMessage.el);
                    //this.$el.append(this.filterCategory.el);
                    this.$el.append(this.filterCategories.el);
                    //this.$el.append(this.dropdown.el);
                  }
      });
});

var Message = Backbone.View.extend({

                  className : 'load-message',

                  tooManyTpl: 'You have more variants than CRAVAT Result Viewer can display. Use filters below to reduce the number of variants to load. When 100,000 or fewer remain, they can be retrieved with the "Load" button.',

                  justRightTpl : _.template('<%= number %> variants selected. Click the "Load variants" button to retrieve them'),

                  initialize : function(){
                     this.render();
                  },

                  render : function(){
                    this.$el.html(this.tooManyTpl);
                  }
      });

var Dropdown = Backbone.View.extend({

                  tagName : 'select',

                  className : 'dropdown',

                  initialize : function(){
                    data = this.model.get('Sorting data');
                    this.columns = Object.keys(data[0]);
                    this.options = '<option value="none">' + this.columns.join('</option><option value="none">') + '</option>';
                    this.render();
                  },

                  render : function(){
                    data = this.model.get('Sorting data');
                    this.columns = Object.keys(data[0]);
                    options = '<option value="none">' + this.columns.join('</option><option value="none">') + '</option>';

                    this.$el.html(['<option value="none">Choose a column to filter</option>',options].join(''));
                  },

                  select : function(index){
                    //this.$el.children().eq(2).attr('selected', true);
                    this.$el.children().eq(index).prop('selected', true);
                  }
      });

var FilterCategories =  Backbone.View.extend({

                  className : 'sidebar-view',

                  //events : {
                    //'change' : 'addFilter'
                  //},

                  initialize : function(){
                    this.target = new FilterCategory({model : this.model});
                    this.render();
                  },

                  addFilter : function(event){
                    console.log('adding filter');
                    index = event.target.selectedIndex;
                    filterCategory = new FilterCategory({model : this.model});
                    console.log(this.target)
                    this.$el.append(filterCategory.el);
                  },

                  render : function(){
                    this.$el.append(this.target.el);
                  }
      });

var FilterCategory = Backbone.View.extend({

                  className : 'sidebar-view',


                  events : {
                      'click button' : 'remove',
                      'change .dropdown' : 'update'
                  },

                  initialize : function(options){
                      data = this.model.get('Sorting data');
                      this.columns = Object.keys(data[0]);
                      this.categoryDropdown = new Dropdown({model : this.model});
                      this.filter = new Filter({model : this.model});
                      this.$el.append('<button>x</button>');
                      //console.log(this.$el);
                      //this.button = $(this.$el.'button');
                      //this.button.hide();
                      //this.button.remove();
                      this.render();
                      //this.model.on('change:Sorted data', this.update, this);
                  },

                  update : function(event){
                    console.log('Updating');
                    //text = event.target.options[index].text;
                    if (index > 0){
                      index = event.target.selectedIndex;
                      index == 0 ? this.remove() : this.filter.render(index - 1);
                      //this.$el.append('<button>x</button>');
                      //this.button.show();
                    } else {
                      this.$el.remove();
                    }
                  },

                  remove : function(){
                    console.log('remove');
                    this.$el.remove();
                  },

                  render : function(){
                    //this.$el.html(this.loadMessage.el);
                    this.$el.append(this.categoryDropdown.el);
                    this.$el.append(this.filter.el);
                    //this.$el.append(new Filter({columns : this.columns}).el);
                    //this.$el.append(new Dropdown({columns : this.columns}).el);
                  }
                });

var Filter = Backbone.View.extend({

                  className : 'filter',

                  categoricalTpl : _.template('is one of <select><%= options %></select>'),

                  quantitativeGreaterTpl : '>=<input></input>',

                  quantitativeLessTpl : '<=<input></input>',

                  initialize : function(params){
                    this.config = this.model.filterColumns;
                    this.categories = this.model.get('Unique values');
                    this.data = this.model.get('Sorting data');
                  },

                  render : function(index){
                    if (index >= 0){
                      if(this.config[index].categorical){
                        name = this.config[index].name;
                        optionList = '<option value="none">' + this.categories[name].join('</option><option>') + '</option>';
                        this.$el.html(this.categoricalTpl({options : optionList}));
                      } else {
                        this.$el.html(this.quantitativeGreaterTpl);
                      }
                    } else {
                      console.log('Check this');
                      this.$el.empty();
                    }
                  },

                  numberOfVariants : function(){

                  }
      });