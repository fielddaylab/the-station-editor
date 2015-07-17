module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'www/js/coffee_out.js'        : ['www/js/*.coffee']
          'www/editor/js/coffee_out.js' : ['www/editor/js/*.coffee']
          'www/common/js/coffee_out.js' : ['www/common/js/*.coffee']
          'www/about/js/coffee_out.js'  : ['www/about/js/*.coffee']
          'www/client3/js/coffee_out.js': ['www/client3/js/*.coffee']
    sass:
      compile:
        files:
          'www/client3/css/main.css'   : ['www/client3/css/main.sass']
          'www/client3/css/mobile.css' : ['www/client3/css/mobile.sass']
          'www/client3/css/desktop.css': ['www/client3/css/desktop.sass']
    less:
      compile:
        files:
          'www/client2/css/sifter-desktop.css': ['www/client2/css/sifter-desktop.less']
          'www/client2/css/sifter-mobile.css' : ['www/client2/css/sifter-mobile.less']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.registerTask 'default', ['coffee', 'sass', 'less']
