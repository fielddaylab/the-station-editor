module.exports = (grunt) ->
  grunt.initConfig
    cjsx:
      compile:
        files:
          'js/coffee_out.js'             : ['js/*.coffee']
          'editor/js/coffee_out.js'      : ['editor/js/*.coffee']
          'common/js/coffee_out.js'      : ['common/js/*.coffee']
          'about/js/coffee_out.js'       : ['about/js/*.coffee']
          'client3/js/coffee_out.js'     : ['client3/js/*.coffee']
          'client-react/js/coffee_out.js': ['client-react/js/*.cjsx']
          'editor-react/js/coffee_out.js': ['editor-react/js/*.cjsx']
      glob_to_multiple:
        expand: true
        flatten: true
        cwd: 'shared/'
        src: ['*.coffee']
        dest: 'shared/'
        ext: '.js'
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
    browserify:
      compile:
        files:
          'client-react/js/browserify_out.js': ['client-react/js/coffee_out.js']
          'editor-react/js/browserify_out.js': ['editor-react/js/coffee_out.js']

  grunt.loadNpmTasks 'grunt-coffee-react'
  grunt.loadNpmTasks 'grunt-sass'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.registerTask 'default', ['cjsx', 'sass', 'less', 'browserify']
