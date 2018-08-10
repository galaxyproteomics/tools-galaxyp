define(['views/sidebar', 'lib/cytoscape', 'lib/nvd3_pie','lib/biocircos-1.1.2'],
	function(Sidebar, cytoscape){
		return Backbone.View.extend({
			className : 'contentTab',

			initialize : function(){
				this.loadIndicator();
				this.sidebar = new Sidebar({model : this.model});
				//this.model.on('change:status', this.render, this);
				//this.model.on('change', this.changed, this);
				this.drawnChartIDs = [];
				/*this.model.on('change:Circos data', this.drawCircosPlot, this);
				this.model.on('change:Number of noncoding variants ', this.drawPieCharts, this);
				this.model.on('change:Number of variants', this.drawPieCharts, this);
				this.model.on('change:Sequence Ontologies ', this.drawPieCharts, this);
				this.model.on('change:Sequence Ontologies ', this.drawPieCharts, this);
				this.model.on('change:Top Genes (VEST-composite-p-value)', this.drawTable, this);*/
				this.model.on('change', this.checkProgress, this);
				//this.render();
			},

			checkProgress : function(){
				if (Object.keys(this.model.attributes).length >= 11){
					this.drawFigures();
				}
			},

			drawFigures : function(){
				this.render();
				this.drawPieCharts();
				this.drawTable();
				this.drawCircosPlot();
				this.updateButton();
			},

			updateButton : function(){
				$('.nav-tabs button:eq(0)').removeClass('loading');
				$('.nav-tabs button:eq(0)').addClass('loaded');
			},


			loadIndicator : function(){
            	this.$el.append('<div class="indicator"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div>');
			},

			render : function(){
				this.sidebar.renderSummary();
				this.graphs = {'Pie Charts' : ['Mutations', 'Cancer-Genome-Landscape', 'Sequence-Ontologies']};
				this.$el.html(this.sidebar.el);
				$rightCell = $('<div>', {'class' : 'right-cell'});
				$rightCell.append(["<div class='summary'>",
									"<div id='pie-charts'>",
										"<div id=", this.graphs['Pie Charts'][0] ," class='pie-chart bordered'><svg></svg></div>",
										"<div id=", this.graphs['Pie Charts'][1] ," class='pie-chart bordered'><svg></svg></div>",
										"<div id=", this.graphs['Pie Charts'][2] ," class='pie-chart bordered'><svg></svg></div>",
									"</div>",
									"<div id='CircosPlot' class='bordered'><h2>Circos Plot</h2><div id='Circos-Plot'>", '</div></div>',
									'<div class="summaryTable"><h2>Top Genes</h2><table id=','"top-genes-table">','</table></div>',
									'<div id="sigma"></div>',
									//'<div id="ndex" class="bordered"><h2>NDEX Networks</h2><div id="cy"></div></div>',
								'</div>'].join(''));
				this.$el.append($rightCell);
				//this.fetchNDEX();
				/*
				this.drawCircosPlot();
				this.drawTable();
				this.fetchNDEX();

				$('.nav-tabs button:eq(0)').removeClass('loading');
				$('.nav-tabs button:eq(0)').addClass('loaded');*/
			},

			drawPieCharts : function(){
				console.log('Drawing pie charts');
				var ID = this.graphs['Pie Charts'][0];
				//if (this.drawnChartIDs.indexOf(ID) < 0 && this.model.get('Number of noncoding variants') && this.model.get('Number of variants')){
				if (this.drawnChartIDs.indexOf(ID) < 0 && this.model.get('Number of noncoding variants') >= 0 && this.model.get('Number of variants') >=0){;
					this.drawPieChart({data : this.convertToKeyValuePair({'Number of noncoding variants' : this.model.get('Number of noncoding variants'),
																	'Number of variants' : this.model.get('Number of variants')}),
									id : ID,
									title : 'Mutations'});
					this.drawnChartIDs.push(ID);
				}

				ID = this.graphs['Pie Charts'][1];
				if (this.drawnChartIDs.indexOf(ID) < 0 && this.model.get('Cancer Genome Landscape')){
					this.drawPieChart({data : this.convertToKeyValuePair(this.model.get('Cancer Genome Landscape')),
									id : ID,
									title : 'Cancer Genome Landscape'});
					this.drawnChartIDs.push(ID);
				}

				ID = this.graphs['Pie Charts'][2];
				if (this.drawnChartIDs.indexOf(ID) < 0 && this.model.get('Sequence Ontologies')){
					this.drawPieChart({data : this.convertToKeyValuePair(this.model.get('Sequence Ontologies')),
									id : ID,
									title : 'Sequence Ontologies'});
					this.drawnChartIDs.push(ID);
				}
			},


			drawPieChart : function(params){
				console.log('Drawing pie chart!');

				var ID = params.id;
				var data = params.data;
				var title = params.title;
				//var myColors = ["#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"];
				var colorScale = d3.scale.ordinal().range(["#ffd400", "#f28d00", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]).range();
				if (ID == 'Sequence-Ontologies'){
					//myColors = myColors.reverse();
					 //var myColors = ["#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"];
					 var colorScale = d3.scale.ordinal().range(["#dd186d", "#bcbd22", "#17becf"]).range();
				} else if (ID == 'Cancer-Genome-Landscape'){
					//var myColors = ["#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"];
					//myColors = myColors.splice(0, parseInt(myColors.length/2));
					var colorScale = d3.scale.ordinal().range(["#00bc09", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]).range();
				} 

				// var colorScale = d3.scale.ordinal().range(myColors);
				//colorScale = d3.scale.category10();
				// var colorScale = d3.scale.ordinal().range(d3.schemeCategory10);
				//var colorScale = d3.scale.ordinal().range(["#d62728", "#9467bd", "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"]).range();
				var height = 300;
				var width = 300;
		 		nv.addGraph(function() {
              		var chart = nv.models.pieChart()
                  		.x(function(d) { return d.label })
                  		.y(function(d) { return d.value })
		                  .showLabels(true).color(colorScale)
		                  .width(width)
		                  .height(height);

		                d3.select('#' + ID + ' svg')
		                    .datum(data)
		                  .transition().duration(1200)
		                    .call(chart);

		                d3.select('#' + ID + ' svg')
		                	.append("text")
		                	.attr("x", 150)             
		  					.attr("y", height * .99)
		  					.attr("text-anchor", "middle")  
		  					.style("font-weight","bold")
		  					.style("font-size","15px")
		  					.text(title);

              		return chart;
              });
		 	},

			fetchNDEX : function(){
				console.log('Creating NDEX');
				var id = '4623bf6d-6194-11e5-8ac5-06603eb7f303';
				//var id = '3416f1ba-5521-11e7-8f50-0ac135e8bacf';
				var url = ['http://www.ndexbio.org/v2/network/', id].join('');
				var xmlHttp = new XMLHttpRequest(url);
				var view = this;
				xmlHttp.onreadystatechange = function() {
					if (xmlHttp.responseText != ''){
						view.renderNDEX(xmlHttp.responseText);
					}
				}
				xmlHttp.open('GET', url, false);
				xmlHttp.send(null);
			},

			renderNDEX : function(text){
				var i1 = text.indexOf('"nodes":');
				var i2 = text.indexOf('"edges":');
				var i3 = text.indexOf('"networkAttributes":');
				var i4 = text.indexOf('"cartesianLayout":');
				var i5 = text.indexOf('"visualProperties":');
				node_text = text.slice(i1,i2).split('}, {');
				edge_text = text.slice(i2,i3).split('}, {');
				coordinates_text = text.slice(i4,i5).split('}, {');

				var row;

				var positionMap = [];
				var x;
				var y;
				for (var i = 0; i < coordinates_text.length; i++){
					row = coordinates_text[i];
					if (row.replace(/^\s+|\s+$/g, '') != []){
						x = row.match('"x" : ([0-9\.-]+)')[1];
						y = row.match('"y" : ([0-9\.-]+)')[1];
						positionMap.push({x: x, y: y})
					}
				}

  				var dataNDEX = [];
  				var id;
  				var name;
  				idMap = {};
				for (var i = 0; i < node_text.length; i++){
					row = node_text[i];
					if (row.replace(/^\s+|\s+$/g, '') != []){
						id = row.match('"@id" : ([0-9]+)')[1];
						name = row.match('"n" : "([A-Z0-9]+)')[1];
						idMap[id] = name;
						dataNDEX.push({group: "nodes", data: { id: name}, position: { x: parseInt(positionMap[i].x), y: parseInt(positionMap[i].y)}});
					}
				}	

				var s;
				var t;
				var startpt;
				var endpt;
				for (var n = 0; n < edge_text.length; n++){
					row = edge_text[n];
					if (row.replace(/^\s+|\s+$/g, '') != []){
						id = row.match('"@id" : ([0-9]+)')[1];
						s = row.match('"s" : ([0-9]+)')[1];
						t = row.match('"t" : ([0-9]+)')[1];
						i = row.match('"i" : "([a-z-]+)')[1];
						startpt = idMap[s];
						endpt = idMap[t];
						dataNDEX.push({group: "edges", classes: i,data: { id: 'e' + n, source: startpt, target: endpt}});
					}
				}	

				edges = dataNDEX.filter(function(a){
					return a.group == 'nodes'
				})
				nodes = dataNDEX.filter(function(a){
					return a.group == 'edges'
				})
				console.log(dataNDEX)
				console.log('Contains ' + edges.length + ' edges');
				console.log('Contains ' + nodes.length + ' nodes');

				/*sigma.parsers.json(dataNDEX, {
				    container: 'sigma',
				    settings: {
				      defaultNodeColor: '#ec5148'
				    }
				  });*/

				var cy = cytoscape({

				  container: document.getElementById('cy'), // container to render in

				  elements: dataNDEX,

				  style: [ // the stylesheet for the graph
				    {
				      selector: 'node',
				      style: {
				        'background-color': '#666',
				        'label': 'data(id)'
				      }
				    },

				    {
				      selector: 'edge',
				      style: {
				        'width': 3,
				        'line-color': '#ccc',
				        'target-arrow-color': '#ccc',
				        'target-arrow-shape': 'triangle'
				      }
				    },

				    {
				      selector: '.controls-state-change-of',
				      style: {
				        'width': 1,
				        'line-color': '#cc66ff',
				        'target-arrow-color': '#cc66ff',
				        'target-arrow-shape': 'triangle'
				      }
				    },

				    {
				      selector: '.in-complex-with',
				      style: {
				        'width': 1,
				        'line-color': '#4dff4d',
				        'line-style': 'dashed',
				        'target-arrow-color': '#4dff4d',
				        'target-arrow-shape': 'triangle'
				      }
				    },

				    {
				      selector: '.chemical-affects',
				      style: {
				        'width': 1,
				        'line-color': '#b3b3b3',
				        'target-arrow-color': '#b3b3b3',
				        'target-arrow-shape': 'triangle'
				      }
				    },

				    {
				      selector: '.neighbor-of',
				      style: {
				        'width': 1,
				        'line-color': '#ccffe6',
				        'line-style': 'dashed',
				        'target-arrow-color': '#ccffe6',
				        'target-arrow-shape': 'triangle'
				      }
				    },

				    {
				      selector: '.controls-phosphorylation-of',
				      style: {
				        'width': 1,
				        'line-color': '#9900ff',
				        'arrow-scale' : 20000,
				        'target-arrow-fill' : 'filled',
				        'target-arrow-color': '#9900ff',
				        'target-arrow-shape': 'triangle'
				      }
				    },

				    {
				      selector: '.controls-transport-of',
				      style: {
				        'width': 1,
				        'line-color': '#99ccff',
				        'target-arrow-color': '#99ccff',
				        'target-arrow-shape': 'triangle'
				      }
				    }
				  ],

				  layout: {
				    name: 'preset',
				  }

				});
			},

			drawTable : function(){
				this.dataTable = $('#top-genes-table');
				if (!$.fn.DataTable.isDataTable(this.dataTable)){
					// Functions for sorting without including blank cells
			        jQuery.fn.dataTableExt.oSort['mystring-asc'] = function(x,y) {
						var retVal;
						x = $.trim(x);
						y = $.trim(y);

						if (x==y) retVal= 0;
						else if (x == "" || x == " ") retVal= 1;
						else if (y == "" || y == " ") retVal= -1;
						else if (x > y) retVal= 1;
						else retVal = -1; // <- this was missing in version 1

						return retVal;
					}
					jQuery.fn.dataTableExt.oSort['mystring-desc'] = function(y,x) {
						var retVal;
						x = $.trim(x);
						y = $.trim(y);

						if (x==y) retVal= 0; 
						else if (x == "" || x == " ") retVal= -1;
						else if (y == "" || y == " ") retVal= 1;
						else if (x > y) retVal= 1;
						else retVal = -1; // <- this was missing in version 1

						return retVal;
					}

					var data = this.model.get('Top Genes (VEST-composite-p-value)');
					data = this.dataTableFormat(data);
					header = data.shift();
					this.dataTable.DataTable({
						data : data,
						columns : this.formatToDataTableHeader(header),
						searching : false,
						paging: false,
						"order": [[1, "asc"]],
						'scrollX': false
					});
					this.dataTable.DataTable().draw();
				}
			},

			formatToDataTableHeader : function(header){
				header_columns = [];
				for (var i = 0; i < header.length; i++){
					header_columns.push({title:header[i]});
				}
				return header_columns;
			},

			dataTableFormat : function(data){
				headers = Object.keys(data[0]);
				formData = [[headers[0], headers[1]]];
				data.sort(function(a,b){
					return a[headers[1]] - b[headers[1]];
				})
				for (var i = 0; i < data.length; i++){
					datum = [];
					for (var j = 0; j < headers.length; j++){
						datum.push(data[i][headers[j]]);
					}
					formData.push(datum);
				}
				return formData;
			},

			listToDict : function(list){
				newDict = {};
				for (var i = 0; i < list.length; i++){
					newDict[list[i][0]] = list[i][1];
				}
				return newDict;
			},

			formatCircosData : function(data){
				view = this;
				this.chromosomes = [["1" , 249250621],
				     ["2" , 243199373],
				     ["3" , 198022430],
				     ["4" , 191154276],
				     ["5" , 180915260],
				     ["6" , 171115067],
				     ["7" , 159138663],
				     ["8" , 146364022],
				     ["9" , 141213431],
				     ["10" , 135534747],
				     ["11" , 135006516],
				     ["12" , 133851895],
				     ["13" , 115169878],
				     ["14" , 107349540],
				     ["15" , 102531392],
				     ["16" , 90354753],
				     ["17" , 81195210],
				     ["18" , 78077248],
				     ["19" , 59128983],
				     ["20" , 63025520],
				     ["21" , 48129895],
				     ["22" , 51304566],
				     ["X" , 155270560],
				     ["Y" , 59373566]];
				var chromosomeMap = this.listToDict(this.chromosomes);

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
								if (pos_data.length > 0){
									val = pos_data.length;
									for (var y = 0; y < val; y++){
										des += pos_data[y]['HUGO symbol'] + ',';
									}
									des = des.slice(0,-1) + ')';

									datum = {chr: pos_data[0]['Chromosome'].replace('chr',''),
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
				}
				return circos_data;
			},

			transform : function(){
				data = this.model.get('Circos Plot');
				var formattedData = [];
				for (var i = 0; i < data[Object.keys(data)[0]].length; i++){
					datum = {};
					for (type in data) {
						datum[type] = data[type][i];
					}
					formattedData.push(datum);
				}
				return formattedData;
			},

			drawCircosPlot : function(){
				var data = this.model.get('Circos data');
				console.log('Drawing circos plot');
				//var data = this.formatCircosData(this.transform());
			
				  backgrounds = [[],[],[],[]];
				  histograms = [[],[],[],[]];
				  var radii = [[205, 240], [160,195], [110, 145], [55,90]];
				  colors = ['#FF6666','#0099CC','#FFCCCC','#42f46b'];
				  var SO = Object.keys(data);
				  for (var i = 0; i < SO.length; i++){
				  	histograms[i] = [ 'HISTOGRAM0' + (i + 1) , {
					  maxRadius: radii[i][1],
					  minRadius: radii[i][0],
					  histogramFillColor: colors[i],
					} , data[SO[i]]];

				  	backgrounds[i] = ['BACKGROUND0' + (i + 1) , {
				  		BginnerRadius: radii[i][0],
				  		BgouterRadius: radii[i][1],
				  		BgFillColor: "none",
					    BgborderColor : "#000",
					    BgborderSize : 0.5
				  	}]
				  }
				  console.log(histograms);
				  	//histograms[1] = [];

				  var BioCircosGenome = [
				     ["2L" , 23011544],
				     ["2R" , 21146708],
				     ["3L" , 24543557],
				     ["3R" , 27905053],
				     ["X" , 22422827],
				     ["4" , 1351857]
				  ];


				  BioCircos01 = new BioCircos(backgrounds[0],backgrounds[1],backgrounds[2],backgrounds[3],histograms[0],histograms[1],histograms[2],histograms[3],chromosomes,{
				     target : "Circos-Plot",
				     svgWidth : 600,
				     svgHeight : 600,
				     chrPad : 0.04,
				     innerRadius: 246,
				     outerRadius: 252,
				     zoom : true,
				     genomeFillColor: ["#999999"],
				     HISTOGRAMMouseEvent : true,
				     HISTOGRAMMouseClickDisplay : false,
				     HISTOGRAMMouseClickColor : "red",            //"none","red"
				     HISTOGRAMMouseClickOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseClickStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseClickStrokeWidth : "none",          //"none",3
					 HISTOGRAMMouseDownDisplay : false,
				     HISTOGRAMMouseDownColor : "red",            //"none","red"
				     HISTOGRAMMouseDownOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseDownStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseDownStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseEnterDisplay : false,
				     HISTOGRAMMouseEnterColor : "red",            //"none","red"
				     HISTOGRAMMouseEnterOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseEnterStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseEnterStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseLeaveDisplay : false,
				     //HISTOGRAMMouseLeaveColor : "red",            //"none","red"
				     HISTOGRAMMouseLeaveOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseLeaveStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseLeaveStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseMoveDisplay : false,
				     HISTOGRAMMouseMoveColor : "red",            //"none","red"
				     HISTOGRAMMouseMoveOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseMoveStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseMoveStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseOutDisplay : true,
				     HISTOGRAMMouseOutAnimationTime : 500,
				     HISTOGRAMMouseOutColor : "red",            //"none","red"
				     HISTOGRAMMouseOutOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseOutStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseOutStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseUpDisplay : true,
				     //HISTOGRAMMouseUpColor : "red",            //"none","red"
				     HISTOGRAMMouseUpOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseUpStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseUpStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseOverDisplay : true,
				     HISTOGRAMMouseOverColor : "red",            //"none","red"
				     HISTOGRAMMouseOverOpacity : 1.0,            //"none",1.0
				     HISTOGRAMMouseOverStrokeColor : "none",  //"none","#F26223"
				     HISTOGRAMMouseOverStrokeWidth : "none",          //"none",3
				     HISTOGRAMMouseOverTooltipsHtml01 : "chr :",
				     HISTOGRAMMouseOverTooltipsHtml02 : "<br>position: ",
				     HISTOGRAMMouseOverTooltipsHtml03 : "-",
				     HISTOGRAMMouseOverTooltipsHtml04 : "<br>name : ",
				     HISTOGRAMMouseOverTooltipsHtml05 : "<br>value : ",
				     HISTOGRAMMouseOverTooltipsHtml06 : "",
				     HISTOGRAMMouseOverTooltipsPosition : "absolute",
				     HISTOGRAMMouseOverTooltipsBackgroundColor : "white",
				     HISTOGRAMMouseOverTooltipsBorderStyle : "solid",
				     HISTOGRAMMouseOverTooltipsBorderWidth : 0,
				     HISTOGRAMMouseOverTooltipsPadding : "3px",
				     HISTOGRAMMouseOverTooltipsBorderRadius : "3px",
				     HISTOGRAMMouseOverTooltipsOpacity : 0.8,
				     genomeBorder : {
				        display : true,
				        borderColor : "#000",
				        borderSize : 0.5
				     },
				     ticks : {
				        display : false,
				        len : 5,
				        color : "#000",
				        textSize : 10,
				        textColor : "#000",
				        scale : 2000000
				     },
				     genomeLabel : {
				        display : true,
				        textSize : 15,
				        textColor : "#000",
				        dx : 0.028,
				        dy : "-0.55em"
				     }
				  });
				  BioCircos01.draw_genome(BioCircos01.genomeLength);
			},


		 	convertToKeyValuePair : function(data){
				nv_input = [];
				
				for (var i = 0; i < Object.keys(data).length; i++){
					key = Object.keys(data)[i];
					value = data[key];
					nv_input.push({"label" : key, "value" : value});
				}
				return nv_input;
			}
			
		});
	});
