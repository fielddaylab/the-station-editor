const path = require('path');

module.exports = [{
  mode: 'development',
  entry: './editor/js/main.js',
  output: {
    path: path.resolve(__dirname, "editor"),
    filename: 'webpack_out.js',
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader"
        }
      }
    ]
  }
}];
