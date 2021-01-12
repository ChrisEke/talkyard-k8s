(import 'ksonnet-util/kausal.libsonnet') +
(import 'config.libsonnet') +
(import 'probe-config.libsonnet') +
(import 'talkyard-version.libsonnet') +

{
  local deployment = $.apps.v1.deployment,
  local container = $.core.v1.container,
  local port = $.core.v1.containerPort,
  local service = $.core.v1.service,
  local configMap = $.core.v1.configMap,
  local volumeMount = $.core.v1.volumeMount,

  local c = $._config.talkyard,

  local containerPorts(o) = [
    { name: p.name, containerPort: p.port }
    for p in o
  ],

  talkyard: {
    namespace: $.core.v1.namespace.new(c.namespace.name),
    app: {
      deployment: deployment.new(
                    name=c.app.name,
                    replicas=1,
                    containers=[
                      container.new(c.app.name, $._images.talkyard.app + ':' + $._version.talkyard.version)
                      + container.withPorts(containerPorts(c.app.ports))
                      + container.withEnv([
                        container.envType.fromSecretRef('POSTGRES_PASSWORD', 'talkyard-rdb-secrets', 'postgres-password'),
                        container.envType.fromSecretRef('PLAY_SECRET_KEY', 'talkyard-app-secrets', 'play-secret-key'),
                      ])
                      + container.withEnvFrom([container.envFromType.mixin.configMapRef.withName(self.envConfigMap.metadata.name)])
                      + container.mixin.readinessProbe.httpGet.withPath($._probe.app.readiness.httpPath)
                      + container.mixin.readinessProbe.httpGet.withPort('http')
                      + container.mixin.readinessProbe.withInitialDelaySeconds(10)
                      + container.mixin.livenessProbe.tcpSocket.withPort('http')
                      + container.mixin.livenessProbe.withInitialDelaySeconds(30)
                      + container.mixin.livenessProbe.withPeriodSeconds(15)
                      + container.mixin.livenessProbe.withTimeoutSeconds(5),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.app.labels)
                  + $.util.configVolumeMount(c.app.name + '-play-framework-conf', '/opt/talkyard/app/conf/app-prod-override.conf', volumeMount.withSubPath('app-prod-override.conf')),
      service: $.util.serviceFor(self.deployment),
      envConfigMap: configMap.new(c.app.name + '-environment-vars')
                    + configMap.withData(c.app.env),
    },
    rdb: {
      deployment: deployment.new(
                    name=c.rdb.name,
                    replicas=1,
                    containers=[
                      container.new(c.rdb.name, $._images.talkyard.rdb + ':' + $._version.talkyard.version)
                      + container.withPorts(containerPorts(c.rdb.ports))
                      + container.withEnv([
                        container.envType.fromSecretRef('POSTGRES_PASSWORD', 'talkyard-rdb-secrets', 'postgres-password'),
                      ])
                      + container.mixin.readinessProbe.exec.withCommand($._probe.rdb.readiness.execCommand)
                      + container.mixin.readinessProbe.withInitialDelaySeconds(10)
                      + container.mixin.readinessProbe.withTimeoutSeconds(6)
                      + container.mixin.readinessProbe.withPeriodSeconds(30)
                      + container.mixin.livenessProbe.exec.withCommand($._probe.rdb.liveness.execCommand)
                      + container.mixin.livenessProbe.withInitialDelaySeconds(30)
                      + container.mixin.livenessProbe.withPeriodSeconds(30)
                      + container.mixin.livenessProbe.withTimeoutSeconds(6),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.rdb.labels)
                  + $.util.configMapVolumeMount(self.initShOverrideConfigMap, '/docker-entrypoint-initdb.d'),
      service: $.util.serviceFor(self.deployment),
      initShOverrideConfigMap: configMap.new(c.rdb.name + '-init-sh-override')
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
                      + container.withPorts(containerPorts(c.cache.ports))
                      + container.mixin.readinessProbe.exec.withCommand($._probe.cache.readiness.execCommand)
                      + container.mixin.readinessProbe.withInitialDelaySeconds(20)
                      + container.mixin.readinessProbe.withTimeoutSeconds(5)
                      + container.mixin.readinessProbe.withPeriodSeconds(3)
                      + container.mixin.livenessProbe.tcpSocket.withPort(c.cache.ports[0].name)
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
                      + container.withPorts(containerPorts(c.search.ports))
                      + container.withEnvFrom([container.envFromType.mixin.configMapRef.withName(self.envConfigMap.metadata.name)])
                      + container.mixin.readinessProbe.exec.withCommand($._probe.search.readiness.execCommand)
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
      envConfigMap: configMap.new(c.search.name + '-environment-vars')
                    + configMap.withData(c.search.env),
    },
    web: {
      deployment: deployment.new(
                    name=c.web.name,
                    replicas=1,
                    containers=[
                      container.new(c.web.name, $._images.talkyard.web + ':' + $._version.talkyard.version)
                      + container.withPorts(containerPorts(c.web.ports))
                      + container.mixin.readinessProbe.httpGet.withPath($._probe.web.readiness.httpPath)
                      + container.mixin.readinessProbe.httpGet.withPort(c.web.ports[0].name)
                      + container.mixin.readinessProbe.withInitialDelaySeconds(10)
                      + container.mixin.readinessProbe.withPeriodSeconds(5),
                    ],
                  )
                  + deployment.mixin.metadata.withLabels(c.commonLabels + c.web.labels),
      service: $.util.serviceFor(self.deployment),
    },
  },
}
