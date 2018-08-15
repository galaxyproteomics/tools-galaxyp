define ([''],
	function(){
		return Backbone.Collection.extend({

			initialize : function () {
				console.log('Data collection has initialized!');
				this.jobID = null;
				this.datasetID = null;
				this.datasetIDs = [];
				/*this.reportNames = {'#Gene Level Annotation Report' : 'Gene',
							'#Variant Additional Details Report' : 'Variant',
                            '#Non-coding Variant Report' : 'Noncoding',
                            '#Input Errors Report' : 'Error'};*/
                this.responseNames = {'Gene Level Annotation' : 'Gene',
            							'Variant' : 'Variant',
            								'Non-coding Variant' : 'Noncoding',
            								'Errors' : 'Error'};
                this.datasets = [];
                //this.findWhere({'name' : 'Variant'}).on('change:length', this.yo, this);
                //this.at(1).on('change:length', this.yo, this);
			},


			setConfig : function(config){
				this.report_name = config.report_name;
				this.report_names = config.report_names;
				this.dataset_id = config.dataset_id;
				console.log('Dataset ID is ' + this.dataset_id);
				this.dataset_hid = config.dataset_hid;
				this.history_id = config.history_id;
				this.init_index = config.index;
				this.jobID = this.getJobID(config.peek);
				//this.jobID = 'rsajulga' + this.jobID.slice(8,this.jobID.length);
				//this.findWhere({'name' : 'Variant'}).on('change:length', this.yo, this);
			},

			// fetchHistoryID: Fetches history ID, then finds its dataset IDs...
			// fetchDatasetIDs: ...then finds this dataset's ID within the list and returns the relevant IDs around it...
			// fetchData: ...then uses those IDs to fetch their respective datasets.
			fetch : function(){
				// Selects the dataset with the given dataset name
				//var current_dataset = this.where({'name' : this.dataset_name})[0];
				//console.log(config.filename);
				//this.retrieveHeaders(current_dataset, this.dataset_id);
				//this.fetchDatasetIDs(this.history_id);
				//this.fetchHistoryID();

				// Loads the selected dataset
				console.log('Loaded dataset');
				this.setDataset(this.at(this.init_index), this.dataset_id);

				var collex_hid = this.dataset_hid - Object.keys(this.report_names).indexOf(this.report_name) + 4;

	            var url = '/api/histories/' + this.history_id + '/contents/dataset_collections/';

	            modelCollex = this;
	            var xhr = jQuery.getJSON(url);
	            xhr.done(function(response){
	                console.log('Obtained dataset_collection info from current history');
	                var response = response.filter( function(a) {
	                    return a.hid == collex_hid;
	                })
	                collex_id = response[0].id;

	                var xhr = jQuery.getJSON(url + collex_id);
	                xhr.done(function(response){
	                    console.log('Obtained info from current dataset collection');
	                    var datasets = response.elements;
	                    var dataset_ids = [];
	                    var id;
	                    //console.log(datasets);
	                    for (var i = 1; i <= datasets.length; i++){
	                    	id = datasets[i - 1].object.id;
	                        dataset_ids.push(id);

	                        if (i != modelCollex.init_index){
	                        	modelCollex.setDataset(modelCollex.at(i), id);
	                        } 
	                        modelCollex.at(i).id = id;
	                    }
	                    modelCollex.dataset_ids = dataset_ids;
	                    //modelCollex.findWhere({'name' : 'Summary'}).fetchSummaryData(datasets);
	                })
	            })
			},

			// Retrieves and sets the headers of each dataset. Once finished, the ID of each dataset is set.
			setDataset: function(dataset, ID){
				view = this;
				var xhr = $.ajax({
						url: '/api/datasets/' + ID,
						contentType: 'application/json; charset=utf-8',
                        dataType : 'json',
                        "data": {data_type : 'raw_data',
                            provider : 'column',
                            limit: 1},
                        success: function(response, status, xhr){
                        	var headers = (response.data[0].length == 1) ? response.data[0][0].split('$%$') : response.data[0];
                        	xhr.dataset.set('All headers', headers);
                        	//console.log(xhr.dataset);
                        	//view.at(0).getColumns();
                        	xhr.dataset.set('Job ID', view.jobID);
                        	xhr.dataset.setData(xhr.id);

							if (xhr.dataset.name == 'Variant'){
	                        	var indices = []
	                        	var gene_headers = ['ID', 'Chromosome', 'Position', 'Sequence ontology', 'Protein sequence change', 'CHASM p-value', 'VEST p-value', 'Reference base(s)', 'Alternate base(s)'];
	                        	for (var i = 0; i < headers.length; i++){
	                        		if (gene_headers.indexOf(headers[i]) >= 0){
	                        			indices.push(i);
	                        		}
	                        	}
	                        	//console.log(indices.join(','));
								var xhr3 = $.ajax({
									url: '/api/datasets/' + xhr.id,
									contentType: 'application/json; charset=utf-8',
									dataType : 'json',
									'data': {data_type: 'raw_data',
											provider : 'column',
											limit : 100000,
											indeces : indices.join(',')},
									success: function(response, status, xhr){
										xhr3.dataset.set('Gene data', response.data);
									}
								})
								xhr3.dataset = xhr.dataset;
							}
                        	//xhr.dataset.set('ID', xhr.id);
                        }
					})
					xhr.id = ID;
					xhr.dataset = dataset;

				view.comment_lines = 11;
				var xhr2 = $.ajax({
						url: '/api/datasets/' + ID,
                        success: function(response, status, xhr2){
                        	//if(/(CRAVAT: [\w ]+ Report).*/.exec(response.name)){
                        	if (xhr.dataset.name != xhr2.view.responseNames[/CRAVAT: ([\w- ]+?)( Report)? on .*/.exec(response.name)[1]] || xhr2.view.getJobID(response.peek) != xhr2.view.jobID){
                        		console.log('Wrong ID for ' + xhr.dataset.name);
                        		//view.findDataset(xhr.dataset, 1, 5);
                        		// Insert case for looking through history for correct ID
                        	} else {
                        		//xhr.dataset.set('Length');
                        		var index = response.misc_blurb.search(/ lines/);
								var number = parseInt(response.misc_blurb.slice(0,index).replace(',',''));
								//var comment_lines = xhr.dataset.name == 'Gene' ? xhr2.view.comment_lines + 1 : xhr2.view.comment_lines;
								var comment_lines = 1;
								//var length = number - comment_lines;
								//console.log(number);
								xhr.dataset.set('length', number - 1);
								//console.log(xhr.dataset);
								//view.at(n).set('length', parseInt(number) - view.comment_lines);
	                        }
                        }
					})
				//xhr2.reference = xhr;
				xhr2.view = view;
				xhr2.id = ID;
				xhr2.dataset = dataset;
			},

			fetchSummaryData : function(){
				// Gene data
				//var ID = this.datasetIDs[this.reportNames[1]];


				// Circos plot
				if (false){
					var ID = this.datasetIDs[this.reportNames[0]];
					var indices = '2,3,10,9';
					var xhr = jQuery.getJSON('/api/datasets/' + ID, {
						data_type : 'raw_data',
						provider : 'column',
						indeces : indices
					});
					var view = this;
					xhr.done(function(response){
						console.log('CIrcos data finished');
						view.at(1).set('Summary Data', response.data);
					});
				}
				//this.getColumns('Variant', '2,3,10,9', 'Summary Data');
			},

			getJobID : function(peek){
				return peek.slice(peek.indexOf('Job Id') + 8, -1).split('</td>')[0];
			},

			/*getColumns : function(name, indices, setvar){
				var dataset = this.where({'name' : name})[0];
				var summaryModel = this.at(0);

				var xhr = jQuery.getJSON('/api/datasets/' + dataset.id, {
						data_type : 'raw_data',
						provider : 'column',
						indeces : indices
					});
					var view = this;
					xhr.done(function(response){
						console.log('CIrcos data finished');
						console.log(response.data);
						//view.at(1).set('Summary Data', response.data);
					});
			},

			/*getJobID : function(response){
				return response.peek.slice(response.peek.indexOf('Job Id') + 8, -1).split('</td>')[0];
			},

			fetchDatasetIDs : function(history_id){
				//this.report_name = response.metadata_column_names[0];
				//console.log(this.report_name);
				console.log(this.dataset_name);

				var view = this;
				//var historyID = response.history_id;
				//var i = response.metadata_column_names[0]; // Index of current dataset within the history

				//this.jobID =  this.getJobID(response);

				var xhr = jQuery.getJSON('/api/histories/' + history_id);

				xhr.done(function(response){
					console.log('1.) Obtaining dataset IDs');
					console.log(response);

					// List of IDs within this history
					view.IDs = response.state_ids.ok;
					
					reportIndex = Object.keys(view.reportNames).indexOf(view.report_name);

					// Index of dataset within history
					datasetIndex = view.IDs.indexOf(view.dataset_id);

					// Index of first report
					i = datasetIndex - reportIndex;
					view.dataset_index = i;

					//for(var n = 0; n < view.reportNames.length; n++){
					//n = 0;
					for (report_name in view.reportNames){
						view.datasetIDs[report_name] = view.IDs[i++];
						view.datasets.push({report_name : report_name,
												dataset_id : view.IDs[i-1]});
					}
					view.fetchDatasets();
					//view.fetchSummaryData();
					view.at(0).fetchData(view.datasetIDs);
				});
			},*/


			findDataset : function(dataset, n, limit){
				var correct_id = null;
				var i = this.dataset_index;
				var x;
				var dataset_id;
				var oscillating = true;
				var IDs = this.IDs;
				console.log('Finding dataset');
				var j = 0;
				var dataset_name = dataset.name;
				var found = false;
				var view = this;
				while (!correct_id && 0 <= i && i < IDs.length && j < limit){
					j++;
				//while (false){
					dataset_id = IDs[i];
					var xhr = $.ajax({
							url: '/api/datasets/' + dataset_id,
	                        success: function(response, status, xhr){
	                        	var jobID = view.getJobID(response);
	                        	var report_name = response.metadata_column_names[0];
	                        	if (!found){
		                        	if (jobID == view.jobID && dataset_name == view.reportNames[report_name]){
		                        		console.log("Found it");
		                        		// Check for Job ID too
		                        		view.retrieveHeaders(dataset, xhr.id);
		                        		found = true;
		                        	} else {
		                        		if (j < limit) {
			                        		console.log('going again');
			                        		//view.findDataset(dataset_name, n, 10);
		                        		}
		                        	}
		                        }
	                        }
						})
					xhr.id = dataset_id;
					xhr.name = dataset.name;
					i = i + n;
					if (oscillating){
						if (0 <= i && i < IDs.length){
							n > 0 ? n++ : n--;
							n = n * -1;
						} 
						if (i == 0){
							i = i + (n * -1) + 1;
							n = 1;
							oscillating = false;
						} else {
							i = i + (n * -1) - 1;
							n = -1;
							oscillating = false;
						}
					}
				}
			},

			checkName : function(IDs){
				for (var i = 0; i < IDs.length; i++){
					var xhr = jQuery.getJSON('/api/datasets/' + IDs[i]);
					xhr.done(function(response){
						console.log(response.name);
						var match = response.name.match('.*PSM.*');
						if (match){
							console.log(match);
						}
					});
				}

			},


			fetchDatasets : function(){
				console.log('2.) Obtaining data for each dataset: ');
				// Issues each dataModel to fetch their datasets by feeding them their corresponding dataset IDs.
				this.lim = 100000;
				this.comment_lines = 11;
				var view = this;
				//jobID_regex = re.compile('Job Id:')
				//for (var i = 0; i < Object.keys(this.reportNames.length; i++){
				for (report_name in this.reportNames){
						//this.at(i).fetchData(this.datasetIDs[this.reportNames[i]]);
						var dataset = this.where({'name' : this.reportNames[report_name]})[0];

						var ID = this.datasetIDs[report_name];
						//  Obtains the lengths of the datasets
						//var xhr2 = jQuery.getJSON('/api/datasets/' + ID);
						//this.at(i+1).id = ID;
						//dataset.id = ID;

						/*xhr2.done(function(response){
							var dataset = view.datasets.filter(function(a){
								return a.report_name == response.metadata_column_names[0]
							})
							n = dataset[0].id;
							index = response.misc_blurb.search(/ lines/);
							number = parseInt(response.misc_blurb.slice(0,index).replace(',',''));
							view.at(n).set('length', parseInt(number) - view.comment_lines);
						});*/

						//view.at(i).set('ID', ID);

					if (dataset.name != this.dataset_name){
						this.retrieveHeaders(dataset, ID);
					}
				}

			}
		})
	})