
require 'erb'
require 'json'
require 'mime/types'

module Capistrano
  module CustomMaintenance
    def self.extended(configuration)
      configuration.load {
        namespace(:deploy) {
          _cset(:maintenance_template_path, File.dirname(__FILE__), 'templates')
          _cset(:maintenance_template) {
            ts = [
              File.join(maintenance_template_path, "#{maintenance_basename}.#{maintenance_suffix}.erb"),
              File.join(maintenance_template_path, "#{maintenance_basename}.erb"),
            ]
            ts << File.join(maintenance_template_path, "#{maintenance_basename}.rhtml") if maintenance_suffix == 'html'
            xs = ts.select { |t| File.exist?(t) }
            unless xs.empty?
              xs.first
            else
              abort("No such template found: #{ts.join(', ')}")
            end
          }
          _cset(:maintenance_content_type, 'text/html')
          _cset(:maintenance_suffix) { # suffix of maintenance document. guessed from content-type by default.
            type, = MIME::Types[maintenance_content_type]
            type.extensions.first
          }
          _cset(:maintenance_filename) { # filename of maintenance document, not including path part
            "#{maintenance_basename}.#{maintenance_suffix}"
          }
          _cset(:maintenance_system_path) { # actual path
            File.join(shared_path, maintenance_document_path)
          }
          _cset(:maintenance_document_path) { # virtual path on httpd
            File.join('/system', maintenance_filename)
          }

          _cset(:maintenance_timestamp) {
            Time.now
          }
          _cset(:maintenance_reason) {
            ENV.fetch('REASON', "maintenance")
          }
          _cset(:maintenance_deadline) {
            ENV.fetch('UNTIL', "shortly")
          }

          namespace(:web) {
            task(:disable, :roles => :web, :except => { :no_release => true }) {
              on_rollback {
                run("rm -f #{maintenance_system_path}")
              }

              reason = maintenance_reason
              deadline = maintenance_deadline

              begin
                ic = fetch(:maintenance_input_encoding, nil)
                template = File.read(maintenance_template, :external_encoding => ic)
              rescue
                template = File.read(maintenance_template)
              end

              _result = ERB.new(template).result(binding)
              begin
                oc = fetch(:maintenance_output_encoding, nil)
                result = oc ? _result.encode(oc) : _result
              rescue
                result = _result
              end

              put(result, maintenance_system_path, :mode => 0644)
            }

            task(:enable, :roles => :web, :except => { :no_release => true }) {
              run("rm -f #{maintenance_system_path}")
            }
          }
        }
      }
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::CustomMaintenance)
end

# vim:set ft=ruby :
