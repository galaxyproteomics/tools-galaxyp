define([],
	function(){
		return Backbone.Model.extend({
			defaults: {
				data : [],
				summaryData : [],
				ID : '',
				name : 'CRAVAT Output', 
				shownHeaders : [],
				headerConfig : {},
				'Sorting data' : [],
			},


			headerTypes : {'Variant Info' : ['Input line','ID','Chromosome','Position','Strand','Reference base(s)','Alternate base(s)','Sample ID','HUGO symbol','dbSNP', 'Variant Impact'],
							'Structure' : ['Protein 3D variant'],
							'Variant Impact' : ['Sequence ontology','Protein sequence change','S.O. transcript','S.O. all transcripts','HGVS Genomic','HGVS Protein','HGVS Protein All'],
							'CHASM' : ['CHASM p-value','CHASM FDR','CHASM transcript','CHASM score','All transcripts CHASM results'],
							'VEST' : ['VEST p-value','VEST FDR','VEST score transcript','VEST score (missense)','VEST score (frameshift indels)','VEST score (inframe indels)','VEST score (stop-gain)','VEST score (stop-loss)','VEST score (splice site)','All transcripts VEST results'],
							'Disease Association' : ['CGL driver class','TARGET','COSMIC ID','COSMIC variant count (tissue)','COSMIC variant count','COSMIC transcript','COSMIC protein change','PubMed article count','PubMed search term','ClinVar','ClinVar disease identifier','ClinVar XRef','CGC driver class','CGC inheritance','CGC tumor types somatic','CGC tumor types germline','GWAS NHLBI Key (GRASP)','GWAS PMID (GRASP)','GWAS Phenotype (GRASP)'],
							'Population Stats' : ['1000 Genomes AF','ESP6500 AF (average)','ESP6500 AF (European American)','ESP6500 AF (African American)','gnomAD AF Total','gnomAD AF African','gnomAD AF American','gnomAD AF Ashkenazi Jewish','gnomAD AF East Asian','gnomAD AF Finnish','gnomAD AF Non-Finnish European','gnomAD AF Other','gnomAD AF South Asian'],
							'Study' : ['Number of samples with variant']},


			initialize : function(params){
				this.name = params.name;
				this.exceedsLimit = false;
				//this.shownHeaders = params.headers;
				this.set('shownHeaders',params.headers);
				this.allHeaders = [];
				//this.filterColumns = ['Chromosome', 'Sample ID', 'COSMIC variant count (tissue)', '1000 Genomes AF'];
				this.filterColumns = [{name : 'Chromosome', categorical : true},
									  {name : 'Sample ID', categorical : true},
									  {name : 'COSMIC variant count (tissue)', categorical : false},
									  {name : '1000 Genomes AF', categorical : false}];
				//this.on('change', this.notify, this);
				this.testing = true;
			},

			getColumns : function(headers){
				data = this.get('data');
				columns = {};
				for (var i = 0; i < headers.length; i++){
					index = this.allHeaders.indexOf(headers[i]);
					columns[headers[i]] = [];
					for (var j = 0; j < data.length; j++){
						columns[headers[i]].push(data[j][index]);
					}
				}
				return columns;
			},

			setData : function(data){
				console.log('fetching data for ' + this.name);
				/*this.ID = datasetID;
				this.commentLines = 11;
				var view = this;

				this.lim = 10000;
				this.lim = 10;
				//if (this.name == 'variant'){
				var xhr = jQuery.getJSON('/api/datasets/' + this.ID);
				xhr.done(function(response){
					index = response.misc_blurb.search(/ lines/);
					number = parseInt(response.misc_blurb.slice(0,index).replace(',',''));
					view.set('length', parseInt(number) - view.commentLines);
				});	
				var xhr = jQuery.getJSON('/api/datasets/' + this.ID, {
					data_type : 'raw_data',
					provider : 'column',
					limit: this.lim
				});*/
				var view = this;
				this.data = data;
				view.allHeaders = data.shift();
				if (view.name=='error'){
					view.allHeaders = view.allHeaders[0].split('$%$');
					data = view.fixError(data);
				}
				view.set('headerConfig', view.formatHeaderConfig(view.allHeaders));
				view.fillOutEndData();
				view.set('data',data);
			},

			setSortingData : function(id){
				this.ID = id;
				var view = this;
				var xhr = jQuery.getJSON('/api/datasets/' + id, {
						data_type : 'raw_data',
						provider : 'column',
						limit : 1
					});

					// Get the indices for the sorting headers, then obtain those columns from the dataset.
					xhr.done(function(response){
						view.allHeaders = response.data[0];
						indices = view.headerIndices();
						var xhr = jQuery.getJSON('/api/datasets/' + view.ID, {
							data_type : 'raw_data',
							provider : 'column',
							indeces : indices.join(',')
						});

						xhr.done(function(response){
							console.log('Set sorting data!');
							view.getUniqueValues(response.data);
							view.set('Sorting data', view.formatObjectArray(response.data));
						})
					});
			},

			getUniqueValues : function(data){
				columns = this.filterColumns;
				uniqueValueTypes = {};
				for (var i = 0; i < columns.length; i++){
					if (columns[i].categorical){
						header = columns[i].name;
						uniqueValues = [];
						for (var j = 1; j < data.length; j++){
							value = data[j][i];
							if (uniqueValues.indexOf(value) < 0){
								uniqueValues.push(value);
							}
						}
						if (header == 'Chromosome'){
							uniqueValues.sort(function(a,b){
								return parseInt(a.replace('chr','').replace('X','24').replace('Y','25')) - parseInt(b.replace('chr','').replace('X','24').replace('Y','25'));
							})
						}
						uniqueValueTypes[header] = uniqueValues;
					}
				}
				this.set('Unique values', uniqueValueTypes);
			},

			fixError : function(data){
				newData = [];
				for (var i = 0; i < data.length; i++){
					newData.push(data[i][0].split('$%$'));
				}
				return newData;
			},

			headerIndices : function(){
				headerIndices = [];
				columns = this.filterColumns;
				for (var i = 0; i < columns.length ; i++){
					header = columns[i].name;
					headerIndices.push(this.allHeaders.indexOf(header));
				}
				return headerIndices.sort(function(a,b){return a- b });
			},

			formatObjectArray : function(data){
				headers = data.shift();
				dictList = [];
				for (var i = 0; i < data.length; i++){
					row = data[i];
					dict = {};
					for (var j = 0; j < row.length; j++){
						value = row[j];
						dict[headers[j]] = value;
					}
					dictList.push(dict);
				}
				return dictList;
			},

			columnVisibility : function(){
				colVisibility = [];
				for (var i = 0; i < this.allHeaders.length; i++){
					if (this.get('shownHeaders').indexOf(this.allHeaders[i]) >= 0){
						colVisibility.push(true);
					} else {
						colVisibility.push(false);
					}
				}
				return colVisibility;
			},

			fillOutEndData : function(){
				for (var i = 0; i < this.data.length; i++){
					if (this.allHeaders){
						while(this.allHeaders.length > this.data[i].length){
							this.data[i].push('');
						}
					}
				}
			},

			formatHeaderConfig : function(allHeaders){
				headerConfig = {};
				for (var type in this.headerTypes){
					headers = this.headerTypes[type];
					headerVisibilities = {};
					for (var i = 0; i < headers.length; i++){
						header = headers[i];
						if (allHeaders.indexOf(header) >= 0){
							headerVisibilities[header] = (this.get('shownHeaders').indexOf(header) >= 0);
						} 
					}
					if (Object.keys(headerVisibilities).length > 0){
						headerConfig[type] = headerVisibilities;
					}
				}
				return headerConfig
			},

		})
	})