module.exports = (config)->
  config.set
    autoWatch: true
    basePath: "../../"
    files: [
      "node_modules/karma-jasmine/lib/jasmine.js"

      # This determines which reporter to use karma (grunt test) or
      # html reporter (grunt dev-test and visiting going to debug.html).
      "spec/spec-utilities/add-reporter.coffee"

      "build/app/zeitgeist.js"
      "bower_components/angular-mocks/angular-mocks.js"

      "build/spec/all.js"

      {pattern: "node_modules/karma-jasmine/lib/adapter.js", included: false}
      {pattern: "bower_components/jasmine/**/*", included: false}

      # Expose build and source files for easier debugging with linked source maps.
      {pattern: "build/**/*", included: false}
      {pattern: "app/**/*", included: false}
      {pattern: "spec/**/*", included: false}
      {pattern: "vendor/**/*", included: false}
    ]

    preprocessors:
      'spec/**/*.coffee': ['coffee']
