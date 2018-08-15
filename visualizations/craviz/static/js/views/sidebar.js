define(['plugin/views/loader'],
      function(Loader){
            return Backbone.View.extend({

                  className : 'left-cell',

                  tpl: _.template(['<p></p>','<%= jobName %>',
                    //'<p></p><b>Input File: </b>', '<%= inputFile %>',
                    //'<p></p><b>Date Run: </b>', '<%= dateRun %>',
                    //'<p></p><b>Processing time: </b>', '<%= processingTime %>',
                              //'<p></p><b>Analysis: </b>', '<%= analysisType %>',
                              //'<p></p><b>Number of Input lines: </b>', '<%= inputLineNumber %>',
                              '<p></p><b>Number of Errors: </b>', '<%= errorNumber %>',
                              '<p></p><b>Number of Variants: </b>', '<%= variantNumber %>',
                              '<p></p><b>Number of Genes: </b>', '<%= geneNumber %>',
                              '<p></p><b>Number of Samples: </b>', '<%= sampleNumber %>',
                    '<p></p><b>Number of Non-Coding: </b>', '<%= noncodingNumber %>'].join('')),

                  loaderTpl: _.template('You have more variants than CRAVAT Result Viewer can display. Use filters below to reduce the number of variants to load. When 100,000 or fewer remain, they can be retrieved with the "Load" button'),

                  events: {
                    'click .sidebar-button' : 'toggleVisibility'
                  },

                  initialize : function(options){
                      this.columnTypeCollection = new ColumnTypeCollection({model : this.model});
                      //this.model.on('change:headerConfig', this.renderColumnOptions, this);
                      this.render();
                      //this.model.on('change:Job ID', this.render, this);
                  },

                  toggleVisibility : function(){
                    if (parseInt(this.$el.css('width')) <= 20){
                      this.$el.css('max-width', '235px');  
                      //this.$el.css('max-width', '250px');  
                      this.button.html('<');
                    } else{
                      this.$el.css('max-width', '15px');
                      //this.$el.css('max-width', '15px');
                      this.button.html('>');
                    }
                  },  

                  render : function(){
                      $sidebar = $('<div>', {class : 'sidebar'});

                      $content = $('<div>', {'class' : 'column-type-collection'});
                      $content.append(this.model.get('Job ID'));
                      //$content.html('rsajulga_20180522_155808');

                      this.button = $('<button>', {'class' : 'sidebar-button'});
                      this.button.append('<');
                      $sidebar.append(this.button);
                      $sidebar.append(new Box({name : 'Job Info', content: $content}).el);
                      this.$el.html($sidebar);
                      this.renderColumnOptions();
                  },

                  renderColumnOptions : function(){
                      $sidebar = $('<div>', {class : 'sidebar'});

                      var $content = $('<div>', {'class' : 'column-type-collection'});
                      $content.append(this.model.get('Job ID'));

                      this.button = $('<button>', {'class' : 'sidebar-button'});
                      this.button.append('<');
                      $sidebar.append(this.button);
                      $sidebar.append(new Box({name : 'Job Info', content: $content}).el);
                      $sidebar.append(new Box({name : 'Columns', content : this.columnTypeCollection}).el);
                      this.$el.html($sidebar);
                  },

                  renderSummary : function(){
                      this.button = $('<button>', {'class' : 'sidebar-button'});
                      this.button.append('<');

                      $sidebar = $('<div>', {class : 'sidebar'});
                      var $content = $('<div>', {'class' : 'column-type-collection'});
                      $content.append(this.tpl({jobName : this.model.get('Job ID'),
                                                  errorNumber : this.model.get('Number of errors'),
                                                  variantNumber : this.model.get('Number of variants'),
                                                  geneNumber : this.model.get('Number of genes'),
                                                  sampleNumber : 1,
                                                  noncodingNumber : this.model.get('Number of noncoding variants')}));
                      $sidebar.html(this.button);
                      $sidebar.append(new Box({name : 'Job Info', content: $content}).el);
                      this.$el.html($sidebar);
                  },

                  renderLoader : function(){

                    loaderView = new Loader({model : this.model});
                    //button  = new VisibilityButton({target : loaderView.$el});

                    var $content = $('<div>', {'class' : 'column-type-collection'});
                    $content.append(this.model.get('Job ID'));
                    this.$el.html(new Box({name : 'Job Info', content: $content}).el);
                    this.$el.append(new Box({name : 'Load', content: loaderView}).el);
                    this.$el.append(new Box({name : 'Columns', content : this.columnTypeCollection}).el);
                  }
      });
});


var Box = Backbone.View.extend({

  initialize : function(params){
    this.name = params.name;
    this.content = params.content;
    this.render();
  },

  render : function(){
    var $label = $('<div>', {'class' : 'label'});
    $label.append(this.name);
    this.$el.html($label);

    var $div = $('<div>', {'class' : 'box'});
    this.$el.append($div);

    var content = this.content.$el || this.content;

    $div.append(content);
    $label.append(new VisibilityButton({target : content, minimized: false}).el);

    //$label.append(new VisibilityButton({target : $div, minimized: false}).el);
  }
});

