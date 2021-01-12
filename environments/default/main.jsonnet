(import 'ksonnet-util/kausal.libsonnet') +
(import 'talkyard/talkyard.libsonnet')

{
  _config+:: {
    talkyard+:: {
      app+:: {
        env+:: {
          PLAY_HEAP_MEMORY_MB: '256',
        },
      },
      search+:: {
        env+:: {
          ES_JAVA_OPTS: '-Xms192m -Xmx192m',
          'bootstrap.memory_lock': 'true',
        },
      },
    },
  },
}
