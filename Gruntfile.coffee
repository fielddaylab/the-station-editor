module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'js/all.js'       : ['js/*.coffee']
          'editor/js/all.js': ['editor/js/*.coffee']
          'common/js/all.js': ['common/js/*.coffee']
          'about/js/all.js' : ['about/js/*.coffee']
          'client/js/all.js': ['client/js/*.coffee']
    sass:
      compile:
        files:
          'client/css/main.css'   : ['client/css/main.sass']
          'client/css/mobile.css' : ['client/css/mobile.sass']
          'client/css/desktop.css': ['client/css/desktop.sass']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.registerTask 'default', ['coffee', 'sass']
