/**
 *  Main application class.
 */
define(['plugin/viewer'],
    function(ContentView, Portlet) {
    return Backbone.View.extend({
        
        el : $('#container'),

    	initialize: function(options){

           this.contentView = new ContentView({dataset_id : options.dataset_id});

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
            //this.$el.append(this.portlet.el);
            $('.tab-button:eq(3)').click();
        }
    });
});