module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'editor/js/all.js': ['editor/js/*.coffee']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.registerTask 'default', ['coffee']
