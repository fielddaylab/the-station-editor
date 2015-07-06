module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'js/coffee_out.js'       : ['js/*.coffee']
          'editor/js/coffee_out.js': ['editor/js/*.coffee']
          'common/js/coffee_out.js': ['common/js/*.coffee']
          'about/js/coffee_out.js' : ['about/js/*.coffee']
          'client/js/coffee_out.js': ['client/js/*.coffee']
    sass:
      compile:
        files:
          'client/css/main.css'   : ['client/css/main.sass']
          'client/css/mobile.css' : ['client/css/mobile.sass']
          'client/css/desktop.css': ['client/css/desktop.sass']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.registerTask 'default', ['coffee', 'sass']
