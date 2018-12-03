const webpack = require('webpack');
const path = require('path');
const dev = process.env.NODE_ENV === "dev"
// const VENDOR_LIBS = ['jquery', 'popper.js', 'webpack-jquery-ui', 'nestedSortable']
// const glob = require('glob');

const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

let cssLoaders = [
  MiniCssExtractPlugin.loader, // Necessary to get one full app.css
  { loader: 'css-loader', options: {sourceMap: true, importLoaders: 3} },
  { loader: 'postcss-loader',
    options: {
      plugins: (loader) => [require('autoprefixer')]
    }
  },
  { loader: 'sass-loader' },
  { loader: 'sass-resources-loader',
    options: {
      sourceMap: true,
      // resources: [@css 'variables.scss')]
      resources: [path.resolve('./css/variables.scss')]
    }
  }
]

let config = {
  entry: {
    app: ['./js/app.js'],
  },
  output: dev ? {
      // IDK why `public` - it's the only path that works
      path: path.resolve(__dirname, 'public'),
      filename: 'js/app.js',
      publicPath: 'http://localhost:8080/',
    }
    : {
      path: path.resolve(__dirname, '../priv/static'),
      filename: 'js/app.js',
  },
  resolve: {
    // alias: {
    //   '@css': path.resolve('./css/')
    // }
  },
  devtool: dev ? "cheap-module-eval-source-map" : false, // Analyse code line in developper tool
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: 'babel-loader',
      },
      {
        test: /\.(css|sass|scss)$/,
        use: cssLoaders,
      },
      {
        test: /\.(png|jpg|jpeg|gif|svg|ico)$/,
        use: [
          { loader: 'url-loader',
            options: {
              limit: 1, // inline img looks to fail with Phoenix preprocessing
              fallback: 'file-loader?&name=images/[name].[ext]'
            }
          }
        ]
      },
      {
        test: /\.(ttf|otf|eot|svg|woff2?)$/,
        // loader: 'file-loader?&name=dede/boris/[name].[ext]'
        loader: 'file-loader',
        options: {
          name: 'css/fonts/[name].[ext]',
        }
      },
    ],
  },
  plugins: [
    new MiniCssExtractPlugin({filename: './css/app.css'}),
    new webpack.ProvidePlugin({$: 'jquery', jQuery: 'jquery', Popper: ['popper.js', 'default']}),
    new CopyWebpackPlugin([{ from: 'static/', to: './' }]),
  ],
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  devServer: {
    watchOptions: {ignored: /node_modules/},
    headers: {'Access-Control-Allow-Origin': '*'}, // CORS header is also required for HMR to work
  },
};

if (!dev) {
  config.plugins.push(new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: true }))
  config.plugins.push(new CleanWebpackPlugin(path.resolve(__dirname, '../priv/static/*'), {dry: false, verbose: true, allowExternal: true}))
}

module.exports = config
