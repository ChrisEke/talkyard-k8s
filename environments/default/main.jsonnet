(import 'talkyard/talkyard.libsonnet')

{
  _config+:: {
    app+:: {
      env+:: {
        PLAY_HEAP_MEMORY_MB: '256',
      },
    },
    search+:: {
      env+:: {
        ES_JAVA_OPTS: '-Xms192m -Xmx192m',
      },
    },
  },
}
