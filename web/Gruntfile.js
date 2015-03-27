var fs = require("fs");
var embedTemplates = require("./embed-templates").embedTemplates
module.exports = function(grunt){
    grunt.initConfig({
        pkg: grunt.file.readJSON("package.json"),
        embedTemplates: {
          main: {
            hostDocumentPath: "index.html",
            templateDirectoryPath: "templates/",
            outfilePath: "index.html"
          }
        },
        coffee: {
            compile: {
                options: {
                    sourceMap: false,
                    bare: true,
                },
                expand: true,
                cwd: "coffee",
                src: ["**/*.coffee"],
                dest: "js",
                ext: '.js',
            }
        },

        less: {
            compile: {
                options: {
                  paths: [
                    "css/",
                  ]
                },
                files: {
                    "css/style.css": "css/style.less",
                }
            }
        },

        concat: {
            options: {
                separator: ";\n",
                banner: "",
            },
            jsVendorGlobals: {
                src: [
                      'js/vendor/addEventListenerPolyfill.js',
                      'js/vendor/es5-sham.min.js',
                      'js/vendor/es5-shim.min.js',
                      'js/vendor/jquery.min.js',
                      'js/vendor/angular.min.js',

                      'js/vendor/lodash.min.js',
                      'js/vendor/d3.min.js',

                      'js/vendor/highcharts.js',
                      'js/vendor/highcharts-more.js',
                      'js/vendor/highcharts-exporting.js',
                      'js/vendor/highcharts-data.js',
                      'js/vendor/highcharts-3d.js',

                      'js/vendor/filtrex.js',
                      'js/vendor/FileSaver.js',


                      'js/vendor/biojs/jquery-migrate.min.js',
                      'js/vendor/biojs/jquery-ui-1.8.2.custom.min.js',
                      'js/vendor/biojs/Biojs.js',
                      'js/vendor/biojs/Biojs.FeatureViewer.js',
                      'js/vendor/biojs/jquery.tooltip.js',
                      'js/vendor/biojs/raphael.js',
                      'js/vendor/biojs/canvg.js',
                      'js/vendor/biojs/rgbcolor.js',


                      'js/vendor/angular-ui.min.js',
                      'js/vendor/angular-ui-ieshiv.min.js',

                      'js/vendor/ui-bootstrap-0.11.0.min.js',
                      'js/vendor/ui-bootstrap-tpls-0.11.0.min.js',
                      'js/vendor/angular-sanitize.min.js',

                      'js/vendor/eval/*.js'
                      ],
              dest: "js/vendor/vendor.concat.js",
            },
            jsApp: {
                src: [
                      //Controllers and Applications
                      'js/app.js',
                      'js/results-view-table/controller/results-representation.js',
                      'js/results-view-table/controller/modal.js',

                      //Services
                      'js/results-view-table/services/csv-service.js',
                      'js/results-view-table/services/color-service.js',

                      //View Directives
                      'js/results-view-table/directives/protein-sequence-view.js',
                      'js/results-view-table/directives/ambiguity-plot.js',
                      'js/results-view-table/directives/metadata-display.js',

                      //Component Directives
                      'js/results-view-table/directives/fragment-ion.js',
                      'js/results-view-table/directives/resizeable.js',
                      'js/results-view-table/directives/save-results.js',
                      'js/results-view-table/directives/html-popover.js',
                      'js/results-view-table/directives/help-menu.js',

                      //Filters
                      'js/results-view-table/filters/highlight-modifications.js',
                      'js/results-view-table/filters/scientific-notation.js',

                      'js/lib/**.js',

                     ],
                dest: "js/app.concat.js"
            },
            css: {
              src: ["css/vendor/*.css", "css/vendor/biojs/*.css"],
              dest: "css/vendor.css"
            }
        },

        watch: {
            coffee: {
                files: [
                    "**/*.coffee",
                ],
                tasks: ["coffee", "concat:jsApp"]
            },
            less: {
                files: [
                    "css/style.less",
                ],
                tasks: ["less", 'concat:css'],
            },
            templates: {
              files: [
                "templates/*.html"
              ],
              tasks: ["embedTemplates"]
            }
        },
        serve: {
        options: {
            port: 9090
        }
    }
    })
    grunt.registerMultiTask("embedTemplates", "Wraps Angular Templates in <script> tags and embeds them in an HTML document,\
      using the template's path as its id field", function(args){
        var done = this.async()
        embedTemplates(this.data.hostDocumentPath, this.data.templateDirectoryPath, this.data.outfilePath)
        done(true);
    })
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-concat');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-watch');
    grunt.loadNpmTasks('grunt-ng-annotate');
    grunt.loadNpmTasks('grunt-serve');
    grunt.registerTask('default', ['coffee', "less", "concat", "embedTemplates", "watch", "serve"]);
}
