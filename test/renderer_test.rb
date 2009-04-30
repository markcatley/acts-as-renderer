require 'test/unit'

require "#{File.dirname(__FILE__)}/../../../../config/boot"
require 'active_record'
require 'action_controller'
require 'active_support'

require "#{File.dirname(__FILE__)}/../init"
RAILS_DEFAULT_LOGGER = Logger.new('/dev/null')
Rails::Initializer.run { |config| config.view_path = File.dirname(__FILE__) }

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :name, :string
      t.column :datetime, :created_at
      t.column :datetime, :updated_at
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class RendererMixin < Mixin
  acts_as_renderer

  def self.table_name() "mixins" end
end

class RendererTest < Test::Unit::TestCase

  def setup
    setup_db
    %w(fred wilma barney betty dino pebbles bambam).each { |name| RendererMixin.create! :name => name }
  end

  def teardown
    teardown_db
  end

  def test_render_to_string
    RendererMixin.find(:all).each do |p|
      assert_equal "Hi, I'm #{p.name}", p.render_to_string('instance.erb')
    end
  end
  
  def test_render_to_file
    RendererMixin.find(:all).each do |p|
      p.render_to_file('instance.erb', "./#{p.name}.txt")
      assert_equal "Hi, I'm #{p.name}", File.read("#{p.name}.txt")
      File.delete("./#{p.name}.txt")
    end
  end
  
  def test_render_string
    output = RendererMixin.render_string('class.erb', :person => 'fred', :animal => 'dinosaur')
    assert_equal "fred has a dinosaur", output
  end
  
  def test_render_file
    RendererMixin.render_file('class.erb', './class.txt', :person => 'matz', :animal => 'python' )
    assert_equal "matz has a python", File.read('./class.txt')
    File.delete('./class.txt')
  end
  
  def test_render_to_new_directory
    if Dir.entries('.').include? 'test_render_tmp'
      Dir.delete('test_render_tmp')
    end
    
    RendererMixin.render_file('class.erb', './test_render_tmp/class.txt', :person => 'matz', :animal => 'python' )
    assert_equal "matz has a python", File.read('./test_render_tmp/class.txt')
    File.delete('./test_render_tmp/class.txt')
    Dir.delete('test_render_tmp')
  end

  def test_render_to_new_nested_directory
    if Dir.entries('.').include? 'test_render_tmp'
      if Dir.entries('test_render_tmp').include? 'another_tmp_dir'
        Dir.delete('test_render_tmp/another_tmp_dir')
      end
      
      Dir.delete('test_render_tmp')
    end
    
    RendererMixin.render_file('class.erb', './test_render_tmp/another_tmp_dir/class.txt', :person => 'matz', :animal => 'python' )
    assert_equal "matz has a python", File.read('./test_render_tmp/another_tmp_dir/class.txt')
    File.delete('./test_render_tmp/another_tmp_dir/class.txt')
    Dir.delete('test_render_tmp/another_tmp_dir')
    Dir.delete('test_render_tmp')
  end
end
