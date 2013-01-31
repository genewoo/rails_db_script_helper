require 'csv'
require 'readline'

module DBSCRIPT
  class World
    attr_accessor :params, :change_set, :results
    def initialize
      @params, @change_set, @results = {}, {} , {}      
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

change_set_data = {}
change_results = {}

def change_set name = :default
#  hr
#  cent "Change Set"
#  hr
  self.world.change_set[name] = yield
end

def params
  self.world.params
end

def param name, desc, opt={}
  required = opt.has_key?(:required) || opt[:required]
  params[name] ||= read_input(desc, required)
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
