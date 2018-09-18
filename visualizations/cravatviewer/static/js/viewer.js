define(['views/tabs','models/data','collections/data','views/panel','views/summary','models/summary'],
    function( Tabs , Dataset, DataCollection, PanelView, SummaryView, SummaryModel) {
    return Backbone.View.extend({
        
        className : 'content',

    	initialize: function(config){
    		var self = this;

            var names = Object.values(config.report_names);
            //var current_index = config.current_index;

            var codingData = new Dataset({name: names[1],
                                        headers : ['Peptide',
                                                    'Chromosome',
                                                            'Position',
                                                            'Strand',
                                                            'Reference base(s)',
                                                            'Alternate base(s)',
                                                            'Sample ID',
                                                            'HUGO symbol',
                                                            'Sequence ontology',
                                                            'Protein sequence change',
                                                            'CHASM p-value',
                                                            'Variant peptide',
                                                            'VEST p-value',
                                                            'COSMIC variant count',
                                                            'gnomAD AF Total',
                                                            'GWAS Phenotype (GRASP)'],
                                        categories : {'Variant Info': ['Input line','ID','Chromosome','Position','Strand','Reference base(s)','Alternate base(s)','Sample ID','HUGO symbol','dbSNP'],
                                                        'Structure': ['Protein 3D variant'],
                                                        'Protein' : ['Reference peptide','Variant peptide'],
                                                        'Variant Impact': ['Sequence ontology','Protein sequence change', 'S.O. transcript', 'S.O. all transcripts','HGVS Genomic','HGVS Protein','HGVS Protein All'],
                                                        'CHASM': ['CHASM p-value','CHASM FDR','CHASM transcript','CHASM score','All transcripts CHASM results'],
                                                        'VEST': ['VEST p-value','VEST FDR','VEST score transcript','VEST score (missense)','VEST score (frameshift indels)','VEST score (inframe indels)','VEST score (stop-gain)','VEST score]([stop-loss)','VEST score (splice site)','All transcripts VEST results'],
                                                        'Disease Association': ['CGL driver class','TARGET','COSMIC ID','COSMIC variant count (tissue)','COSMIC variant count','COSMIC transcript','COSMIC protein change','PubMed article count','PubMed ]search term','ClinVar','ClinVar disease identifier','ClinVar XRef','CGC driver class','CGC inheritance','CGC tumor types somatic','CGC tumor types germline','GWAS NHLBI Key ( GRASP)','GWAS PMID (GRASP)','GWAS Phenotype (GRASP)'],
                                                        'Population Stats': ['1000 Genomes AF','ESP6500 AF (average)','ESP6500 AF (European American)','ESP6500 AF (African American)','gnomAD AF Total','gnomAD AF African','gnomAD AF American','gnomAD  AF Ashkenazi Jewish','gnomAD AF East Asian','gnomAD AF Finnish','gnomAD AF Non-Finnish European','gnomAD AF Other','gnomAD AF South Asian'],
                                                        'Study': ['Number of samples with variant'],
                                                        'Mutation Call Quality': ['Phred','VCF filters','Zygosity','Alternate reads','Total reads','Variant allele frequency'],
                                                        'NDEx': ['NCI pathway hits','NCI pathway IDs','NCI pathway names']}});

           /*headerTypes : {'Variant Info' : ['Input line','ID','Chromosome','Position','Strand','Reference base(s)','Alternate base(s)','Sample ID','HUGO symbol','dbSNP', 'Variant Impact'],
                            'Protein' : ['Peptide'],
                            'Gene info' : ['HUGO symbol', 'Number of variants'],
                            'Structure' : ['Protein 3D variant', 'Protein 3D gene'],
                            'Variant Impact' : ['Sequence ontology','Protein sequence change','S.O. transcript','S.O. all transcripts','HGVS Genomic','HGVS Protein','HGVS Protein All'],
                            'CHASM' : ['CHASM p-value','CHASM FDR','CHASM transcript','CHASM score','All transcripts CHASM results'],
                            'VEST' : ['VEST p-value','VEST FDR','VEST score transcript','VEST score (missense)','VEST score (frameshift indels)','VEST score (inframe indels)','VEST score (stop-gain)','VEST score (stop-loss)','VEST score (splice site)','All transcripts VEST results'],
                            'Disease Association' : ['CGL driver class','TARGET','COSMIC ID','COSMIC variant count (tissue)','COSMIC variant count','COSMIC transcript','COSMIC protein change','PubMed article count','PubMed search term','ClinVar','ClinVar disease identifier','ClinVar XRef','CGC driver class','CGC inheritance','CGC tumor types somatic','CGC tumor types germline','GWAS NHLBI Key (GRASP)','GWAS PMID (GRASP)','GWAS Phenotype (GRASP)'],
                            'Population Stats' : ['1000 Genomes AF','ESP6500 AF (average)','ESP6500 AF (European American)','ESP6500 AF (African American)','gnomAD AF Total','gnomAD AF African','gnomAD AF American','gnomAD AF Ashkenazi Jewish','gnomAD AF East Asian','gnomAD AF Finnish','gnomAD AF Non-Finnish European','gnomAD AF Other','gnomAD AF South Asian'],
                            'Study' : ['Number of samples with variant'],
                            'Mutation Call Quality' : ['Phred', 'VCF filters', 'Zygosity', 'Alternate reads','Total reads', 'Variant allele frequency'],
                            'NDEx' : ['NCI pathway hits','NCI pathway IDs', 'NCI pathway names']},*/

            var geneData = new Dataset({name: names[0],
                                        headers : ['HUGO symbol',
                                                    'Sequence ontology',
                                                    'CHASM gene p-value',
                                                    'VEST gene p-value',
                                                    'CGL driver class',
                                                    'Number of samples with gene mutated'],
                                        categories : {'Gene Info': ['HUGO symbol','Number of variants'],
                                                    'Structure': ['Protein 3D gene'],
                                                    'Variant Impact': ['Sequence ontology'],
                                                    'CHASM': ['CHASM gene score','CHASM gene p-value','CHASM gene FDR'],
                                                    'VEST': ['VEST gene score (non-silent)','VEST gene p-value','VEST gene FDR'],
                                                    'Disease Association': ['CGL driver class','TARGET','Occurrences in COSMIC','COSMIC gene count (tissue)','PubMed article count','PubMed search term','ClinVar disease identifier','ClinVar XRef','CGC [driver class','CGC inheritance','CGC tumor types somatic','CGC tumor types germline'],
                                                    'Study': ['Number of samples with gene mutated'],
                                                    'NDEx': ['NCI pathway hits','NCI pathway IDs','NCI pathway names']}});

            var noncodingData = new Dataset({name: names[2],
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
                                                        'GWAS Phenotype (GRASP)'],
                                            categories: {'Variant Info': ['Input line','ID','Chromosome','Position','Strand','Reference base(s)','Alternate base(s)','Sample ID','HUGO symbol','dbSNP', 'UTR/Intron', 'UTR/Intron Gene', 'UTR/Intron All Transcript','ncRNA Class','ncRNA Name','Repeat Class','Repeat Family','Repeat Name','Pseudogene','Pseudogene Transcript'],
                                                            'Disease Association': ['COSMIC ID','COSMIC variant count (tissue)','COSMIC variant count','COSMIC transcript','COSMIC protein change','GWAS NHLBI Key (GRASP)','GWAS PMID (GRASP)','GWAS Phenotype ( GRASP)'],
                                                            'Population Stats': ['1000 Genomes AF','gnomAD AF Total','gnomAD AF African','gnomAD AF American','gnomAD AF Ashkenazi Jewish','gnomAD AF East Asian','gnomAD AF Finnish','gnomAD AF Non-Finnish  European','gnomAD AF Other','gnomAD AF South Asian'],
                                                            'Study': ['Number of samples with variant'],
                                                            'Mutation Call Quality': ['Phred','VCF filters','Zygosity','Alternate reads','Total reads','Variant allele frequency']}});

            var errorData = new Dataset({name: names[3]});


            this.dataCollection = new DataCollection([summaryData, geneData, codingData, noncodingData, errorData]);
            //summaryData.setDatasets();
            //this.dataCollection.add();
            var summaryData = new SummaryModel({names : names,
                                                models : this.dataCollection});
            
            this.dataCollection.setConfig(config);
            this.dataCollection.fetch();
          
            //var summaryModel = new SummaryModel({models : this.dataCollection});
            
            this.summaryPanel = new SummaryView({model : summaryData, n: 0,  id : 'Summary'});
          	this.genePanel      = new PanelView({model : geneData, n: 1,      id : names[0],      table : true});
          	this.codingPanel    = new PanelView({model : codingData, n: 2,   id : names[1],    frameViewer : true});
            this.noncodingPanel = new PanelView({model : noncodingData, n: 3, id : names[2], table : true});
            this.errorPanel     = new PanelView({model : errorData, n: 4,    id : names[3],      table : true});

			this.tabViewer = new Tabs({ id : 'tabs',
                                                panels: [this.summaryPanel,
																	this.genePanel,
																	this.codingPanel,
																	this.noncodingPanel,
																	this.errorPanel]});
    		this.render();
        },

        render : function(){
        	this.$el.append(this.summaryPanel.el);
        	this.$el.append(this.genePanel.el);
        	this.$el.append(this.codingPanel.el);
        	this.$el.append(this.noncodingPanel.el);
        	this.$el.append(this.errorPanel.el);
        }
    });
});