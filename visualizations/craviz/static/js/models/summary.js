define([],
	function(){
		return Backbone.Model.extend({

			defaults : {
				status : 'loading'
			},

			initialize : function(options){
				console.log('Initializing summary model');
				this.model = options.models;

				this.variantModel = this.model.where({'name':'variant'})[0];
				this.geneModel = this.model.where({'name':'gene'})[0];
				this.noncodingModel = this.model.where({'name':'noncoding'})[0];
				this.errorModel = this.model.where({'name':'error'})[0];
				

				this.variantModel.on('change:data', this.getVariantData, this);
				this.variantModel.on('change:length', this.getVariantDataLength, this);
				this.geneModel.on('change:data', this.getGeneData, this);
				this.geneModel.on('change:length', this.getGeneDataLength, this);
				this.noncodingModel.on('change:length', this.getNoncodingData, this);  // Only the length is needed for noncoding data.
				this.errorModel.on('change:length', this.getErrorData, this);
				this.on('change', this.checkProgress, this);

				this.stats = {};
			},

			checkProgress : function(){
				numberOfCalculations = 9;
				if (Object.keys(this.attributes).length - 2 >= numberOfCalculations && this.get('status') == 'loading'){
					this.set('status','done');
				}
			},

			getVariantData : function(){
				//Variant
				toCount = ['CGL driver class', 'Sequence ontology','GeneCards summary (from http://www.genecards.org)']
				toGet = ['Gene', 'Chromosome', 'Position']

				//'GeneCards summary (from http://www.genecards.org)'
				/*variantStats = this.variantModel.countAndGet({toCount : ['CGL driver class', 'Sequence ontology'],
												toGet : ['HUGO symbol', 'Chromosome', 'Position', 'Sequence ontology']});*/

				columns = this.variantModel.getColumns(['CGL driver class', 'Gene', 'Sequence ontology','GeneCards summary (from http://www.genecards.org)']);
				
				
				this.set('Job ID', this.model.jobID);
				//this.set('Number of variants', this.variantModel.get('data').length);

				cancerGenomeLandscape = this.switchValues(columns['CGL driver class'], {'' : 'Other genes',
																'TSG' : 'Tumor suppresor genes'});
				sequenceOntologies = this.switchValues(columns['Sequence ontology'], {'SG' : 'Stopgain',
																					'MS' : 'Missense',
																					'CS' : 'Complex sub',
																					'FD' : 'Frameshift del',
																					'FI' : 'Frameshift ins',
																					'SL' : 'Stoploss',
																					'SS' : 'Splice site',
																					'SY' : 'Synonymous',
																					'UN' : 'Unknown'})
				
				this.set('Number of variants', this.variantModel.get('length'));
				this.set('Cancer Genome Landscape',this.countInstancesOf(cancerGenomeLandscape));
				this.set('Sequence Ontologies',this.countInstancesOf(sequenceOntologies));
				this.set('Circos Plot', this.variantModel.getColumns(['Chromosome', 'Position', 'Sequence ontology', 'HUGO symbol']));
			},

			getVariantDataLength : function(){
				this.set('Number of variants', this.variantModel.get('length'));
			},

			switchValues : function(values, map){
				newValues = [];
				for (var i = 0; i < values.length; i++){
					if (map[values[i]]){
						values[i] = map[values[i]]
					}
				}
				return values;
			},

			countInstancesOf : function(column){
				SOcounts = {};
				for (var i = 0; i < column.length; i++){
					SO = column[i];
					SOcounts[SO] == undefined ? SOcounts[SO] = 1 : SOcounts[SO] += 1;
				}
				return SOcounts;
			},

			getGeneData : function(){
				//console.log('')
				columns = this.geneModel.getColumns(['HUGO symbol', 'VEST gene p-value']);
				this.set('Top Genes (VEST-composite-p-value)',this.getTopValues(columns));
			},

			getGeneDataLength : function(){
				this.set('Number of genes', this.geneModel.get('length'));
			},

			getNoncodingData : function(){
				this.set('Number of noncoding variants', this.noncodingModel.get('length'));
			},

			getErrorData : function(){
				this.set('Number of errors', this.errorModel.get('length'));
			},

			getTopValues : function(table){
				topValues = [];
				if (Object.keys(table).length == 2){
					col1 = Object.keys(table)[0];
					col2 = Object.keys(table)[1];
					for (var i = 0; i < table[col1].length; i++){
						datum = {};
						gene = table[col1][i];
						p_value = table[col2][i];
						datum[col1] = gene;
						datum[col2] = p_value;
						topValues.push(datum);
					}
				}
				view = this;
				topValues.sort(function(a,b){
					return b[Object.keys(b)[1]] - a[Object.keys(a)[1]];
				})
				return topValues.splice(0,10);
			}

	})
});