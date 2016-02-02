module.exports = (grunt) ->
  grunt.initConfig
    cjsx:
      compile:
        files:
          'client-react/js/coffee_out.js': ['client-react/js/*.cjsx']
          'editor-react/js/coffee_out.js': ['editor-react/js/*.cjsx']
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
        options: {}
      editor:
        js: 'editor-react/js/browserify_out.js'
        jsOutputFile: 'editor-react/js/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        options: {}
      discover:
        js: 'discover/browserify_out.js'
        jsOutputFile: 'discover/minify_out.js'
        closurePath: '/usr/local/opt/closure-compiler/libexec'
        options: {}

  grunt.loadNpmTasks 'grunt-coffee-react'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-closure-compiler'
  grunt.registerTask 'default', ['cjsx', 'browserify', 'closure-compiler']
