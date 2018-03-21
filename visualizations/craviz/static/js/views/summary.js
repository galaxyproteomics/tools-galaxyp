define(['plugin/Views/sidebar','plugin/lib/nvd3_pie','plugin/lib/biocircos-1.1.2'],
	function(Sidebar){
		return Backbone.View.extend({
			className : 'contentTab',

			initialize : function(){
				this.loadIndicator();
				this.sidebar = new Sidebar({model : this.model});
				this.model.on('change:status', this.render, this);
			},

			loadIndicator : function(){
            	this.$el.append('<div class="loader"><h2>Retrieving Data...</h2><div class="loaderIndicator"></div></div>');
			},

			render : function(){
				this.sidebar.renderSummary();
				this.graphs = {'Pie Charts' : ['Mutations', 'Cancer-Genome-Landscape', 'Sequence-Ontologies']};
				this.$el.html(this.sidebar.el);
				this.$el.append(["<div class='summary'>", "<div id='pie-charts'>",
								"<div id=", this.graphs['Pie Charts'][0] ," class='pie-chart'><svg></svg></div>",
								"<div id=", this.graphs['Pie Charts'][1] ," class='pie-chart'><svg></svg></div>",
								"<div id=", this.graphs['Pie Charts'][2] ," class='pie-chart'><svg></svg></div>",
								"</div>",
								"<div id=", "'Circos-Plot'>", '</div>',
								'<div class="summaryTable"><table id=','"top-genes-table"','</table></div></div>'].join(''));

				this.drawPieChart({data : this.convertToKeyValuePair({'Number of noncoding variants' : this.model.get('Number of noncoding variants'),
																	'Number of variants' : this.model.get('Number of variants')}),
									id : this.graphs['Pie Charts'][0],
									title : 'Mutations'});

				this.drawPieChart({data : this.convertToKeyValuePair(this.model.get('Cancer Genome Landscape')),
									id : 'Cancer-Genome-Landscape',
									title : 'Cancer Genome Landscape'});
				
				this.drawPieChart({data : this.convertToKeyValuePair(this.model.get('Sequence Ontologies')),
									id : this.graphs['Pie Charts'][2],
									title : 'Sequence Ontologies'});
				this.drawCircosPlot();
				this.drawTable();

			},

			drawTable : function(){
				var data = this.model.get('Top Genes (VEST-composite-p-value)');
				data = this.dataTableFormat(data);
				header = data.shift();
				this.dataTable = $('#top-genes-table');
				this.dataTable.DataTable({
					data : data,
					columns : this.formatToDataTableHeader(header),
					searching : false,
					paging: false,
					select : {
						style: 'os',
						className: 'row-selected'
					},
					'scrollX': true
				});
				this.dataTable.DataTable().draw();
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
				
				/*chromosome_SOTypeData = [];
				for (var i = 0; i < this.chromosomes.length; i++){
					datum = data.filter(function(a){
						return a['Chromosome'] == 'chr' + view.chromosomes[i][0];
					});
					if (datum.length > 0){
						for (var j = 0; j < datum.length; j++){
							datum[j]['Chromosome'] = datum[j]['Chromosome'].replace('chr','');
						}
						chromosome_SOTypeData.push(datum);
					}
				}*/

				SOtypeData = {};
				//SOs = ['NS','MS'];
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
				var data = this.formatCircosData(this.transform());
			
				  backgrounds = [[],[],[],[]];
				  histograms = [[],[],[],[]];
				  var radii = [[205, 240], [160,195], [110, 145], [55,90]];
				  colors = ['#FF6666','#FFCCCC','#0099CC','#42f46b'];
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
				  	//histograms[1] = [];

				  var BioCircosGenome = [
				     ["2L" , 23011544],
				     ["2R" , 21146708],
				     ["3L" , 24543557],
				     ["3R" , 27905053],
				     ["X" , 22422827],
				     ["4" , 1351857]
				  ];

				  BioCircos01 = new BioCircos(backgrounds[0],backgrounds[1],backgrounds[2],backgrounds[3],histograms[0],histograms[1],histograms[2],histograms[3],this.chromosomes,{
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


			drawPieChart : function(params){
				

				var ID = params.id;
				var data = params.data;
				var title = params.title;
				

				var height = 300;
				var width = 300;
		 		nv.addGraph(function() {
              		var chart = nv.models.pieChart()
                  		.x(function(d) { return d.label })
                  		.y(function(d) { return d.value })
		                  .showLabels(true)
		                  .width(width)
		                  .height(height);

		                d3.select('#' + ID + ' svg')
		                    .datum(data)
		                  .transition().duration(1200)
		                    .call(chart);

		                d3.select('#' + ID + ' svg')
		                	.append("text")
		                	.attr("x", 200)             
		  					.attr("y", height * .97)
		  					.attr("text-anchor", "middle")  
		  					.style("font-weight","bold")
		  					.style("font-size","15px")
		  					.text(title);

              	return chart;
            	});
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
