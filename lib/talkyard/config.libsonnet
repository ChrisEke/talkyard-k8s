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
        ports: [
          { name: 'http', port: 7000 },
          { name: 'https', port: 9000 },
        ],
        env: {},
      },
      rdb: {
        name: 'rdb',
        labels: {
          'app.kubernetes.io/component': 'database',
        },
        ports: [
          { name: 'default', port: 5432 },
        ],
      },
      cache: {
        name: 'cache',
        labels: {
          'app.kubernetes.io/component': 'cache',
        },
        ports: [
          { name: 'default', port: 6379 },
        ],
      },
      search: {
        name: 'search',
        labels: {
          'app.kubernetes.io/component': 'search',
        },
        ports: [
          { name: 'default', port: 9300 },
        ],
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
        ports: [
          { name: 'http', port: 80 },
          { name: 'https', port: 443 },
        ],
      },
    },
  },
  _version+:: {
    talkyard: {
      version: 'latest',
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
