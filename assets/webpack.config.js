// var ExtractTextPlugin = require("extract-text-webpack-plugin");
var MiniCssExtractPlugin = require('mini-css-extract-plugin');
var merge = require("webpack-merge");
var webpack = require("webpack");

// var env = process.env.NODE_ENV || "development";
var production = process.env.NODE_ENV == 'production'

var node_modules_dir = "node_modules"

var plugins = [
  // new ExtractTextPlugin("css/app.css"),
  new MiniCssExtractPlugin({filename: "css/app.css"}),
  new webpack.ProvidePlugin({
    $: "jquery",  jQuery: "jquery", "window.jQuery": "jquery",
    Alert: 'exports-loader?Alert!bootstrap/js/dist/alert',
    Button: 'exports-loader?Button!bootstrap/js/dist/button',
    Carousel: 'exports-loader?Carousel!bootstrap/js/dist/carousel',
    Collapse: 'exports-loader?Collapse!bootstrap/js/dist/collapse',
    Dropdown: 'exports-loader?Dropdown!bootstrap/js/dist/dropdown',
    Modal: 'exports-loader?Modal!bootstrap/js/dist/modal',
    Popover: 'exports-loader?Popover!bootstrap/js/dist/popover',
    Scrollspy: 'exports-loader?Scrollspy!bootstrap/js/dist/scrollspy',
    Tab: 'exports-loader?Tab!bootstrap/js/dist/tab',
    Tooltip: "exports-loader?Tooltip!bootstrap/js/dist/tooltip",
    Util: 'exports-loader?Util!bootstrap/js/dist/util'
  })
  // new webpack.ProvidePlugin({Tether: 'tether', Popper: 'popper.js'})
]

if (production == true) {
  // plugins.push(
  //   new webpack.optimize.UglifyJsPlugin({
  //     compress: {warnings: false},
  //     output: {comments: false}
  //   })
  // );
} else {
  plugins.push(
    new webpack.EvalSourceMapDevToolPlugin()
  );
}

var common = {
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [node_modules_dir],
        loader: "babel-loader",
        options: {
          presets: ["es2015"]
        }
      },
      {
        test: /\.css$/, use: ['style-loader', 'css-loader', 'postcss-loader']
      },
      {
        test: /\.scss$/,
          use: [
            MiniCssExtractPlugin.loader,
            {loader: 'css-loader'},
            {loader: 'postcss-loader', options: {
                plugins() {
                  return [
                    require("precss"),
                    require("autoprefixer")
                  ];
                }
              }
            },
            {loader: 'sass-loader'}
          ]
      },
      {
        test: /\.(png|jpg|gif)$/,
        loader: "file-loader?name=/images/[name].[ext]"
      },
      {
        test: /\.(ttf|otf|eot|svg|woff2?)$/,
        loader: "file-loader?name=/fonts/[name].[ext]"
      }
    ]
  },
  plugins: plugins,
  optimization: {minimize: true}
};

module.exports = [
  merge(common, {
    entry: [
      __dirname + "/css/app.scss",
      __dirname + "/js/app.js"
    ],
    output: {
      path: __dirname + "/../priv/static",
      filename: "js/app.js"
    },
    resolve: {
      modules: [
        node_modules_dir,
        __dirname + "./"
      ]
    }
  })
];