var ColumnTypeCollection =  Backbone.View.extend({
      //tagName: 'div',
      className : 'column-type-collection',

      initialize : function(){
        //this.model.on('change:headerConfig',this.render, this);
        this.render();
            },

            render : function(){
              //var headerConfig = this.model.get('headerConfig');
              var headerConfig = this.model.categories;
              
              var shownHeaders = this.model.get('shownHeaders');

              for (var columnType in headerConfig){
                //this.$el.append(new VisibilityButton({name: columnType}).el);
                var columnViews = [];
                //for (var header in headerConfig[columnType]){
                for (var i = 0; i < headerConfig[columnType].length; i++){
                  header = headerConfig[columnType][i];
                  //console.log(shownHeaders);
                  //console.log(headerConfig[columnType][i]);
                  if (shownHeaders.indexOf(headerConfig[columnType][i]) > 0){
                    className = 'columnOption shown'
                  } else {
                    className = 'columnOption' 
                  }
                  columnViews.push(new Column({model : this.model,
                                  name: header,
                                  type : columnType,
                                  header : header,
                                  className : className,
                                  shown : headerConfig[columnType][i],
                                  id : header + 'Option'}));
                }
                columnsCollectionView = new Columns({name: columnType, model : this.model, columns : columnViews});
                this.$el.append(columnType);
                this.$el.append(new VisibilityButton({target: columnsCollectionView.$el, minimized: true}).el);
                this.$el.append('<p></p>');
                this.$el.append(columnsCollectionView.el);
              }
            }
      });

var Columns = Backbone.View.extend({
              
              className : 'columns-collection-view',

              initialize : function(options){
                    this.columns = options.columns;
                    this.name = options.name;
                    this.render();
              },

              render : function(){
                    for (var i = 0; i < this.columns.length; i++){
                          this.$el.append(this.columns[i].el);
                    }
              }
  });

var Column = Backbone.View.extend({
        tagname : 'div',

        events:{
          'click' : 'toggleColumn'
        },

        initialize : function(options){
              //this.model.on('change:headerConfig', this.render, this);
              this.name = options.name;
              this.header = options.header;
              this.type = options.type;
              this.shown = options.shown;
              this.render();
              //this.model.on('change:shownHeaders', this.toggleClass, this);
        },
        render : function(){
              this.$el.html(this.name);
        },

        toggleClass : function(){
          console.log('Toggling class');
          if (this.shown){
            $(this.el).addClass('shown'); 
          } else {
            $(this.el).removeClass('shown');
          }
        },

        toggleColumn : function(event){
          //headerConfig[this.type][this.header] = !headerConfig[this.type][this.header];
          console.log('Toggling column');
          var shownHeaders = this.model.get('shownHeaders');
          if (shownHeaders.indexOf(this.header) >= 0){
            header = this.header;
            $(this.el).removeClass('shown'); 
            var newShownHeaders = shownHeaders.filter(function(e) { return e !== header});
          } else{
            $(this.el).addClass('shown');
            var newShownHeaders = shownHeaders.concat(this.header);
          }
          this.model.set('shownHeaders',newShownHeaders);
        }
      });

var VisibilityButton =  Backbone.View.extend({
      tagName: 'button',

                  className: 'visibility-button',

                  events : {
                        'click' : 'toggleVisibility'
                  },

      initialize : function(options){
                        this.minimized = options.minimized;
                        this.target = options.target;
                        this.render();      
                        if (this.minimiz)
                        this.target.hide();
                  },

                  render : function(){
                    if (this.minimized){
                      this.$el.html('+');
                      this.target.hide();
                      //this.height = this.target.css('max-height');
                      //this.target.css('max-height', 0);
                    } else {
                      this.$el.html('-');
                      // this.target.css('max-height',this.target.css('height'));
                    }
                  },

                  calculateHeight : function(){
                        div = $('.columnOption');
                        var height = parseInt(div.height());
                        var attributes = ['padding-bottom','padding-top','margin-bottom','margin-top'];
                        for (var i = 0; i < attributes.length; i++){ 
                              height += parseInt(div.css(attributes[i]).replace('px',''));
                        }
                        numberOfDivs = this.target.context.childNodes.length;
                        return height * numberOfDivs;
                  },

                  toggleVisibility : function(){
                        if (this.minimized){
                            this.target.show();
                            this.target.css('max-height', '0px');
                        }

                        console.log(this.target.css('max-height'));
                        if (parseInt(this.target.css('max-height')) == 0){
                              this.target.css('max-height','90vh');
                              this.$el.html('-');
                              //this.target.css('transition', 'height 0.5s');
                        } else {
                              this.target.css('max-height','0px');
                              //this.target.addClass('open');
                              this.$el.html('+');
                              this.target.show();
                              //this.target.css('transition', 'height 0.5s');
                        }
                  }
      });



