require 'yaml'
require 'json'
require 'pathname'

class CouchbasePetset
  def initialize(opts = {})
    @opts = opts
  end

  def storage_type
    @opts['storage_type'] || 'ephemeral'
  end

  def image_pull_policy
    @opts['image_pull_policy'] || 'Always'
  end

  def param_enabled
    key = 'param_enabled'
    return @opts[key] if @opts.key? key
    true
  end

  def image
    @opts['image'] || "#{param('REGISTRY')}/openshift/#{param('IMAGE_NAME')}"
  end

  def param(name)
    # os has parameters mode
    return "${#{name}}" if param_enabled

    # default user/pw
    return 'admin'     if name == 'COUCHBASE_USER'
    return 'k8s-rulez' if name == 'COUCHBASE_PASSWORD'

    # get default values
    parameters.each do |param|
      next if param['name'] != name
      break if param['value'].nil?

      return param['value'].to_i if name =~ /^REPLICAS_/

      return param['value']
    end
    nil
  end

  def image_sidecar
    @opts['image_sidecar'] || 'jetstackexperimental/couchbase-sidecar:0.0.2'
  end

  def k8s_template
    {
      'apiVersion' => 'v1',
      'kind' => 'List',
      'metadata' => {},
      'items' => [
        config_map,
        global_service,
        petset_service('query'),
        petset('query', 'ephemeral'),
        petset_service('data'),
        petset('data', nil),
        petset_service('index'),
        petset('index', nil)
      ]
    }
  end

  def openshift_template
    {
      'apiVersion' => 'v1',
      'kind' => 'Template',
      'metadata' =>
      {
        'name' => "couchbase-petset-#{storage_type}",
        'annotations' =>
        {
          'description' => template_description,
          'iconClass' => 'icon-couchbase',
          'tags' => 'database,couchbase'
        }
      },
      'objects' =>
      [
        config_map,
        global_service,
        petset_service('query'),
        petset('query', 'ephemeral'),
        petset_service('data'),
        petset('data', nil),
        petset_service('index'),
        petset('index', nil)
      ],
      'parameters' => parameters,
      'labels' => labels
    }
  end

  def template_description
    if storage_type == 'persistent'
      'Couchbase database service, with persistent storage. You must have persistent volumes available in your cluster to use this template.'
    else
      "Couchbase database service, with #{storage_type} storage."
    end
  end

  def scheduler_anti_affinity
    {
      'podAntiAffinity' => {
        'requiredDuringSchedulingIgnoredDuringExecution' => [{
          'labelSelector' => {
            'matchExpressions' => [
              {
                'key' => 'app',
                'operator' => 'In',
                'values' => ['couchbase']
              },
              {
                'key' => 'type',
                'operator' => 'In',
                'values' => %w(data index)
              },
              {
                'key' => 'name',
                'operator' => 'In',
                'values' => [param('DATABASE_SERVICE_NAME')]
              }
            ]
          },
          'topologyKey' => 'kubernetes.io/hostname'
        }]
      }
    }
  end

  def config_map
    {
      'kind' => 'ConfigMap',
      'apiVersion' => 'v1',
      'metadata' => { 'name' => param('DATABASE_SERVICE_NAME') },
      'data' => config_map_data
    }
  end

  def config_map_data
    data = {
      'couchbase.username' => param('COUCHBASE_USER'),
      'couchbase.password' => param('COUCHBASE_PASSWORD'),
      'couchbase.cluster-id' => '',
      "couchbase.bucket.#{param('COUCHBASE_BUCKET')}" => ''
    }
    roles.each do |role|
      data["couchbase.#{role}.memory-limit"] = param("MEMORY_LIMIT_#{role.upcase}")
    end
    data
  end

  def global_service
    {
      'kind' => 'Service',
      'apiVersion' => 'v1',
      'metadata' => { 'name' => param('DATABASE_SERVICE_NAME') },
      'spec' =>
      {
        'ports' => [{ 'name' => 'cb-admin', 'port' => 8091 }],
        'selector' => { 'name' => param('DATABASE_SERVICE_NAME') }
      }
    }
  end

  def roles
    %w(data index query)
  end

  def pod_template_sidecar
    {
      'name' => 'couchbase-sidecar',
      'image' => image_sidecar,
      'imagePullPolicy' => image_pull_policy,
      'env' =>
      [
        {
          'name' => 'POD_NAME',
          'valueFrom' => {
            'fieldRef' => { 'fieldPath' => 'metadata.name' }
          }
        },
        {
          'name' => 'POD_NAMESPACE',
          'valueFrom' => {
            'fieldRef' => { 'fieldPath' => 'metadata.namespace' }
          }
        },
        { 'name' => 'POD_IP',
          'valueFrom' => {
            'fieldRef' => { 'fieldPath' => 'status.podIP' }
          } }
      ],
      'readinessProbe' => {
        'httpGet' => {
          'path' => '/_status/ready',
          'port' => 8080
        },
        'timeoutSeconds' => 3
      },
      'lifecycle' => {
        'preStop' => {
          'exec' => {
            'command' => ['/couchbase-sidecar', 'stop']
          }
        }
      },
      'ports' => [{
        'containerPort' => 8080,
        'name' => 'sidecar'
      }],
      'volumeMounts' =>
      [
        {
          'mountPath' => '/sidecar',
          'name' => 'sidecar'
        }
      ]
    }
  end

  def pod_template(role)
    {
      'name' => 'couchbase',
      'image' => image,
      'imagePullPolicy' => image_pull_policy,
      'livenessProbe' =>
      {
        'initialDelaySeconds' => 30,
        'tcpSocket' => { 'port' => 8091 },
        'timeoutSeconds' => 1
      },
      'env' =>
      [
        {
          'name' => 'COUCHBASE_USER',
          'value' => param('COUCHBASE_USER')
        },
        {
          'name' => 'COUCHBASE_PASSWORD',
          'value' => param('COUCHBASE_PASSWORD')
        }
      ],
      'lifecycle' => {
        'preStop' => {
          'exec' => {
            'command' => ['/sidecar/couchbase-sidecar', 'stop']
          }
        }
      },
      'ports' => [
        {
          'containerPort' => 8091,
          'name' => 'cb-admin'
        },
        {
          'containerPort' => 8092,
          'name' => 'cb-views'
        },
        {
          'containerPort' => 8093,
          'name' => 'cb-queries'
        },
        {
          'containerPort' => 8094,
          'name' => 'cb-search'
        },
        {
          'containerPort' => 9100,
          'name' => 'cb-int-ind-ad'
        },
        {
          'containerPort' => 9101,
          'name' => 'cb-int-ind-sc'
        },
        {
          'containerPort' => 9102,
          'name' => 'cb-int-ind-ht'
        },
        {
          'containerPort' => 9103,
          'name' => 'cb-int-ind-in'
        },
        {
          'containerPort' => 9104,
          'name' => 'cb-int-ind-ca'
        },
        {
          'containerPort' => 9105,
          'name' => 'cb-int-ind-ma'
        },
        {
          'containerPort' => 9998,
          'name' => 'cb-int-rest'
        },
        {
          'containerPort' => 9999,
          'name' => 'cb-int-gsi'
        },
        {
          'containerPort' => 11_207,
          'name' => 'cb-memc-ssl'
        },
        {
          'containerPort' => 11_209,
          'name' => 'cb-int-bu'
        },
        {
          'containerPort' => 11_210,
          'name' => 'cb-moxi'
        },
        {
          'containerPort' => 11_211,
          'name' => 'cb-memc'
        },
        {
          'containerPort' => 11_214,
          'name' => 'cb-ssl-xdr1'
        },
        {
          'containerPort' => 11_215,
          'name' => 'cb-ssl-xdr2'
        },
        {
          'containerPort' => 18_091,
          'name' => 'cb-admin-ssl'
        },
        {
          'containerPort' => 18_092,
          'name' => 'cb-views-ssl'
        },
        {
          'containerPort' => 18_093,
          'name' => 'cb-queries-ssl'
        },
        {
          'containerPort' => 4369,
          'name' => 'empd'
        }
      ],
      'resources' => {
        'requests' => {
          'memory' => param("MEMORY_LIMIT_#{role.upcase}"),
          'cpu' => 0.1
        },
        'limits' => {
          'memory' => param("MEMORY_LIMIT_#{role.upcase}")
        }
      },
      'volumeMounts' =>
      [
        {
          'mountPath' => '/opt/couchbase/var',
          'name' => 'data'
        },
        {
          'mountPath' => '/sidecar',
          'name' => 'sidecar'
        }
      ]
    }
  end

  def petset_service(role)
    {
      'kind' => 'Service',
      'apiVersion' => 'v1',
      'metadata' =>
      {
        'name' => "#{param('DATABASE_SERVICE_NAME')}-#{role}",
        'annotations' =>
        {
          'service.alpha.kubernetes.io/tolerate-unready-endpoints' => 'true'
        }
      },
      'spec' =>
      {
        'clusterIP' => 'None',
        'ports' => [{ 'name' => 'cb-admin', 'port' => 8091 }],
        'selector' => {
          'name' => param('DATABASE_SERVICE_NAME'),
          'type' => role
        }
      }
    }
  end

  def petset(role, storage_type)
    storage_type = self.storage_type if storage_type.nil?
    petset = {
      'apiVersion' => 'apps/v1alpha1',
      'kind' => 'PetSet',
      'metadata' => {
        'name' => "#{param('DATABASE_SERVICE_NAME')}-#{role}"
      },
      'spec' =>
      {
        'serviceName' => "#{param('DATABASE_SERVICE_NAME')}-#{role}",
        'replicas' => param("REPLICAS_#{role.upcase}"),
        'template' =>
        {
          'metadata' =>
          {
            'labels' =>
            {
              'name' => param('DATABASE_SERVICE_NAME'),
              'app' => 'couchbase',
              'type' => role
            },
            'annotations' => {
              'pod.alpha.kubernetes.io/initialized' => 'true',
              'scheduler.alpha.kubernetes.io/affinity' => scheduler_anti_affinity.to_json
            }
          },
          'spec' =>
          {
            'terminationGracePeriodSeconds' => 86_400,
            'containers' => [
              pod_template(role),
              pod_template_sidecar
            ],
            'volumes' => [
              {
                'name' => 'sidecar',
                'emptyDir' => {}
              }
            ]
          }
        }
      }
    }

    if storage_type == 'persistent'
      petset['spec']['volumeClaimTemplates'] = [{
        'metadata' => {
          'name' => 'data',
          'annotations' => {
            'volume.alpha.kubernetes.io/storage-class' => param("STORAGE_CLASS_#{role.upcase}")
          }
        },
        'spec' => {
          'accessModes' => ['ReadWriteOnce'],
          'resources' => {
            'requests' => {
              'storage' => param("VOLUME_CAPACITY_#{role.upcase}")
            }
          }
        }
      }]
    else
      petset['spec']['template']['spec']['volumes'] << {
        'name' => 'data',
        'emptyDir' => {}
      }
    end
    petset
  end

  def deployment(role)
    {
      'apiVersion' => 'extensions/v1beta1',
      'kind' => 'Deployment',
      'metadata' => { 'name' => "#{param('DATABASE_SERVICE_NAME')}-#{role}" },
      'spec' =>
      {
        'replicas' => param("REPLICAS_#{role.upcase}"),
        'template' => {
          'metadata' =>
          { 'labels' =>
            { 'name' => param('DATABASE_SERVICE_NAME'),
              'app' => 'couchbase',
              'type' => role } },
          'spec' =>
            {
              'containers' => [
                pod_template(role),
                pod_template_sidecar
              ],
              'volumes' => [
                {
                  'name' => 'data',
                  'emptyDir' => {}
                },
                {
                  'name' => 'sidecar',
                  'emptyDir' => {}
                }
              ]
            }
        }
      }
    }
  end

  def deployment_config(role)
    pod_template_noimage = pod_template(role)
    pod_template_noimage['image'] = ''

    {
      'apiVersion' => 'v1',
      'kind' => 'DeploymentConfig',
      'metadata' => {
        'name' => "#{param('DATABASE_SERVICE_NAME')}-#{role}"
      },
      'spec' =>
      {
        'replicas' => param("REPLICAS_#{role.upcase}"),
        'selector' => {
          'name' => parm('DATABASE_SERVICE_NAME'),
          'type' => role
        },
        'template' =>
        { 'metadata' =>
          { 'labels' =>
            { 'name' => parm('DATABASE_SERVICE_NAME'),
              'app' => 'couchbase',
              'type' => role } },
          'spec' =>
            {
              'containers' => [
                pod_template_noimage,
                pod_template_sidecar
              ],
              'volumes' => [
                {
                  'name' => 'data',
                  'emptyDir' => {}
                },
                {
                  'name' => 'sidecar',
                  'emptyDir' => {}
                }
              ]
            } },
        'triggers' => [
          {
            'imageChangeParams' => {
              'automatic' => true,
              'containerNames' => ['couchbase'],
              'from' => {
                'kind' => 'ImageStreamTag',
                'name' => param('IMAGE_NAME'),
                'namespace' => param('NAMESPACE')
              }
            },
            'type' => 'ImageChange'
          },
          {
            'type' => 'ConfigChange'
          }
        ]
      }
    }
  end

  def labels
    { 'template' => "couchbase-petset-#{storage_type}-template" }
  end

  def parameters_per_role
    params = []
    roles.each do |role|
      params << {
        'name' => "REPLICAS_#{role.upcase}",
        'displayName' => "Desired Pod count for #{role} nodes",
        'description' => "How many #{role} nodes should be provisioned? This value can be changed later, by scaling up/down.",
        'value' => '3'
      }
      params << {
        'name' => "MEMORY_LIMIT_#{role.upcase}",
        'displayName' => "Memory Limit for #{role} nodes",
        'description' => "Maximum amount of memory #{role} container can use.",
        'value' => '512Mi'
      }

      next unless (role != 'query') && (storage_type == 'persistent')
      params << {
        'name' => "VOLUME_CAPACITY_#{role.upcase}",
        'displayName' => "Volume Capacity for #{role} nodes",
        'description' => "Volume space available for #{role} nodes, e.g. 512Mi, 2Gi.",
        'value' => '5Gi',
        'required' => true
      }
      params << {
        'name' => "STORAGE_CLASS_#{role.upcase}",
        'displayName' => "Storage Class for #{role} nodes",
        'description' => "Storage Class of the volume space for #{role} nodes, e.g. gp2, st1",
        'value' => 'gp2',
        'required' => true
      }
    end
    params
  end

  def parameters
    [
      {
        'name' => 'NAMESPACE',
        'displayName' => 'Namespace',
        'description' => 'The OpenShift Namespace where the ImageStream resides.',
        'value' => 'openshift'
      },
      {
        'name' => 'DATABASE_SERVICE_NAME',
        'displayName' => 'Database Service Name',
        'description' =>
        'The name of the OpenShift Service exposed for the database.',
        'value' => 'couchbase',
        'required' => true
      },
      {
        'name' => 'COUCHBASE_USER',
        'displayName' => 'Couchbase Connection Username',
        'description' =>
        'Username for Couchbase user that will be used for accessing the database.',
        'generate' => 'expression',
        'from' => 'user[A-Z0-9]{3}',
        'required' => true
      },
      {
        'name' => 'COUCHBASE_PASSWORD',
        'displayName' => 'Couchbase Connection Password',
        'description' => 'Password for the Couchbase connection user.',
        'generate' => 'expression',
        'from' => '[a-zA-Z0-9]{16}',
        'required' => true
      },
      {
        'name' => 'COUCHBASE_BUCKET',
        'displayName' => 'Couchbase Bucket Name',
        'description' => 'Name of the Couchbase database accessed.',
        'value' => 'bucket',
        'required' => true
      },
      {
        'name' => 'IMAGE_NAME',
        'value' => 'couchbase-noroot:4.5.1-enterprise',
        'required' => true
      },
      {
        'name' => 'REGISTRY',
        'value' => '###REGISTRY_IP###:5000',
        'required' => true
      }
    ] + parameters_per_role
  end
end

def write_openshift_templates
  dir = Pathname.new File.dirname(__FILE__)

  %w(persistent ephemeral).each do |storage_type|
    c = CouchbasePetset.new('storage_type' => storage_type)
    File.open(dir.join("couchbase-petset-openshift-#{storage_type}.yaml"), 'w') do |file|
      file.write c.openshift_template.to_yaml
    end
  end
end

def write_k8s_templates
  dir = Pathname.new File.dirname(__FILE__)

  %w(persistent ephemeral).each do |storage_type|
    c = CouchbasePetset.new(
      'storage_type' => storage_type,
      'image_pull_policy' => 'IfNotPresent',
      'image' => 'couchbase/server:enterprise-4.5.1',
      'param_enabled' => false
    )
    File.open(dir.join("couchbase-petset-k8s-#{storage_type}.yaml"), 'w') do |file|
      file.write c.k8s_template.to_yaml
    end
  end
end

write_openshift_templates
write_k8s_templates
