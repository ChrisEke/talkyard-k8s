(import 'config.libsonnet')
{
  local elastisearch_readiness = |||
    #!/usr/bin/env bash -e
    # If the node is starting up wait for the cluster to be green
    # Once it has started only check that the node itself is responding
    START_FILE=/tmp/.es_start_file

    http () {
        local path="${1}"
        if [ -n "${ELASTIC_USERNAME}" ] && [ -n "${ELASTIC_PASSWORD}" ]; then
        BASIC_AUTH="-u ${ELASTIC_USERNAME}:${ELASTIC_PASSWORD}"
        else
        BASIC_AUTH=''
        fi
        curl -XGET -s -k --fail ${BASIC_AUTH} http://127.0.0.1:9200${path}
    }

    if [ -f "${START_FILE}" ]; then
        echo 'Elasticsearch is already running, lets check the node is healthy'
        http "/"
    else
        echo 'Waiting for elasticsearch cluster to become green'
        if http "/_cluster/health?wait_for_status=green&timeout=1s" ; then
            touch ${START_FILE}
            exit 0
        else
            echo 'Cluster is not yet green'
            exit 1
        fi
    fi
  |||,
  _probe+:: {
    app: {
      readiness: {
        httpPath: '/-/are-scripts-ready',
      },
    },
    rdb: {
      readiness: {
        execCommand: ['/bin/sh', '-c', 'exec pg_isready -U "talkyard" -h 127.0.0.1 -p ' + $._config.rdb.ports[0].port],
      },
      liveness: {
        execCommand: $._probe.rdb.readiness.execCommand,
      },
    },
    cache: {
      readiness: {
        execCommand: ['redis-cli', 'ping'],
      },
    },
    search: {
      readiness: {
        execCommand: ['/bin/sh', '-c', elastisearch_readiness],
      },
    },
    web: {
      readiness: {
        httpPath: '/-/ping-nginx',
      },
    },
  },
}
