{
  _config+:: {
    name: 'talkyard',
    namespace: self.name,
    app: {
      name: 'app',
      labels: {
        'app.kubernetes.io/component': 'application',
      },
      ports: [
        { name: 'http', port: 9000 },
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
      env: {},
    },
    web: {
      name: 'web',
      labels: {
        'app.kubernetes.io/component': 'webserver',
      },
      ports: [
        { name: 'http', port: 80 },
      ],
    },
  },
  _images+:: {
      app: 'debiki/talkyard-app',
      rdb: 'debiki/talkyard-rdb',
      cache: 'debiki/talkyard-cache',
      search: 'debiki/talkyard-search',
      web: 'debiki/talkyard-web',
    },
}
