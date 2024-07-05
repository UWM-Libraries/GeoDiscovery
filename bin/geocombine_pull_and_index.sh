# bin/geocombine_pull.sh
#!/bin/bash
# This will only work in production!

OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.uwm]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.uchicago]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.illinois]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.indiana]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.uiowa]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.umd]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.msu]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.umn]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.unl]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.nyu]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.osu]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.psu]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.purdue]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.rutgers]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.umich]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.berkeley]
# GBL 1.0 institutions:
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.wisc]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.columbia]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.cornell]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.princeton.arks]
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake geocombine:pull[edu.stanford.purl]
# GBL 1.0 to Aardvark Convert:
OGM_PATH=/var/www/rubyapps/uwm-geoblacklight/shared/tmp/opengeometadata/ bundle exec rake uwm:opendataharvest:gbl1_to_aardvark
# GBL 1.0 to Aardvark Convert:
bundle exec rake uwm:index:delete_all
RAILS_ENV=production bundle exec rake geocombine:index