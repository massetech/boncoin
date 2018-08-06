const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const webpack = require('webpack');

module.exports = (env, options) => ({
  // optimization: {
  //   minimizer: [
  //     new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
  //     new OptimizeCSSAssetsPlugin({})
  //   ]
  // },
  entry: './js/app.js',
  output: {
    path: path.resolve(__dirname, '../priv/static/js'),
    filename: 'app.js'
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
      {
        test: /\.(css|scss)$/,
        use: [
          {
            // Adds CSS to the DOM by injecting a `<style>` tag
            loader: process.env.NODE_ENV !== 'production' ? 'style-loader' : MiniCssExtractPlugin.loader
          },
          {
            // Interprets `@import` and `url()` like `import/require()` and will resolve them
            loader: 'css-loader'
          },
          {
            // Loads a SASS/SCSS file and compiles it to CSS
            loader: 'sass-loader'
          }
        ]
      }
    ],
  },
  resolve: {
    modules: ['node_modules', path.resolve(__dirname, 'js')],
    extensions: ['.js'],
  },
  plugins: [
    new MiniCssExtractPlugin({filename: "[name].css",chunkFilename: "[id].css"}),
    // new CopyWebpackPlugin([{from:'src/images',to:'images'}])
    new webpack.ProvidePlugin({$: "jquery",  jQuery: "jquery", Tether: 'tether', Popper: 'popper.js'})
  ]
});
