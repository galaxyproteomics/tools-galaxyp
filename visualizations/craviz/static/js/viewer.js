/**
 *  Main application class.
 */
define(['plugin/Views/tabs','plugin/Models/data','plugin/collections/data','plugin/views/panel','plugin/views/summary','plugin/Models/summary'],
    function( Tabs , Dataset, DataCollection, PanelView, SummaryView, SummaryModel) {
    return Backbone.View.extend({
        
        className : 'content',

    	initialize: function(options){
    		var self = this;

			this.id = options.dataset_id;

            var codingData = new Dataset({name: 'variant',
                                        headers : ['Chromosome',
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
                                                            'GWAS Phenotype (GRASP)']});

            var geneData = new Dataset({name: 'gene',
                                        headers : ['Chromosome',
                                                    'HUGO symbol',
                                                    'Number of variants',
                                                    'Sequence ontology',
                                                    'CHASMA gene p-value',
                                                    'VEST gene p-value',
                                                    'CGL driver class',
                                                    'Number of samples with gene mutated']});

            var noncodingData = new Dataset({name: 'noncoding',
                                            headers: ['Chromosome',
                                                        'Position',
                                                        'Strand',
                                                        'Reference base(s)',
                                                        'Alternate base(s)',
                                                        'Sample ID',
                                                        'dbSNP',
                                                        'gnomAD AF Total',
                                                        'UTR/Intron',
                                                        'UTR/Intron Gene',
                                                        'ncRNA Class',
                                                        'ncRNA Name',
                                                        'Repeat Class',
                                                        'Pseudogene',
                                                        'GWAS Phenotype (GRASP)']});

            var errorData = new Dataset({name: 'error'});


            this.dataCollection = new DataCollection([codingData, geneData, noncodingData, errorData]);
            this.dataCollection.fetch(this.id);
          
            var summaryModel = new SummaryModel({models : this.dataCollection});
            
            this.summaryPanel = new SummaryView({model : summaryModel,  id : 'Summary'});
          	this.genePanel      = new PanelView({model : geneData,      id : 'Gene',      table : true});
          	this.codingPanel    = new PanelView({model : codingData,    id : 'Variant',    frameViewer : true});
            this.noncodingPanel = new PanelView({model : noncodingData, id : 'Noncoding', table : true});
            this.errorPanel     = new PanelView({model : errorData,     id : 'Error',      table : true});

			this.tabViewer = new Tabs({id : 'tabs', panels: [this.summaryPanel,
																	this.genePanel,
																	this.codingPanel,
																	this.noncodingPanel,
																	this.errorPanel]});
    		this.render();
        },

        render : function(){
        	//this.$el.append(this.summaryPanel.el);
        	this.$el.append(this.genePanel.el);
        	this.$el.append(this.codingPanel.el);
        	this.$el.append(this.noncodingPanel.el);
        	this.$el.append(this.errorPanel.el);
        }
    });
});