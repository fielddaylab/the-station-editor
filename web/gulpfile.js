var gulp = require('gulp');
var sass = require('gulp-sass');
var webpackStream = require('webpack-stream');
var webpack = require('webpack');

gulp.task('webpack-editor', [], function() {
  return gulp.src('editor-react/js/main.js')
    .pipe(webpackStream({
      output: {filename: 'webpack_out.js'},
      plugins: [
        new webpack.DefinePlugin({
          'process.env': {NODE_ENV: "'production'"}
        }),
        new webpack.optimize.UglifyJsPlugin(),
      ],
      module: {
        loaders: [
          {
            test: /.jsx?$/,
            loader: 'babel-loader',
            exclude: /node_modules/,
            query: {
              presets: ['@babel/preset-env', '@babel/preset-react']
            }
          }
        ]
      },
    }, webpack))
    .pipe(gulp.dest('editor-react/'));
});

gulp.task('webpack-discover', [], function() {
  return gulp.src('discover/js/main.js')
    .pipe(webpackStream({
      output: {filename: 'webpack_out.js'},
      plugins: [
        new webpack.DefinePlugin({
          'process.env': {NODE_ENV: "'production'"}
        }),
        new webpack.optimize.UglifyJsPlugin(),
      ],
      module: {
        loaders: [
          {
            test: /.jsx?$/,
            loader: 'babel-loader',
            exclude: /node_modules/,
            query: {
              presets: ['@babel/preset-env', '@babel/preset-react']
            }
          }
        ]
      },
    }, webpack))
    .pipe(gulp.dest('discover/'));
});

gulp.task('scss-editor', function () {
  return gulp.src('editor-react/scss/main.scss')
    .pipe(sass())
    .pipe(gulp.dest('editor-react/')); // TODO filename
});

gulp.task('default', ['webpack-editor', 'webpack-discover', 'scss-editor']);
