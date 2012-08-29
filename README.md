# capistrano-custom-maintenance

a customizable capistrano maintenance recipe.

this recipe has backward compatibility with original capistrano's maintenance features.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-custom-maintenance'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-custom-maintenance

## Usage

Add following in you `config/deploy.rb`.

    # in "config/deploy.rb"
    require 'capistrano-custom-maintenance'

Now you can entering/leaving maintenance

    $ cap deploy:web:disable # <-- entering maintenance
    $ cap deploy:web:enable # <-- leaving maintenance

If you prefer JSON response for maintenance page, you can do it with configuring as following.

    # in "config/deploy.rb"
    require 'capistrano-custom-maintenance'
    set(:maintenance_content_type, 'application/json')

Following options are available to manage your maintenance.

 * `:maintenance_basename` - basename of your maintenance page. use `maintenance` by default.
 * `:maintenance_filename` - filename of maintenance document, not including path part.
 * `:maintenance_suffix` - suffix of maintenance document. guessed from content-type by default.
 * `:maintenance_content_type` - the `Content-Type` of maintenance page. use `text/html` by default.
 * `:maintenance_reason` - the reason of maintenance. use `ENV['REASON']` by default.
 * `:maintenance_deadline` - the deadline of maintenance. use `ENV['UNTIL']` by default.
 * `:maintenance_document_path` - the path to the maintenance page on httpd.
 * `:maintenance_system_path` - the path to the maintenance page.
 * `:maintenance_template_path` - the path to the maintenance templates.
 * `:maintenance_template` - the path to the template of maintenance page.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Author

- YAMASHITA Yuu (https://github.com/yyuu)
- Geisha Tokyo Entertainment Inc. (http://www.geishatokyo.com/)

## License

MIT
