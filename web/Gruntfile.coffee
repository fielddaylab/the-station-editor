module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        files:
          'client-react/js/coffee_out.js': ['client-react/js/*.coffee']
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
          'client-react/js/browserify_out.js': ['client-react/js/coffee_out.js']
          'editor-react/js/browserify_out.js': ['editor-react/js/coffee_out.js']
          'discover/browserify_out.js'       : ['discover/coffee_out.js'       ]
    "closure-compiler":
      client:
        js: 'client-react/js/browserify_out.js'
        jsOutputFile: 'client-react/js/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        options:
          language_in: 'ECMASCRIPT5'
      editor:
        js: 'editor-react/js/browserify_out.js'
        jsOutputFile: 'editor-react/js/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        options:
          language_in: 'ECMASCRIPT5'
      discover:
        js: 'discover/browserify_out.js'
        jsOutputFile: 'discover/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        options:
          language_in: 'ECMASCRIPT5'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-closure-compiler'
  grunt.registerTask 'default', ['coffee', 'browserify', 'closure-compiler']
