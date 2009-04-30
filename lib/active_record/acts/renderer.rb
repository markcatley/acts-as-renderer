require 'application_controller'

module ActiveRecord
  module Acts #:nodoc:
    module Renderer #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end
    
      # Allows models to support render_to_file and render_to_string methods
      module ClassMethods
        def acts_as_renderer
          class_eval <<-EOV, __FILE__, __LINE__
            include ActiveRecord::Acts::Renderer::InstanceMethods
          
            # Renders a template to a file with the included variable assignments
            def self.render_file(template, destination, assigns)
              if output = render_string(template, assigns)
                unless File.directory?(File.dirname(destination))
                  path = ''
                  File.expand_path(File.dirname(destination)).split(File::SEPARATOR).each do |dir|
                    path = File.join(path, dir)
                    unless File.directory?(path)
                      Dir.mkdir(path)
                    end
                  end
                end
                File.open(destination, 'w') do |file|
              	  file.write output
            	  end
              end
            end

            # Renders a template to a string with the included variable assignments
            def self.render_string(template, assigns)
              viewer = Class.new(ApplicationController)
              path = ActionController::Base.view_paths rescue ActionController::Base.view_root
              ActionView::Base.new(path, assigns, viewer).render(:file => template)
            end
          EOV
        end
      end
      
      # For instance, if your model is HomePage, you could say:
      # home_page.render_to_file('page', "#{self.user.name}/page.html", :now => Time.now)
      # and the destination file would be rendered using the template 'page', with the instance
      # variables @now and @home_page populated with Time.now and the current instance, respectively
      # The functions render_to_file and render_to_string work the same way.
      module InstanceMethods
        # Renders a record instance to a file using the provided template and any additional variables.
        def render_to_file(template, destination, variables={})
          assigns = variables.reverse_merge(self.class.class_name.underscore.to_sym => self)
          self.class.render_file(template, destination, assigns)          
        end

        # Renders a record instance to a string using the provided template and additional variables.
        def render_to_string(template, variables={})
          assigns = variables.reverse_merge(self.class.class_name.underscore.to_sym => self)
          self.class.render_string(template, assigns)
        end    
      end
    end
  end
end
