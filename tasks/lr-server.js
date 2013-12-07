// TODO: more documentation on bg and usage of each task

// Simple Livereload server tasks
// - `lr-start`
// - `lr-reload`
// Based on suggestions from grunt-contrib-watch (https://github.com/gruntjs/grunt-contrib-watch#rolling-your-own-live-reload)
var server = require('tiny-lr')();

module.exports = function(grunt) {
  grunt.registerTask('lr-start', 'Start the tiny livereload server', function() {
    var options = {port:35729};
    server.listen(options.port, this.async());
    grunt.log.writeln('LiveReload server started on port', options.port);
  });

  grunt.registerTask('lr-reload', 'Sends a reload notification to the livereload server', function(argFilepath) {
    var filepath = argFilepath || grunt.config('lr-reload').filepath;
    grunt.log.writeln('LiveReload server notifying '+ filepath +' changed');
    server.changed({body:{files:[filepath]}});
  });
};
