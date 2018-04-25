module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'editor-react/js/coffee_out.js': ['editor-react/js/*.coffee']
          'discover/coffee_out.js'       : ['discover/*.coffee']
      glob_shared:
        expand: true
        flatten: true
        cwd: 'shared/'
        src: ['*.coffee']
        dest: 'shared/'
        ext: '.js'
    browserify:
      compile:
        files:
          'editor-react/js/browserify_out.js': ['editor-react/js/coffee_out.js']
          'discover/browserify_out.js'       : ['discover/coffee_out.js'       ]
    ###
    "closure-compiler":
      editor:
        js: 'editor-react/js/browserify_out.js'
        jsOutputFile: 'editor-react/js/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        maxBuffer: 99999999
        options:
          language_in: 'ECMASCRIPT5'
      discover:
        js: 'discover/browserify_out.js'
        jsOutputFile: 'discover/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        maxBuffer: 99999999
        options:
          language_in: 'ECMASCRIPT5'
    ###
    sass:
      dist:
        files:
          "editor-react/style.css": "editor-react/scss/main.scss"

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  # grunt.loadNpmTasks 'grunt-closure-compiler'
  grunt.loadNpmTasks 'grunt-sass'
  grunt.registerTask 'default', [
    'coffee'
    'browserify'
    # 'closure-compiler'
    'sass'
  ]
