define([],
	function(){
		return Backbone.Model.extend({

			defaults : {
				status : 'loading'
			},

			initialize : function(config){
				console.log('Initializing summary model');
				//this.model = options.models;
				this.names = config.names;
				var models = config.models;

				//this.model('Variant').on('change:All headers', this.getVariantData, this);

				this.variantModel = models.findWhere({'name':'Variant'});
				this.geneModel = models.findWhere({'name':'Gene'});
				this.noncodingModel = models.findWhere({'name':'Noncoding'});
				this.errorModel = models.findWhere({'name':'Error'});

				/*this.variantModel.on('change:length', this.getLength, this);
				this.geneModel.on('change:length', this.getLength, this);
				this.noncodingModel.on('change:length', this.getLength, this);
				this.errorModel.on('change:length', this.getLength, this);*/
				view = this;
				models.each(function(model){
					model.on('change:length', view.getLength, view);
					model.on('change:ID', view.getData, view);
				});
				//models.on('change:length', this.getLength, this);

				/*
				this.variantModel.on('change:All headers', this.getVariantData, this);
				/*
				this.variantModel.on('change:length', this.getVariantDataLength, this);
				this.variantModel.on('change:Summary Data', this.renderCircosPlot, this);
				this.geneModel.on('change:data', this.getGeneData, this);
				this.geneModel.on('change:length', this.getGeneDataLength, this);
				this.noncodingModel.on('change:length', this.getNoncodingData, this);  // Only the length is needed for noncoding data.
				this.errorModel.on('change:length', this.getErrorData, this);*/
				//this.on('change', this.updateButton, this);

				this.stats = {};
			},
			
			getLength : function(dataset){
				var name = dataset.name == 'Noncoding' ? dataset.name.toLowerCase() + ' variant' : dataset.name.toLowerCase();
				this.set('Number of ' + name + 's', dataset.get('length'));
			},

			formatCircosData : function(data, view){
				console.log('Creating circos data');
				var headers = data.shift();
				var circosData = {};
				var value;
				var category;
				for (var x = 0; x < headers.length; x++){
					category = [];
					for (var y = 0; y < data.length; y++){
						value = data[y][x];
						category.push(value);
					}
					circosData[headers[x]] = category;
				}

				var data = circosData;

				var formattedData = [];
				for (var i = 0; i < data[Object.keys(data)[0]].length; i++){
					datum = {};
					for (type in data) {
						datum[type] = data[type][i];
					}
					formattedData.push(datum);
				}

				var data = formattedData;

				chromosomes = [["1",248956422],
								["2", 242193529],
								["3", 198295559],
								["4", 190214555],
								["5", 181538259],
								["6", 170805979],
								["7", 159345973],
								["8", 145138636],
								["9", 138394717],
								["10", 133797422],
								["11", 135086622],
								["12", 133275309],
								["13", 114364328],
								["14", 107043718],
								["15", 101991189],
								["16", 90338345],
								["17", 83257441],
								["18", 80373285],
								["19", 58617616],
								["20", 64444167],
								["21", 46709983],
								["22", 50818468],
								["X", 156040895],
								["Y", 57227415]];
				var chromosomeMap = {};
				for (var i = 0; i < chromosomes.length; i++){
					chromosomeMap[chromosomes[i][0]] = chromosomes[i][1];
				}

				SOtypeData = {};
				SOtypes = ['Non-Silent', 'Missense', 'Inactivating'];
				SOfilters = [function(a){ return a['Sequence ontology'] == 'SY';},
						function(a){return a['Sequence ontology'] == 'MS';},
						 function(a){return a['Sequence ontology'] != 'MS' && a['Sequence ontology'] != 'SY';}];
			    var inc = 5000000;
			    circos_data = {};

				for (var i = 0; i < SOtypes.length; i++){
					// Non-silent, missense, or inactivating sorted data
					type_data = data.filter(SOfilters[i]);
					//console.log(data);
					for (chromosome in chromosomeMap){
						chrom_data = type_data.filter(function(a){
							return a['Chromosome'].replace('chr','') == chromosome;
						})
						if (chrom_data.length > 0){
							chrom_length = chromosomeMap[chromosome];
							for (var x = 0; x < chrom_length; x += inc){
								start = x;
								end = chrom_length >= x + inc ? x + inc : chrom_length;
								des = SOtypes[i] + '(';
								pos_data = chrom_data.filter(function(a){
									return start <= a['Position'] && a['Position'] < end;
								})
								val = pos_data.length;
								des = val == 0 ? "" : des;
								for (var y = 0; y < val; y++){
									des += pos_data[y]['HUGO symbol'] + ',';
									if (y == val - 1){
										des = des.slice(0,-1) + ')';
									}
								}

								//datum = {chr: pos_data[0]['Chromosome'].replace('chr',''),
								datum = {chr: chromosome,
										start: String(start),
										end: String(end),
										name: des,
										value: String(val)};

								if (circos_data[SOtypes[i]]){
									circos_data[SOtypes[i]].push(datum);
								} else {
									circos_data[SOtypes[i]] = [datum];
								}
							}
						}
					}
				}
				view.set('Circos data', circos_data);
			},


			getData : function(dataset){
				console.log('Getting summary data for ' + dataset.name);
				if (dataset.name == 'Variant'){
					this.getColumns(this.formatCircosData, dataset, ['Chromosome', 'Position', 'Sequence ontology', 'HUGO symbol']);
					this.getColumns(this.countSummaryData, dataset, ['CGL driver class', 'Sequence ontology']); //'GeneCards summary (from http://www.genecards.org)'
				} else if (dataset.name == 'Gene'){
					this.getColumns(this.getTopGenes, dataset, ['HUGO symbol', 'VEST gene p-value']);
				}
			},

			getGeneData : function(data, view){
				//console.log('')
				//columns = this.geneModel.getColumns(['HUGO symbol', 'VEST gene p-value']);
				var data = view.tableToDict(data);
				view.set('Top Genes (VEST-composite-p-value)',this.getTopGenes(data));
			},

			tableToDict : function(data){
				var header = data.shift();
				newDict = {};
				for (var i = 0; i < header.length; i++){
					list = [];
					for (var j = 0; j < data.length; j++){
						list.push(data[j][i]);
					}
					newDict[header[i]] = list;
				}
				return newDict;
			},

			countSummaryData : function(data, view){
				console.log('Counting summary data');
				var data = view.tableToDict(data);
				var cancerGenomeLandscape = view.switchValues(data['CGL driver class'], {'' : 'Other genes'});
				var sequenceOntologies = view.switchValues(data['Sequence ontology'], {'SG' : 'Stopgain',
																					'MS' : 'Missense',
																					'CS' : 'Complex sub',
																					'FD' : 'Frameshift del',
																					'FI' : 'Frameshift ins',
																					'SL' : 'Stoploss',
																					'SS' : 'Splice site',
																					'SY' : 'Synonymous',
																					'UN' : 'Unknown'});
				view.set('Sequence Ontologies', view.countInstancesOf(cancerGenomeLandscape));
				view.set('Cancer Genome Landscape', view.countInstancesOf(sequenceOntologies));
			},

			getColumns : function(func, model, headers){
				var ID = model.get('ID');
				var allHeaders = model.get('All headers');
				indices = '';
				for (var i = 0; i < headers.length; i++){
					indices = indices + allHeaders.indexOf(headers[i]) + ',';
				}
				indices = indices.slice(0, indices.length-1);
				var xhr = jQuery.getJSON('/api/datasets/' + ID, {
						data_type : 'raw_data',
						provider : 'column',
						indeces : indices
					});
				xhr.func = func;
				var view = this;
				xhr.done(function(response){
					xhr.func(response.data, view);
					//console.log('CIrcos data finished');
					//view.at(1).set('Summary Data', response.data);
				});
			},

			old_getVariantData : function(){
				//Variant
				toCount = ['CGL driver class', 'Sequence ontology','GeneCards summary (from http://www.genecards.org)']
				toGet = ['Gene', 'Chromosome', 'Position']

				//'GeneCards summary (from http://www.genecards.org)'
				/*variantStats = this.variantModel.countAndGet({toCount : ['CGL driver class', 'Sequence ontology'],
												toGet : ['HUGO symbol', 'Chromosome', 'Position', 'Sequence ontology']});*/

				columns = this.variantModel.getColumns(['CGL driver class', 'HUGO symbol', 'Sequence ontology','GeneCards summary (from http://www.genecards.org)']);
				
				
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
				//var circosData = this.variantModel.getColumns(['Chromosome', 'Position', 'Sequence ontology', 'HUGO symbol']);
				//this.set('Circos Plot', circosData);
			},




			setDatasets : function(){
				this.variantModel = this.collection.findWhere({'name' : 'Variant'});
				this.geneModel = this.collection.findWhere({'name' : 'Gene'});
				this.noncodingModel = this.collection.findWhere({'name' : 'Noncoding'});
				this.errorModel = this.collection.findWhere({'name' : 'Error'});
				this.variantModel.on('change:length', this.getVariantDataLength, this);
			},

			checkProgress : function(){
				numberOfCalculations = 9;
				if (Object.keys(this.attributes).length - 2 >= numberOfCalculations && this.get('status') == 'loading'){
					this.set('status','done');
				}
			},

			switchValues : function(values, map){
				var newValues = [];
				var value;
				for (var i = 0; i < values.length; i++){
					value = values[i] || '';

					if (map[value]){
						values[i] = map[value]
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


			getTopGenes : function(table, view){
				var table = view.tableToDict(table);
				topValues = [];
				console.log(table);
				if (Object.keys(table).length == 2){
					col1 = Object.keys(table)[0];
					col2 = Object.keys(table)[1];;
					for (var i = 0; i < table[col1].length; i++){
						datum = {};
						gene = table[col1][i];
						p_value = table[col2][i];
						datum[col1] = gene;
						datum[col2] = p_value;
						topValues.push(datum);
					}
				}
				topValues.sort(function(a,b){
					return b[Object.keys(b)[1]] - a[Object.keys(a)[1]];
				})
				view.set('Top Genes (VEST-composite-p-value)', topValues.splice(0,10));
			}

	})
});