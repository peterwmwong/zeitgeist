###
elementify transform
====================

A browserify transform for creating element directives by generating the
necessary boilerplate:
1. Generates angular directive declaration
2. Injects the template
3. Generates the code to include CSS

For example:

```coffeescript
# app/elements/app.coffee

elementify
  controller: ($scope)->
```

```slim
/ app/elements/app.slim

.msg app's template
```

becomes...

```javascript
// build/app/elements/app.js

angular.module("zeitgeist").directive(function(){
  return {
    controller: function($scope){},
    restrict: "E",
    template: "<div class='msg'>app's template</div>"
  }
})
document.head.appendChild(angular.element("<link href='elements/app.css' rel='stylesheet' type='text/css'>")[0])
```
###

path    = require 'path'
fs      = require 'fs'
through = require 'through'
falafel = require 'falafel'

APP_PATH = path.resolve process.cwd(), "app"

module.exports =

  # Public: Creates a browserify transform function for creating element
  #         directives.
  #
  # options - Hash to configure the transform function.
  #           :inlineCSS - generate code to inlining CSS
  #
  # Examples
  #
  #     elementify = require "elementify"
  #     elementify.createTransform inlineCSS: true
  #     // => function (transform function that generates inline CSS)
  #
  createTransform: (options={})->
    # Default options
    options.inlineCSS ?= false

    (file)->
      return through() unless /\/elements\/.*\.(coffee|js)$/.test file

      data = ''
      write = (buf)-> data += buf
      end = ->
        found = false
        try
          @queue String falafel data, (node)->
            # `element()` calls should only occur once per element directive
            # Save some CPU cycles by not analyzing the nodes after one is found
            if (not found) and (isElementCall node)
              found = true

              # Get element directive name from the filename
              elName = camelCase path.basename(file).split('.')[0]

              # Get the path without the file extension
              buildElPath = path.relative APP_PATH, file.replace(/\.(coffee|js)$/,'')

              # Get the template from the project build directory
              templatePath = "build/app/#{buildElPath}.html"
              template =
                if fs.existsSync templatePath
                  fs.readFileSync(templatePath).toString()

              # Create an absolute URL path to the CSS from the project build
              # directory
              cssPath = "/#{buildElPath}.css"

              # Keep track of CSS files of all transformed element directives
              # ... If we're not going to inline the CSS during runtime.
              if options.inlineCSS
                module.exports.allCSSFiles.push(cssPath)

              # Surrounds the element directive options hash with...
              # 1. the angular directive declaration
              # 2. inlined template
              # 3. optionally, code'to inline CSS
              node.update """
                angular.module("zeitgeist").directive('#{elName}',function(){return #{
                    node.arguments[0].source().slice(0,-1)
                  },
                  restrict: "E"#{
                    if template then ", template:#{JSON.stringify(template)}"
                    else ""
                  }
                }});
              """ +
                # In the karma test environment, base path to assets is `/base`.
                # ex. `/build/app/elements/app.css` -> `/base/build/app/elements/app.css`
                if options.inlineCSS then """
                  document.head.appendChild(
                    angular.element(
                      "<link href='"+(window.__karma__?"/base/build/app":"")+"#{cssPath}' rel='stylesheet' type='text/css'>"
                    )[0]
                  )
                """
                else ""
          @queue null

        catch ex
          @emit 'error', ex
          @queue data
          @queue null
        return

      through write, end

  allCSSFiles: []

# Private: Determines whether JS AST Node is the `element()` function call.
#
# node    - Esprima JS AST Node
#
# Examples
#
#    // node is the JS AST Node for "element({})"
#    isElementCall(node)
#    // => true
#
isElementCall = (node)->
  if c = node.callee
    node.type is 'CallExpression' and
      c.type is 'Identifier' and
        c.name is 'elementify'

# Private: Converts snake to camel case
#
# string  - snake name
#
# Examples
#
#    isElementCall("test-element")
#    // => "testElement"
#
camelCase = (string)->
  string.replace /(\-[a-z])/g, (s)->s.slice(1).toUpperCase()
