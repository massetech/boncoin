exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js"
    },
    stylesheets: {
      joinTo: "css/app.css",
      order: {
        after: ["css/app.scss"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: [
      "static", "css", "js", "vendor", "scss", "fonts",
      // "node_modules/bootstrap-select/dist/js/bootstrap-select.min.js",
      // "node_modules/bootstrap-select/dist/js/bootstrap-select.bundle.js",
      // "node_modules/bootstrap-select/dist/css/bootstrap-select.min.css"
    ],
    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    sass: {
      mode: 'native',
      options: {
        includePaths: [
          "node_modules/bootstrap/scss",
          "node_modules/font-awesome/scss"
        ], // tell sass-brunch where to look for files to @import
        precision: 8 // minimum precision required by bootstrap
      }
    },
    copycat: {
      "fonts": ["static/fonts", "node_modules/font-awesome/fonts"],
      verbose: false, //shows each file that is copied to the destination directory
      onlyChanged: true //only copy a file if it's modified time has changed (only effective when using brunch watch)
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    globals: { // Bootstrap JavaScript requires both '$', 'jQuery', and Tether in global scope
      $: 'jquery',
      jQuery: 'jquery',
      Tether: 'tether',
      Popper: 'popper.js',
      bootstrap: 'bootstrap' // require Bootstrap JavaScript globally too
    }
  }
};
