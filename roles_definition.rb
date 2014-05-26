# cassandra nodes
role :cassandra do
  role_cassandra
end

# cassandra first node (opscenter installation)
role :cassandra_first do
  role_cassandra.first
end
