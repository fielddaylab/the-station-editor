const path = require('path');

module.exports = [{
  mode: 'development',
  entry: './editor-react/js/main.js',
  output: {
    path: path.resolve(__dirname, "editor-react"),
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
}, {
  mode: 'development',
  entry: './discover/js/main.js',
  output: {
    path: path.resolve(__dirname, "discover"),
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
