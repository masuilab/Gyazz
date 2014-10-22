'use strict'

module.exports = (grunt) ->

  (require 'jit-grunt') grunt,
    simplemocha: 'grunt-simple-mocha'

  require 'coffee-errors'

  grunt.loadNpmTasks 'grunt-notify'

  grunt.registerTask 'test', [
    'coffeelint'
    'simplemocha'
    'jsonlint'
    'csslint'
  ]
  grunt.registerTask 'default', [ 'test', 'build', 'watch' ]
  grunt.registerTask 'build',   [ 'coffee' ]

  grunt.initConfig

    csslint:
      strict:
        src: [
          '**/gyazz.css'
          '!node_modules/**'
        ]

    jsonlint:
      config:
        src: [
          '**/*.json'
          '!node_modules/**'
          '!tmp/**'
        ]

    coffeelint:
      options:
        max_line_length:
          value: 119
        indentation:
          value: 2
        newlines_after_classes:
          level: 'error'
        no_empty_param_list:
          level: 'error'
        no_unnecessary_fat_arrows:
          level: 'ignore'
      dist:
        files:
          src: [
            '**/*.coffee'
            '!node_modules/**'
            '!tmp/**'
          ]

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'spec'
        compilers: 'coffee:coffee-script'
        ignoreLeaks: no
      dist:
        src: [ 'tests/test_*.coffee' ]

    coffee:
      compile:
        files: [{
          expand: yes
          cwd: 'public/javascripts/'
          src: [ '**/*.coffee' ]
          dest: 'public/javascripts/'
          ext: '.js'
        }]
        options: {
          sourceMap: yes
        }

    watch:
      options:
        interrupt: yes
      dist:
        files: [
          '**/*.{coffee,js,jade,json,css}'
          '!node_modules/**'
          '!tmp/**'
          '!public/**/*.js'
        ]
        tasks: [ 'test', 'build' ]
