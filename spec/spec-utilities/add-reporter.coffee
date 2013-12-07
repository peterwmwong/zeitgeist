# This determines which reporter to use karma (grunt test) or
# html reporter (grunt dev-test and visiting going to debug.html).
# The html reporter is better for development as you can...
# 1) More clearly see which tests are passing/failing and from which suite it
#    belongs to.
# 2) Allows a developer to filter which specs to run
# 3) Auto-reruns specs with LiveReload
document.write(
  if /debug.html$/.test window.location.pathname
    """
    <link href='/base/bower_components/jasmine/lib/jasmine-core/jasmine.css' rel='stylesheet' type='text/css'></link>
    <script src='/base/bower_components/jasmine/lib/jasmine-core/jasmine-html.js'></script>
    <script src='http://#{(location.host || 'localhost').split(':')[0]}:35729/livereload.js?snipver=1'></script>
    <script>
      window.__karma__.start = function(){
        var jasmineEnv = jasmine.getEnv();
        var htmlReporter = new jasmine.HtmlReporter();
        jasmineEnv.addReporter(htmlReporter);

        // Save specFilter installed by karma's
        var origSpecFilter = jasmineEnv.specFilter;

        jasmineEnv.specFilter = function(spec){
          // If karma's `iit()` or `ddescribe()` is use, override jasmine's
          // HtmlReporter filtering
          if (spec.exclusive_ && !!window.location.search) {
            window.location.search = '';
          }
          var result = (origSpecFilter ? origSpecFilter.call(jasmineEnv,spec) : true);
          return result && htmlReporter.specFilter(spec);
        };

        jasmineEnv.execute();
      };
    </script>
    """
  else
    """
    <script src='/base/node_modules/karma-jasmine/lib/adapter.js'></script>
    """
)
