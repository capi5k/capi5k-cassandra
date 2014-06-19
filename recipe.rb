set :cassandra_path, "#{recipes_path}/capi5k-cassandra"

load "#{cassandra_path}/roles.rb"
load "#{cassandra_path}/roles_definition.rb"
load "#{cassandra_path}/output.rb"

set :puppet_p, "https_proxy='http://proxy:3128' http_proxy='http://proxy:3128' puppet"
set :wget_p, "https_proxy='http://proxy:3128' http_proxy='http://proxy:3128' wget"
set :apt_get_p, "https_proxy='http://proxy:3128' http_proxy='http://proxy:3128' apt-get"
set :gem_p, "https_proxy='http://proxy:3128' http_proxy='http://proxy:3128' gem"

set :file_cassandra_recipe, "#{file_cassandra_recipe}"

before :cassandra, :puppet

namespace :cassandra do

  desc 'Deploy Cassandra on nodes'
  task :default do
    generate
    modules::install
    transfer
    apply
    opscenter::default
  end

  task :generate do
    template = File.read("#{file_cassandra_recipe}")
    renderer = ERB.new(template)
    @cassandra_name = "cassandra_cluster"
    @cassandra_seeds = "#{seeds_cassandra}"
    generate = renderer.result(binding)
    myFile = File.open("#{cassandra_path}/tmp/cassandra.pp", "w")
    myFile.write(generate)
    myFile.close
  end

  namespace :modules do
    task :install, :roles => [:cassandra] do
      set :user, "root"
      run "#{puppet_p} module install msimonin/cassandra"
   end

    task :uninstall, :roles => [:cassandra] do
      set :user, "root"
      run "#{puppet_p} module uninstall msimonin/cassandra"
   end

  end

  task :transfer, :roles => [:cassandra] do
    set :user, "root"
    upload("#{cassandra_path}/tmp/cassandra.pp","/tmp/cassandra.pp", :via => :scp)  
  end

  task :apply, :roles => [:cassandra] do
    set :user, "root"
    run "FACTER_lsbdistid=debian #{puppet_p} apply /tmp/cassandra.pp -d "
  end

  # hack to install opscenter on debian
  # require openssl 0.9.8 but removed from wheezy
  # Only work on debian
  namespace :opscenter do
    desc 'Install the opscenter'
    task :default do
      package
      install
    end

    # source.list updated with cassandra
    task :package, :roles => [:cassandra_first] do
      set :user, "root"
      run "#{wget_p} http://ftp.fr.debian.org/debian/pool/main/o/openssl/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb -O /tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb 2>1"
    end

    task :install, :roles => [:cassandra_first] do
      set :user, "root"
      run "dpkg -i /tmp/libssl0.9.8_0.9.8o-4squeeze14_amd64.deb 2>1"
      run "#{apt_get_p} install -y opscenter-free 2>1"
    end

  end

end

