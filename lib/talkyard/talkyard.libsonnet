(import 'ksonnet-util/kausal.libsonnet') +
(import './config.libsonnet') +
{
  local deployment = $.apps.v1.deployment,
  local statefulSet = $.apps.v1.statefulSet,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,
  local configMap = $.core.v1.configMap,
  local volumeMount = $.core.v1.volumeMount,
  local persistentVolumeClaim = $.core.v1.persistentVolumeClaim,

  local c = $._config.talkyard,
  talkyard: {
    app: {
      deployment: deployment.new(
                    name=c.app.name,
                    replicas=1,
                    containers=[
                      container.new(c.app.name, $._images.talkyard.app + ':' + $._version.talkyard.version)
                      + container.withPorts([port.new('http', 9000)])
                      + container.withEnv([
                        container.envType.fromSecretRef('POSTGRES_PASSWORD', 'talkyard-rdb-secret', 'postgres-password'),
                        container.envType.fromSecretRef('PLAY_SECRET_KEY', 'talkyard-app-secret', 'play-secret-key'),
                      ])
                      + container.withEnvMap(c.app.env)
                      + container.mixin.readinessProbe.httpGet.withPath('/-/are-scripts-ready')
                      + container.mixin.readinessProbe.httpGet.withPort('http')
                      + container.mixin.readinessProbe.withInitialDelaySeconds(10)
                      + container.mixin.livenessProbe.tcpSocket.withPort('http')
                      + container.mixin.livenessProbe.withInitialDelaySeconds(30)
                      + container.mixin.livenessProbe.withPeriodSeconds(15)
                      + container.mixin.livenessProbe.withTimeoutSeconds(5),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.app.labels)
                  + $.util.configMapVolumeMount(self.playFrameworkConf, '/opt/talkyard/app/conf/app-prod-override.conf', volumeMount.withSubPath('app-prod-override.conf')),
      service: $.util.serviceFor(self.deployment),
      playFrameworkConf: configMap.new(c.app.name + '-play-framework-conf')
                         + configMap.withData({
                           'app-prod-override.conf': importstr 'files/play-framework.conf',
                         }),
    },
    rdb: {
      statefulSet: statefulSet.new(
                     name=c.rdb.name,
                     replicas=1,
                     volumeClaims=[
                       persistentVolumeClaim.new(),
                     ],
                     containers=[
                       container.new(c.rdb.name, $._images.talkyard.rdb + ':' + $._version.talkyard.version)
                       + container.withPorts([port.new(c.rdb.ports.default.name, c.rdb.ports.default.port)])
                       + container.withEnv([
                         container.envType.fromSecretRef('POSTGRES_PASSWORD', 'talkyard-rdb-secret', 'postgres-password'),
                       ])
                       + container.mixin.readinessProbe.exec.withCommand(
                         ['/bin/sh', '-c', 'exec pg_isready -U "talkyard" -h 127.0.0.1 -p 5432']
                       )
                       + container.mixin.readinessProbe.withInitialDelaySeconds(10)
                       + container.mixin.readinessProbe.withTimeoutSeconds(6)
                       + container.mixin.readinessProbe.withPeriodSeconds(30)
                       + container.mixin.livenessProbe.exec.withCommand(
                         ['/bin/sh', '-c', 'exec pg_isready -U "talkyard" -h 127.0.0.1 -p 5432']
                       )
                       + container.mixin.livenessProbe.withInitialDelaySeconds(30)
                       + container.mixin.livenessProbe.withPeriodSeconds(30)
                       + container.mixin.livenessProbe.withTimeoutSeconds(6),
                     ],
                   )
                   + statefulSet.mixin.metadata.withLabels(c.commonLabels + c.rdb.labels)
                   + statefulSet.mixin.spec.withServiceName(c.rdb.name)
                   + $.util.configMapVolumeMount(self.initShOverride, '/docker-entrypoint-initdb.d'),
      service: $.util.serviceFor(self.statefulSet),
      initShOverride: configMap.new(c.rdb.name + '-init-sh-override')
                      + configMap.withData({
                        'init.sh': importstr 'files/init.sh',
                      }),
    },
    cache: {
      deployment: deployment.new(
                    name=c.cache.name,
                    replicas=1,
                    containers=[
                      container.new(c.cache.name, $._images.talkyard.cache + ':' + $._version.talkyard.version)
                      + container.withPorts([port.new(c.cache.ports.default.name, c.cache.ports.default.port)])
                      + container.mixin.readinessProbe.exec.withCommand(['redis-cli', 'ping'],)
                      + container.mixin.readinessProbe.withInitialDelaySeconds(20)
                      + container.mixin.readinessProbe.withTimeoutSeconds(5)
                      + container.mixin.readinessProbe.withPeriodSeconds(3)
                      + container.mixin.livenessProbe.tcpSocket.withPort('cache')
                      + container.mixin.livenessProbe.withInitialDelaySeconds(20)
                      + container.mixin.livenessProbe.withPeriodSeconds(3)
                      + container.mixin.livenessProbe.withTimeoutSeconds(5),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.cache.labels),
      service: $.util.serviceFor(self.deployment),

    },
    search: {
      deployment: deployment.new(
                    name=c.search.name,
                    replicas=1,
                    containers=[
                      container.new(c.search.name, $._images.talkyard.search + ':' + $._version.talkyard.version)
                      + container.withPorts([port.new(c.search.ports.default.name, c.search.ports.default.port)])
                      + container.withEnvMap(c.search.env)
                      + container.mixin.readinessProbe.exec.withCommand(['/bin/sh', '-c', importstr 'files/elastisearch-readiness.sh'],)
                      + container.mixin.readinessProbe.withInitialDelaySeconds(30)
                      + container.mixin.readinessProbe.withTimeoutSeconds(5)
                      + container.mixin.readinessProbe.withPeriodSeconds(10)
                      + container.mixin.readinessProbe.withSuccessThreshold(3),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.search.labels)

                  + $.util.configMapVolumeMount(
                    self.log4j2PropertiesOverride,
                    '/usr/share/elasticsearch/config/log4j2.properties',
                    volumeMount.withSubPath('log4j2.properties')
                  ),
      service: $.util.serviceFor(self.deployment),
      log4j2PropertiesOverride: configMap.new(c.search.name + '-log4j2-properties-override')
                                + configMap.withData({
                                  'log4j2.properties': importstr 'files/log4j2.properties',
                                }),
    },
    web: {
      deployment: deployment.new(
                    name=c.web.name,
                    replicas=1,
                    containers=[
                      container.new(c.web.name, $._images.talkyard.web + ':' + $._version.talkyard.version)
                      + container.withPorts(
                        [
                          port.new(c.web.ports.http.name, c.web.ports.http.port),
                          port.new(c.web.ports.https.name, c.web.ports.https.port),
                        ]
                      )
                      + container.mixin.readinessProbe.httpGet.withPath('/-/ping-nginx')
                      + container.mixin.readinessProbe.httpGet.withPort('http')
                      + container.mixin.readinessProbe.withInitialDelaySeconds(10)
                      + container.mixin.readinessProbe.withPeriodSeconds(5),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.web.labels),
      service: $.util.serviceFor(self.deployment),
    },
  },
}
