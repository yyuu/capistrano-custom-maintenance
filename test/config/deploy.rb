set :application, "capistrano-custom-maintenance"
set :repository, "."
set :deploy_to do
  File.join("/home", user, application)
end
set :deploy_via, :copy
set :scm, :none
set :use_sudo, false
set :user, "vagrant"
set :password, "vagrant"
set :ssh_options, {:user_known_hosts_file => "/dev/null"}

role :web, "192.168.33.10"
role :app, "192.168.33.10"
role :db,  "192.168.33.10", :primary => true

$LOAD_PATH.push(File.expand_path("../../lib", File.dirname(__FILE__)))
require "capistrano-custom-maintenance"
require "mime/types"
require "tempfile"

def assert_file_exists(file, options={})
  begin
    invoke_command("test -f #{file.dump}", options)
  rescue
    logger.debug("assert_file_exists(#{file}) failed.")
    invoke_command("ls #{File.dirname(file).dump}", options)
    raise
  end
end

def assert_file_not_exists(file, options={})
  begin
    invoke_command("test \! -f #{file.dump}", options)
  rescue
    logger.debug("assert_file_not_exists(#{file}) failed.")
    invoke_command("ls #{File.dirname(file).dump}", options)
    raise
  end
end

def assert_file_content(file, content, options={})
  begin
    tempfile = Tempfile.new("capistrano-custom-maintenance")
    download(file, tempfile.path)
    tempfile.seek(0)
    raise if content != tempfile.read
  rescue
    logger.debug("assert_file_content_type(#{file}, #{content.dump}) failed.")
    raise
  end
end

def assert_command(cmdline, options={})
  begin
    invoke_command(cmdline, options)
  rescue
    logger.debug("assert_command(#{cmdline}) failed.")
    raise
  end
end

def assert_command_fails(cmdline, options={})
  failed = false
  begin
    invoke_command(cmdline, options)
  rescue
    logger.debug("assert_command_fails(#{cmdline}) failed.")
    failed = true
  ensure
    abort unless failed
  end
end

def reset_maintenance!
  variables.each_key do |key|
    reset!(key) if /^maintenance_/ =~ key
  end
end

task(:test_all) {
  find_and_execute_task("test_default")
  find_and_execute_task("test_with_html")
  find_and_execute_task("test_with_javascript")
  find_and_execute_task("test_with_json")
}

on(:start) {
  run("rm -rf #{deploy_to.dump}")
}

namespace(:test_default) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_default", "test_default:setup"
  after "test_default", "test_default:teardown"

  task(:setup) {
#   set(:maintenance_template_path, File.expand_path("tmp/maintenance"))
    set(:maintenance_content_type, "text/html")
    reset_maintenance!
    find_and_execute_task("deploy:setup")
    find_and_execute_task("deploy")
  }

  task(:teardown) {
    find_and_execute_task("deploy:web:enable")
  }

  task(:test_disable_enable) {
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.html"))
    find_and_execute_task("deploy:web:disable")
    assert_file_exists(File.join(current_path, "public", "system", "maintenance.html"))
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.html"))
  }
}

def prepare_templates(path, &block)
  run_locally("rm -rf #{path.dump}; mkdir -p #{path.dump}")
  templates = Object.new
  templates.instance_eval { @path = path }
  def templates.create(name, body)
    File.write(File.join(@path, name), body)
  end
  templates.instance_eval(&block)
# run_locally("rm -rf #{path.dump}")
end

namespace(:test_with_html) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_with_html", "test_with_html:setup"
  after "test_with_html", "test_with_html:teardown"

  task(:setup) {
    set(:maintenance_template_path, File.expand_path("tmp/maintenance"))
    set(:maintenance_content_type, "text/html")
    reset_maintenance!
    find_and_execute_task("deploy:setup")
    find_and_execute_task("deploy")
  }

  task(:teardown) {
    find_and_execute_task("deploy:web:enable")
  }

  task(:test_maintenance_with_erb) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.html", "html")
      create("maintenance.html.erb", "html.erb")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.html"), "html.erb")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.html"))
  }

  task(:test_maintenance_without_erb) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.html", "html")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.html"), "html")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.html"))
  }

  task(:test_maintenance_with_rhtml) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.rhtml", "rhtml")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.html"), "rhtml")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.html"))
  }
}

namespace(:test_with_javascript) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_with_javascript", "test_with_javascript:setup"
  after "test_with_javascript", "test_with_javascript:teardown"

  task(:setup) {
    set(:maintenance_template_path, File.expand_path("tmp/maintenance"))
    set(:maintenance_content_type, "application/javascript")
    reset_maintenance!
    find_and_execute_task("deploy:setup")
    find_and_execute_task("deploy")
  }

  task(:teardown) {
    find_and_execute_task("deploy:web:enable")
  }

  task(:test_maintenance_with_erb) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.js", "js")
      create("maintenance.js.erb", "js.erb")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.js"), "js.erb")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.js"))
  }

  task(:test_maintenance_without_erb) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.js", "js")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.js"), "js")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.js"))
  }
}

namespace(:test_with_json) {
  task(:default) {
    methods.grep(/^test_/).each do |m|
      send(m)
    end
  }
  before "test_with_json", "test_with_json:setup"
  after "test_with_json", "test_with_json:teardown"

  task(:setup) {
    set(:maintenance_template_path, File.expand_path("tmp/maintenance"))
    set(:maintenance_content_type, "application/json")
    reset_maintenance!
    find_and_execute_task("deploy:setup")
    find_and_execute_task("deploy")
  }

  task(:teardown) {
    find_and_execute_task("deploy:web:enable")
  }

  task(:test_maintenance_with_erb) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.json", "json")
      create("maintenance.json.erb", "json.erb")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.json"), "json.erb")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.json"))
  }

  task(:test_maintenance_without_erb) {
    reset_maintenance!
    prepare_templates(maintenance_template_path) do
      create("maintenance.json", "json")
    end
    find_and_execute_task("deploy:web:disable")
    assert_file_content(File.join(current_path, "public", "system", "maintenance.json"), "json")
    find_and_execute_task("deploy:web:enable")
    assert_file_not_exists(File.join(current_path, "public", "system", "maintenance.json"))
  }
}

# vim:set ft=ruby sw=2 ts=2 :
