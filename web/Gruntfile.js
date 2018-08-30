module.exports = function(grunt) {
  grunt.initConfig({
    browserify: {
      compile: {
        files: {
          'editor-react/js/browserify_out.js': ['editor-react/js/main.js'],
          'discover/browserify_out.js': ['discover/main.js']
        }
      }
    },
    sass: {
      dist: {
        files: {
          "editor-react/style.css": "editor-react/scss/main.scss"
        }
      }
    }
  });
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-sass');
  grunt.registerTask('default', ['browserify', 'sass']);
};
