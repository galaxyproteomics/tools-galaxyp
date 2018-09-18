
define([],
      function(){
            return Backbone.View.extend({

                  className : 'loader',

                  events : {
                    //'click .load' : 'loadData'
                  },


                  initialize : function(options){
                    console.log('Loader initialized');
                    this.loadMessage = new Message({model : this.model});
                    this.filterCategories = new FilterCategories({model : this.model});
                    //this.filterCategory = new FilterCategory({model : this.model});
                    this.dropdown = new Dropdown({model : this.model});
                    //this.length = 0;
                    this.button = null;
                    this.model.on('change:Sorted data', this.updateButton, this);
                    this.render();
                  },

                  loadData : function(){
                    //this.model.sortData();
                    var data = this.model.get('Sorted data');
                    if (data.length <= 100000){
                      this.model.set('data', data);
                    }
                  },

                  updateButton : function(){
                    var data = this.model.get('Sorted data');

                    if (100000 >= data.length && data.length > 0){
                      this.button.show();
                    } else{
                      this.button.hide();
                    }
                  },

                  render : function(){
                    this.$el.append(this.loadMessage.el);
                    this.$el.append(this.filterCategories.el);
                    this.$el.append('<div ><button>Check number of variants</button><button class="load">Load variants</button></div>')
                    this.button = $(this.$el).find('button.load');
                    this.button.hide();
                  }
      });
});


var Message = Backbone.View.extend({

  className : 'load-message',

  tooManyTpl: 'You have more variants than CRAVAT Result Viewer can display. Use filters below to reduce the number of variants to load. When 100,000 or fewer remain, they can be retrieved with the "Load" button.',

  justRightTpl : _.template('<%= number %> variants selected. Click the "Load variants" button to retrieve them'),

  initialize : function(){
     this.render();
     this.model.on('change:Sorted data', this.update, this);
  },

  render : function(){
    this.$el.html(this.tooManyTpl);
  },

  update : function(){
    var length = this.model.get('Sorted data').length;
    if (length <= 100000){
      this.$el.html(this.justRightTpl({number : length == 0 ? 'No ' : length}));
    } else {
      this.$el.html(this.tooManyTpl);
    }
  }
});

var FilterCategories =  Backbone.View.extend({

                  className : 'sidebar-view',

                  events : {
                    'change' : 'update',
                    //'remove' : 'update'
                  },

                  initialize : function(){
                    this.target = new FilterCategory({model : this.model});
                    this.length = 0;
                    this.render();
                  },

                  addFilter : function(){
                    filterCategory = new FilterCategory({model : this.model});
                    this.$el.append(filterCategory.el);
                  },

                  // Adds a 
                  update : function(event){
                    this.length = this.$el.children().length - 1;
                    var filters = this.model.filters;
                    var filtered = Object.values(filters).filter(filter => filter.category != null);
                    filterLength = filtered.length;
                    inc = filterLength - this.length;
                    if (inc > 0){
                      this.addFilter();
                    } 
                    this.length = filterLength;
                  },

                  render : function(){
                    this.$el.append(this.target.el);
                  }
      });

var FilterCategory = Backbone.View.extend({

                  className : 'filter-category',


                  events : {
                      'change' : 'update',
                      'click .remove' : 'remove'
                  },

                  initialize : function(options){
                      this.filterColumns = this.model.filterColumns;
                      this.category = null;
                      this.model.filters[this.cid] = {category : null, filter : null};

                      this.categoryDropdown = new Dropdown({id : this.cid, model : this.model});
                      this.filter = new Filter({id : this.cid, model : this.model});

                      this.model.on('change:Sorting data', this.update,this);
                      //this.categoryDropdown.on('change', this.loadFilter, this);
                      this.filter.on('change:value', this.sortData, this);
                      //this.filter.on('click', this.remove, this);
                      this.render();
                  },

                  setFilter : function(value){
                    console.log('Setting filter');
                    var filters = this.model.get('Filters');
                    filters[this.cid] = value;
                    this.model.set('Filters', filters);
                  },

                  sortData : function(){
                    console.log('sadflkasd;lfkjadsf');
                  },

                  update : function(event){
                    console.log('Updating');
                    if (event.target){
                      if (event.target.className == 'dropdown') {
                        index = event.target.selectedIndex;
                        index == 0 ? this.remove() : this.filter.render(index - 1);
                        var category = this.filterColumns[index-1].name;
                        this.model.filters[this.cid].category = category;
                        uniqueValues = this.model.get('Unique values');
                        if (category in uniqueValues){
                          this.model.filters[this.cid].filter = uniqueValues[category][0];
                          this.model.sortData();
                        }
                      } else {
                        if (event.target.value == 'none'){
                          this.model.filters[this.cid].filter = uniqueValues[this.model.filters[this.cid].category][0];
                        } else {
                          this.model.filters[this.cid].filter = event.target.value;
                        }
                        this.model.sortData();
                      } 
                    }
                  },

                  remove : function(){
                    delete this.model.filters[this.cid];
                    this.$el.remove();
                    this.model.sortData();
                  },

                  render : function(){
                    this.$el.append(this.categoryDropdown.el);
                    this.$el.append(this.filter.el);
                  }
                });


var Dropdown = Backbone.View.extend({

                  tagName : 'select',

                  className : 'dropdown',

                  events : {
                    //'change' : 'setCategory'
                  },

                  initialize : function(options){
                    //data = this.model.get('Sorting data');
                    this.id = options.id;
                    this.columns = this.model.filterColumns.map(a => a.name);
                    //this.options = '<option value="none">' + this.columns.join('</option><option value="none">') + '</option>';
                    this.category = null;
                    this.render();
                  },

                  render : function(){
                    options = '<option value="none">' + this.columns.join('</option><option value="none">') + '</option>';
                    this.$el.html(['<option value="none">Choose a column to filter</option>',options].join(''));
                  },

                  setCategory : function(event){
                    this.model.filters[this.id].category = this.model.filterColumns[event.target.selectedIndex-1];
                  },

                  select : function(index){
                    //this.$el.children().eq(2).attr('selected', true);
                    this.$el.children().eq(index).prop('selected', true);
                  }
      });


var Filter = Backbone.View.extend({

                  className : 'filter',

                  categoricalTpl : _.template('is one of <select><%= options %></select>'),

                  quantitativeTpl : '<input></input>',

                  button : '<button class="remove">x</button>',

                  events : {
                    'change' : 'sortData'
                  },

                  initialize : function(params){
                    this.config = this.model.filterColumns;
                    this.categories = this.model.get('Unique values');
                    this.data = this.model.get('Sorting data');
                    this.value = null;
                  },

                  sortData : function(event){
                    this.value = event.target.value;
                    this.model.filters[this.id].filter = this.value;
                  },

                  render : function(index){
                    if (index >= 0){
                      if(this.config[index].categorical){
                        name = this.config[index].name;
                        optionList = '<option value="none">' + this.categories[name].join('</option><option>') + '</option>';
                        this.$el.html(this.categoricalTpl({options : optionList}));
                      } else {
                        this.$el.html(this.config[index].type + this.quantitativeTpl);
                      }
                      this.$el.append(this.button);
                    } else {
                      console.log('Check this code out');
                      this.$el.empty();
                    }
                  }
      });