module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'js/coffee_out.js'        : ['js/*.coffee']
          'editor/js/coffee_out.js' : ['editor/js/*.coffee']
          'common/js/coffee_out.js' : ['common/js/*.coffee']
          'about/js/coffee_out.js'  : ['about/js/*.coffee']
          'client3/js/coffee_out.js': ['client3/js/*.coffee']
    sass:
      compile:
        files:
          'client3/css/main.css'   : ['client3/css/main.sass']
          'client3/css/mobile.css' : ['client3/css/mobile.sass']
          'client3/css/desktop.css': ['client3/css/desktop.sass']
    less:
      compile:
        files:
          'client2/css/sifter-desktop.css': ['client2/css/sifter-desktop.less']
          'client2/css/sifter-mobile.css' : ['client2/css/sifter-mobile.less']
    cjsx:
      compile:
        files:
          'client-react/js/coffee_out.js': ['client-react/js/*.cjsx']

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-sass'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-coffee-react'
  grunt.registerTask 'default', ['coffee', 'sass', 'less', 'cjsx']
