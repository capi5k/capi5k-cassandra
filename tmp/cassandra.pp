class { 'cassandra':
  package_name => "cassandra",
  version      => "1.2.9",
  cluster_name => "cassandra_cluster",
  seeds        => ["griffon-91.nancy.grid5000.fr", "griffon-92.nancy.grid5000.fr"],
  repo_pin     => false
}
