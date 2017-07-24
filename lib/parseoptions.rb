require 'optparse'
require 'optparse/time'
require 'ostruct'
class ParseOptions

  CODES = %w[iso-2022-jp shift_jis euc-jp utf8 binary]
  CODE_ALIASES = { "jis" => "iso-2022-jp", "sjis" => "shift_jis" }

  def self.parse(args)
  options = OpenStruct.new

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: rubrik.rb [options]"

    opts.separator ""
    opts.separator "Specific options:"
    opts.on('-l', '--login', "Perform no operations but return authentication token") do |login|
      options[:login] = login;
    end
    opts.on('-c', '--client [name]', "Name of Virtual Machine to perform operation for") do |c|
      options[:vm] = c;
    end
    opts.on('-g', '--get',"Perform GET operation") do |g|
      options[:get] = g;
    end
    opts.on('-a', '--assure [string]',"String to set in SET operation (in case of --sla, it's the SLA Name)") do |g|
      options[:assure] = g;
    end
    opts.on('--dr', "Instant Recovery of --client") do |g|
      options[:dr] = g;
    end
    opts.on('--sla',"Perform and SLA Operation (used with --get or --assure") do |g|
      options[:sla] = g;
    end
    opts.on('--list', "Audit SLA configuration (used with --sla)") do |g|
      options[:list] = g;
    end
    opts.separator ""
    opts.separator "Metric options:"
    opts.on('--metric', "Return Requested Metric") do |g|
      options[:metric] = g;
    end
    opts.on('--storage', "Return storage capacity information") do |g|
      options[:storage] = g;
    end
    opts.on('--incoming', "Return the number of currently incoming snapshots") do |g|
      options[:incomingsnaps] = g;
    end
    opts.on('--runway', "Return the available runway in days") do |g|
      options[:runway] = g;
    end
    opts.on('--iostat [range]', "Return iostat information for range (30sec, 60min, etc)") do |g|
      options[:iostat] = g;
    end
    opts.on('--archivebw [range]', "Return archive bandwidth information for range (30sec, 60min, etc)") do |g|
      options[:archivebw] = g;
    end
    opts.on('--physicalingest [range]', "Return physical ingest bandwidth information for range (30sec, 60min, etc)") do |g|
      options[:physicalingest] = g;
    end
    opts.on('--localingest [range]', "Return local ingest bandwidth information for range (30sec, 60min, etc)") do |g|
      options[:localingest] = g;
    end
    opts.on('--snapshotingest [range]', "Return snapshot ingest bandwidth information for range (30sec, 60min, etc)") do |g|
      options[:snapshotingest] = g;
    end
    opts.on('-j', '--json', "Output in JSON if possible") do |g|
      options[:json] = g;
    end
    opts.separator ""
    opts.separator "Experimental options:"
    opts.on('--file', "Experimental - file search and recovery") do |g|
      options[:file] = g;
    end
    opts.on('--relics [days]',"Remove Relic VMs after [n] days of inactivity") do |g|
      options[:relics] = g;
    end
    opts.separator ""
    opts.separator "Common options:"
    opts.on('-n', '--node [Address]', "Rubrik Cluster Address/FQDN") do |node|
      options[:n] = node;
    end
    opts.on('-u', '--username [username]',"Rubrik Cluster Username") do |user|
      options[:u] = user;
    end
    opts.on('-p', '--password [password]', "Rubrik Cluster Password") do |pass|
      options[:p] = pass;
    end
    opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
    end
  end
  opt_parser.parse!(args)
   options
  end
end
