(import 'talkyard/talkyard.libsonnet')

{
  // local configMap = $.core.v1.configMap,
  //   app+: {
  //     playFrameworkConfigMap: configMap.new('app-play-framework-conf')
  //                             + configMap.withData({
  //                               'app-prod-override.conf': importstr 'play-framework.conf',
  //                             }),
  // },
  _config+:: {
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
}
