require 'csv'
require 'readline'

module DBSCRIPT
  class World
    attr_accessor :params, :change_set, :results, :params_settings
    def initialize
      @params, @change_set, @results, @params_settings = {}, {} , {}, {}
    end
  end
end


trap('QUIT') { exit(-1) }

FIX_LEN = 80
def self.world
  @world ||= DBSCRIPT::World.new
end

def desc title, detail = ""
  hr
  cent title
  hr
  puts detail
  hr
  yield
end

def change_set name = :default
  OptionParser.new do |opts|
    opts.on("-y", "--yes", "Update without confirmation") do |yes|
      params[:yes] = true
    end
    self.world.params_settings.each do |key, settings|
      key_str = key.to_s
      opt1 = "-#{key_str[0..0]}"
      opt2 = "--#{key_str} [#{key_str}]"
      opt3 = settings[:desc]
      opts.on(opt1, opt2, opt3) do |value|
        params[key] = value
      end
    end
  end.parse!

  self.world.params_settings.each do |key, settings|
    unless params.has_key?(key)
      required = settings.has_key?(:required) || settings[:required]
      params[key] = read_input("#{settings[:desc]} : ", required)
    else
      puts "#{settings[:desc]} : #{params[key]}"
    end
  end
  self.world.change_set[name] = yield
end

def params
  self.world.params
end

def param name, desc, opt={}
  self.world.params_settings[name] = {:desc => desc}.merge(opt)
#  required = opt.has_key?(:required) || opt[:required]
#  params[name] ||= read_input(desc, required)
end

def update name = :default
  hr
  cent "Processing"
  hr
  to_be_changed = self.world.change_set[name]
  results = []
  if to_be_changed
    ActiveRecord::Base.transaction do
      if to_be_changed.kind_of? Array
        to_be_changed.each do |rec|
          results << yield(rec) 
          pp_changes rec
          rec.save
        end
      else
        results << yield(to_be_changed)
        pp_changes to_be_changed
        to_be_changed.save
      end
      unless params[:yes]
        unless confirm
          hr
          cent "QUIT without changing"
          hr
          results = []
          raise ActiveRecord::Rollback
        end
      end

      hr
      cent "DONE"
      hr
    end
  end
  self.world.results[name] = results
end

def summary name = :default
  changed = self.world.results[name]
  changed.each do |rec|
    yield rec
  end
end

private
def read_input( question, required = true )
  input = nil
  begin
    while input = Readline.readline(question, true).chomp
      break if input && !input.empty? || !required
    end    
  rescue Interrupt => e
    exit(-1)
  end
  input
end

def confirm( question = "[Y]es / [N]o :")
  hr
  script_results = []
  while line = Readline.readline(question, true)
    return "Y" == line.upcase if /[YN]/ =~ line.upcase 
  end
end

def pp_changes rec
  table_name = "#{rec.class.table_name}"
  puts table_name + " : #{rec.id}"
  rec.changes.each do |change|
    puts "#{' '* table_name.length}+-#{change[0]} : #{change[1][0]} -> #{change[1][1]}"
  end
end

def hr
  puts "=" * FIX_LEN
end

def cent title
  puts " " * ((FIX_LEN - title.length) /2)  + title
end
