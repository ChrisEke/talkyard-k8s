(import 'talkyard/talkyard.libsonnet')

{
  app+: {
    // Includes play-framework.conf as a ConfigMap which Talkyard-app will mount as a config volume.
    playFrameworkConfigMap: $.core.v1.configMap.new('app-play-framework-conf')
                            + $.core.v1.configMap.withData({
                              'app-prod-override.conf': importstr 'play-framework.conf',
                            }),
  },
  _config+:: {
    namespace: 'my-namespace',
    app+:: {
      // Settings for Java heap size as well as many of the parameters in play-framework-conf
      // can be specified as environment variables
      env+:: {
        PLAY_HEAP_MEMORY_MB: '256',
        BECOME_OWNER_EMAIL_ADDRESS: 'example@example.com',
        TALKYARD_HOSTNAME: 'example.com',
      },
    },
    search+:: {
      env+:: {
        ES_JAVA_OPTS: '-Xms192m -Xmx192m',
      },
    },
  },
}
