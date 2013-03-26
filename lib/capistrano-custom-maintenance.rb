require "capistrano/configuration/resources/file_resources"
require "erb"
require "json"
require "mime/types"

module Capistrano
  module CustomMaintenance
    def self.extended(configuration)
      configuration.load {
        namespace(:maintenance) {
          _cset(:maintenance_template_path, File.expand_path("templates", File.dirname(__FILE__)))
          _cset(:maintenance_content_type, "text/html")
          _cset(:maintenance_suffix) { # suffix of maintenance document. guessed from content-type by default.
            MIME::Types[maintenance_content_type].map { |type| type.extensions }.flatten.first
          }
          _cset(:maintenance_basename, "maintenance")
          _cset(:maintenance_filename) { "#{maintenance_basename}.#{maintenance_suffix}" } # filename of maintenance document, not including path part
          _cset(:maintenance_system_path) { File.join(shared_path, maintenance_document_path) } # actual path
          _cset(:maintenance_document_path) { File.join("/system", maintenance_filename) } # virtual path on httpd
          _cset(:maintenance_timestamp) { Time.now }
          _cset(:maintenance_reason) { ENV.fetch("REASON", "maintenance") }
          _cset(:maintenance_deadline) { ENV.fetch("UNTIL", "shortly") }

          def template(name, options={})
            reason = fetch(:maintenance_reason)
            deadline = fetch(:maintenance_deadline)
            options = {
              :path => maintenance_template_path,
              :binding => binding,
            }.merge(options)
            options[:external_encoding] = fetch(:maintenance_input_encoding) if exists?(:maintenance_input_encoding)
            result = top.template(name, options)
            exists?(:maintenance_output_encoding) ? result.encode(fetch(:maintenance_output_encoding)) : result
          end
        }

        namespace(:deploy) {
          namespace(:web) {
            task(:disable, :roles => :web, :except => { :no_release => true }) {
              on_rollback do
                find_and_execute_task("deploy:web:enable")
              end
              top.put(maintenance.template(maintenance_filename), maintenance_system_path, :mode => "644")
            }

            task(:enable, :roles => :web, :except => { :no_release => true }) {
              run("rm -f #{maintenance_system_path.dump}")
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
