{
  // +:: is important (we don't want to override the
  // _config object, just add to it)
  _config+:: {
    // define a namespace for this library
    talkyard: {
      name: 'talkyard',
      commonLabels: {
        'app.kubernetes.io/part-of': 'talkyard',
        'app.kubernetes.io/version': $._version.talkyard.version,
      },
      app: {
        name: 'app',
        labels: {
          'app.kubernetes.io/component': 'application',
        },
        env: {
          PLAY_HEAP_MEMORY_MB: '256',
        },
      },
      rdb: {
        port: 9090,
        name: 'rdb',
        labels: {
          'app.kubernetes.io/component': 'database',
        },
      },
      cache: {
        name: 'cache',
        labels: {
          'app.kubernetes.io/component': 'cache',
        },
        port: 9090,
      },
      search: {
        name: 'search',
        labels: {
          'app.kubernetes.io/component': 'search',
        },
        port: 9090,
        env: {
          ES_JAVA_OPTS: '-Xms192m -Xmx192m',
          'bootstrap.memory_lock': 'true',
        },
      },
      web: {
        name: 'web',
        labels: {
          'app.kubernetes.io/component': 'webserver',
        },
        port: 9090,
      },
    },
  },
  _version+:: {
    talkyard: {
      version: 'v0.2021.01-923ae76d3',
    },
  },
  _images+:: {
    talkyard: {
      app: 'debiki/talkyard-app',
      rdb: 'debiki/talkyard-rdb',
      cache: 'debiki/talkyard-cache',
      search: 'debiki/talkyard-search',
      web: 'debiki/talkyard-web',
    },
  },
}
