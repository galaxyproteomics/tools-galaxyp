/**
 *  Main application class.
 */
define(['viewer'],
    function(ContentView, Portlet) {
    return Backbone.View.extend({
        
        el : $('#container'),

    	initialize: function(config){

            /*var names = options.dataset_names;
            var filename = options.filename;
            var dataset_name;

            var current_index = -1;
            for (var i = 0; i < names.length; i++){
                if (filename.indexOf(names[i]) > 0){
                    current_index = i;
                    dataset_name = names[i];
                }
            }*/
            var name = config.report_name;
        
            name = name.indexOf(' on data') > 0 ? 
                name.slice(0,name.indexOf(' on data')) :
                name;
            var names = config.report_names;

            this.index = Object.keys(names).indexOf(name) + 1;
            config.index = this.index;
          /* this.contentView = new ContentView({dataset_id : options.dataset_id,
                                                dataset_names : names,
                                                history_id : options.history_id,
                                                filename : options.filename,
                                                current_index : current_index,
                                                dataset_name : dataset_name});*/
            this.contentView = new ContentView(config);
           //this.dataset_name = options.dataset_name;
    	   this.render();




           this.footer = ['<footer>',
            '<a href="http://cravat.us/CRAVAT/">CRAVAT</a> is developed by the ',
            '<a href="http://karchinlab.org/">Karchin Lab</a> at <a href="https://www.jhu.edu/">',
            "John Hopkins University's</a> <a href='https://icm.jhu.edu/''>Institute for Computational Medicine</a>",
            '<p></p><a href="http://cravat.us/CRAVAT/disclaimer.html"> Disclaimer </a> | <a href="http://cravat.us/CRAVAT/privacyPolicy.html">Privacy Policy</a> | <a href="http://cravat.us/CRAVAT/licensing.html">Licensing</a></footer>'].join('');
        },

        render : function(){
            this.$el.append(this.contentView.tabViewer.el);
            this.$el.append(this.contentView.el);
            this.$el.append(this.footer);
            $('.nav-tabs button:eq(' + this.index + ')').click();
        }
    });
});