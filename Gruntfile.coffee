module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'js/all.js': ['js/*.coffee']
          'editor/js/all.js': ['editor/js/*.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.registerTask 'default', ['coffee']
