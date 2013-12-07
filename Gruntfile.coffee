elementify = require "./tasks/transforms/elementify"

elementifyTransformCSS = elementify.createTransform inlineCSS: true
elementifyTransform    = elementify.createTransform inlineCSS: false

module.exports = (grunt)->

  BUILD_DIR = "build/"

  grunt.initConfig

    # Metadata
    # ========
    pkg: grunt.file.readJSON "package.json"

    # Compile Tasks
    # =============
    clean:
      build: BUILD_DIR

    browserify:
      options:
        insertGlobals: false
        detectGlobals: false
        debug: true
        shim: SHIMMED_LIBS =
          angular:
            path: "bower_components/angular/angular.js"
            exports: "angular"
          "angular-animate":
            path: "bower_components/angular-animate/angular-animate.js"
            exports: null
            depends:
              angular: "angular"
          "angular-resource":
            path: "bower_components/angular-resource/angular-resource.js"
            exports: null
            depends:
              angular: "angular"
        # Reduce build time by making sure Browserify doesn't unnecesarily trace
        # dependencies in libraries that are not CommonJS or AMD.
        noParse: (path for name,{path} of SHIMMED_LIBS)
        transform: ["coffeeify", elementifyTransformCSS]

      spec:
        src: ["spec/**/*.coffee", "!spec/spec-utilities/**/*.coffee"]
        dest: "build/spec/all.js"

      app:
        src: "app/zeitgeist.coffee"
        dest: "build/app/zeitgeist.js"

      prod:
        src: "app/zeitgeist.coffee"
        dest: "build/app/zeitgeist.prod.js"
        options:
          transform: ["coffeeify", elementifyTransform]
          postBundleCB: (err, src, next)->
            # When running `grunt prod`, the "cssmin:app" task runs afterwards.
            # This code informs the "cssmin:app" task which css files should be
            # concatenated and minified. This method of informing a subsequent
            # task is exactly how the "watch" event listener informs the
            # subsequent compile task ("sass:app" or "slim:app") which file has
            # changed and needs to be built.
            # The list of CSS files is gathered by the elementify transform as
            # it performs each transformation.
            grunt.config.set "cssmin.app.src",
              elementify.allCSSFiles.map (cssFile)->"build/app#{cssFile}"
            next null, src

    sass:
      app:
        expand: true
        cwd: "."
        ext: ".css"
        src: "{app,spec}/**/*.scss"
        dest: BUILD_DIR
        options:
          sourcemap: true
          loadPath: ["app/styles/","vendor/bourbon"]

    slim:
      app:
        expand: true
        cwd: "."
        ext: ".html"
        src: "{app,spec}/**/*.slim"
        dest: BUILD_DIR
        options:
          pretty: true

    copy:
      fonts:
        expand: true
        cwd: "."
        src: "vendor/fonts/**/*"
        dest: "#{BUILD_DIR}/app"


    # Production Build Tasks
    # ======================
    cssmin:
      app:
        # `src` is set by browserify:prod, which traces all dependencies and
        # informs this task the subset of CSS files needed to be packaged.
        dest: "build/app/zeitgeist.min.css"

    ngmin:
      app:
        src: "<%= browserify.prod.dest %>"
        dest: "build/app/zeitgeist.ngmin.js"

    uglify:
      app:
        src: "<%= ngmin.app.dest %>"
        dest: "build/app/zeitgeist.min.js"


    # Watch Tasks
    # ===========
    watch:
      options: {spawn: false}

      jsShims:
        files: "<%= browserify.options.shim.angular.path %>"
        tasks: ["browserify:app", "lr-reload:<%= browserify.app.dest %>"]

      coffee:
        files: ["app/**/*.coffee"]
        tasks: ["browserify:app", "lr-reload:<%= browserify.app.dest %>"]

      coffee_spec:
        files: "spec/**/*.coffee"
        tasks: ["browserify:spec", "lr-reload:<%= browserify.spec.dest %>"]

      sass:
        files: "{app,spec}/**/*.scss"
        tasks: ["sass:app", "lr-reload"]

      slim:
        files: "app/**/*.slim"
        tasks: [
          "slim:app"
          # Allow inlining of templates into element directives
          "browserify:app"
          "lr-reload"
        ]

      slim_spec:
        files: "spec/**/*.slim"
        tasks: [
          "slim:app"
          # Allow inlining of templates into test fixture element directives
          "browserify:spec"
          "lr-reload"
        ]

    # Test Tasks
    # ==========
    karma:
      options:
        configFile: "spec/spec-utilities/karma.conf.coffee"

      # One time test run on major browsers in parallel
      # Eventually CI build
      unit:
        options:
          singleRun: true
          browsers: ['Chrome','Safari','Firefox']

      "unit-ci":
        options:
          singleRun: true
          browsers: ['PhantomJS']
          reporters: ['dots', 'junit']
          junitReporter:
            outputFile: 'test-results.xml'

      # Continous/livereload test run for development
      unit_dev:
        options:
          autoWatch: true
          singleRun: false
          background: true
          browsers: ['Chrome']

    # Dev Tasks
    # ========
    symlink:

      # This enables SASS source maps to be served from the specified paths in
      appForSASSSourceMaps:
        src: "app/"
        dest: "build/app/app/"

    # Server Task
    # ===========
    connect:
      server:
        options:
          hostname: "*"
          port: grunt.option('port') || 8000
          base: "#{BUILD_DIR}/app"


  # Called when the "watch" tasks detects a file change, but BEFORE it runs
  # any build tasks. This allows us to only build the changed file.
  # This is done by adjusting the `src` property on the build task's config
  # to the changed file.
  grunt.event.on 'watch', (action, filepath)->
    # Determine task by the file extension of the changed file
    fileExt = /\.(\w+)$/.exec(filepath)[1]
    taskToModify = {
      "slim": "slim.app"
      "scss": "sass.app"
    }[fileExt]

    if taskToModify
      # Since app/style/**.sass are used globally do a full SASS build
      if /app\/styles\//.test filepath
        filepath = "{app,spec}/**/*.scss"

      # Re-set the task's config with the `src` property overriden
      grunt.config.set taskToModify,
        Object.defineProperty grunt.config.get(taskToModify),
          'src'
          value: [filepath]

      # Configure LiveReload task to notify server a file has changed
      destExt = grunt.config.get "#{taskToModify}.ext"
      grunt.config.set "lr-reload",
        filepath: BUILD_DIR + (filepath.replace /\.(\w+)$/, destExt)

  # Load Custom Tasks
  # =================
  grunt.loadTasks "tasks/"

  # Load Tasks
  # ==========
  grunt.loadNpmTasks npmTask for npmTask in [
    "grunt-browserify"
    "grunt-contrib-clean"
    "grunt-contrib-connect"
    "grunt-contrib-copy"
    "grunt-contrib-cssmin"
    "grunt-contrib-sass"
    "grunt-contrib-symlink"
    "grunt-contrib-uglify"
    "grunt-contrib-watch"
    "grunt-karma"
    "grunt-ngmin"
    "grunt-slim"
  ]

  # CLI Tasks
  # =========
  grunt.registerTask "prod", [
    "default"
    "browserify:prod"
    "cssmin:app"
    "ngmin:app"
    "uglify:app"
  ]

  grunt.registerTask "dev", [
    "default"
    "symlink:appForSASSSourceMaps"
    "lr-start"
    "connect:server"
    "karma:unit_dev"
    "watch"
  ]
  grunt.registerTask "test", [
    "default"
    "karma:unit"
  ]
  grunt.registerTask "test-ci", [
    "default"
    "karma:unit-ci"
  ]
  grunt.registerTask "default", [
    "clean"
    "copy"
    "sass:app"
    "slim:app"
    "browserify:spec"
    "browserify:app"
  ]
