define(['plugin/Views/loader'],
      function(Loader){
            return Backbone.View.extend({

                  className : 'sidebar',

                  tpl: _.template(['<p></p><b>Job Info: </b>', '<%= jobName %>',
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


                  initialize : function(options){
                      this.columnTypeCollection = new ColumnTypeCollection({model : this.model});
                      this.model.on('change:headerConfig', this.render, this);
                  },

                  render : function(){
                      //button  = new VisibilityButton({target : this.columnTypeCollection.$el});
                      //this.$el.append(button.el);

                      this.$el.append(['Filter',
                                        '<button class="visibility-button">-</button>',
                                        '<div class="options">VEST p-value</div>',
                                        'Columns'].join(''));
                      this.$el.append(this.columnTypeCollection.el);
                  },

                  renderSummary : function(){
                      this.$el.html(this.tpl({jobName : this.model.get('Job ID'),
                                                  errorNumber : this.model.get('Number of errors'),
                                                  variantNumber : this.model.get('Number of variants'),
                                                  geneNumber : this.model.get('Number of genes'),
                                                  sampleNumber : 'N/A',
                                                  noncodingNumber : this.model.get('Number of noncoding variants')}));
                  },

                  renderLoader : function(){
                    loaderView = new Loader({model : this.model});
                    button  = new VisibilityButton({target : this.columnTypeCollection.$el});
                    this.$el.append(button.el);
                    this.$el.append(loaderView.el);
                  }
      });
})

var ColumnTypeCollection =  Backbone.View.extend({
      tagName: 'div',

      initialize : function(){
        this.model.on('change:headerConfig',this.render, this);
            },

            render : function(){
              var headerConfig = this.model.get('headerConfig');
              for (var columnType in headerConfig){
                //this.$el.append(new VisibilityButton({name: columnType}).el);
                var columnViews = [];
                for (var header in headerConfig[columnType]){
                  if (headerConfig[columnType][header]){
                    className = 'columnOption shown'
                  } else {
                    className = 'columnOption' 
                  }
                  columnViews.push(new Column({model : this.model,
                                  name: header,
                                  type : columnType,
                                  header : header,
                                  className : className,
                                  shown : headerConfig[columnType][header],
                                  id : header + 'Option'}));
                }
                columnsCollectionView = new Columns({name: columnType, model : this.model, columns : columnViews});
                this.$el.append(columnType);
                this.$el.append(new VisibilityButton({target: columnsCollectionView.$el}).el);
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
                        this.target = options.target;
                        this.render();      
                  },

                  render : function(){
                    this.$el.html('+');
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
                        console.log(this.target);
                        if (!this.height){
                              this.height = this.calculateHeight();
                        }
                        if (this.target.css('height') == '0px'){
                              this.target.css('height',this.height);
                              this.$el.html('-');
                        } else {
                              this.target.css('height','0px');
                              //this.target.addClass('open');
                              this.$el.html('+');
                        }
                  }
      });



