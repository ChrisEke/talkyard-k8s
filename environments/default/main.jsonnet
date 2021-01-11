(import 'ksonnet-util/kausal.libsonnet')
+ (import 'talkyard/talkyard.libsonnet')
+ (import 'talkyard_version.jsonnet')

  {
  _config+:: {
    talkyard+:: {
      app+:: {
        env+:: {
          PLAY_HEAP_MEMORY_MB: '256',
        },
      },
    },
  },
}
