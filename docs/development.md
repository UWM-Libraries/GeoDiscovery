# Local Development

## Dependencies: Ruby and Java

To run GeoDiscovery locally, you'll need to be able to run Ruby and Java. GoRails has good instructions for installing Ruby on Rails on multiple operating systems online here: https://gorails.com/setup

Make sure you have Java installed. On a Mac with homebrew, that can be as simple as: `brew install java`.

### Clone the GeoDiscovery repository, and cd into it

```bash
git clone git@github.com:UWM-Libraries/GeoDiscovery.git
cd GeoDiscovery
```

### Configure your DotEnv files

.example.env.test and .example.env.development

```bash
cp .example.env.test .env.test
cp .example.env.development .env.development
```

After you copy the files, update them to include your database and solr connections.

For local Solr, GeoDiscovery expects development and test to use different ports by default:

- development: `http://127.0.0.1:8983/solr/blacklight-core`
- test: `http://127.0.0.1:8985/solr/blacklight-core`

The provided `.env.development` and `.env.test` files should match those defaults. `RAILS_ENV=test bundle exec rake ci` will normally manage its own test Solr on `8985`. If you want to point CI-style runs at an already-running Solr, set `USE_EXISTING_SOLR=1` and make sure `SOLR_URL` points at the test core.

### Bundle dependencies

The application's [RubyGem](https://rubygems.org/) dependencies are listed in the project `Gemfile`. Bundle the gems via this command:

```bash
bundle install
```

If the `Gemfile` has changed recently, you might need to run an additional command to get all the latest updates:

```bash
bundle update
```

### Install JavaScript dependencies

This project uses Vite for frontend assets, so you also need the Node packages from `package.json`:

```bash
yarn install
```

If `node_modules` is missing, Rails can still boot but page rendering will fail once Vite tries to resolve the frontend entrypoints.

### Database initialization

You'll need a local database for development and test modes. Both can just use sqlite.

```bash
bundle exec rake db:create
bundle exec rake db:migrate
```

In a production environment, you'll want a production capacity database like MySQL/MariaDB or PostgreSQL (recommended).

### Run the application

This rake task will run Solr and Puma and populate the application with the project's test fixture Aardvark JSON files:

```bash
bundle exec rake uwm:server
```

### Run the test suite

To run the project test suite, run this rake task below: (you'll need to stop the command above for the test suite to run correctly):

```bash
RAILS_ENV=test bundle exec rake ci
```

### Run the Ruby linter - Standard

GeoBlacklight uses [Standard](https://github.com/testdouble/standard) to ensure the application code is consistent and follows Ruby community best practices. Run the linter via the command below:

`bundle exec standardrb`

### Harvest Thumbnails - GeoBlacklight Sidecar Images

This project uses the [GeoBlacklight Sidecar Images](https://github.com/geoblacklight/geoblacklight_sidecar_images) gem to collect search result thumbnails.

That gem includes several helpful rake tasks to manage thumbnail images:

* bundle exec rake gblsci:images:harvest_all
* bundle exec rake gblsci:images:harvest_states
* bundle exec rake gblsci:images:harvest_failed_state_inspect
* bundle exec rake gblsci:images:harvest_report
* bundle exec rake gblsci:images:harvest_retry
* bundle exec rake gblsci:images:harvest_purge_all
* bundle exec rake gblsci:images:harvest_purge_orphans
* DOC_ID='stanford-cz128vq0535' bundle exec rake gblsci:images:harvest_doc_id

Read more about each rake task on the gem [README](https://github.com/geoblacklight/geoblacklight_sidecar_images) file.

### Harvest Metadata - GeoCombine

You can harvest OGM Aardark records via the [GeoCombine](https://github.com/OpenGeoMetadata/GeoCombine) gem. The [OMG metadata repositories](https://github.com/OpenGeoMetadata) are hosted on GitHub.

Clone metadata from an individual institution like this:

```bash
bundle exec rake geocombine:clone\[edu.umn\]
```

Clone all the OMG repositories like this:

```bash
bundle exec rake geocombine:clone
```

Index the documents you have harvested via this rake task:

```bash
bundle exec rake geocombine:index
```
