# bin/geocombine_pull.sh
#!/bin/bash

if [ "$RAILS_ENV" == "production" ]; then
  source .env.production
else
  source .env.development
fi

bundle exec rake geocombine:pull[edu.uwm]
bundle exec rake geocombine:pull[edu.uchicago]
bundle exec rake geocombine:pull[edu.illinois]
bundle exec rake geocombine:pull[edu.indiana]
bundle exec rake geocombine:pull[edu.uiowa]
bundle exec rake geocombine:pull[edu.umd]
bundle exec rake geocombine:pull[edu.msu]
bundle exec rake geocombine:pull[edu.umn]
bundle exec rake geocombine:pull[edu.unl]
bundle exec rake geocombine:pull[edu.nyu]
bundle exec rake geocombine:pull[edu.osu]
bundle exec rake geocombine:pull[edu.psu]
bundle exec rake geocombine:pull[edu.purdue]
bundle exec rake geocombine:pull[edu.rutgers]
bundle exec rake geocombine:pull[edu.umich]
bundle exec rake geocombine:pull[edu.wisc]
bundle exec rake geocombine:pull[edu.berkeley]
bundle exec rake geocombine:pull[edu.columbia]
bundle exec rake geocombine:pull[edu.cornell]
bundle exec rake geocombine:pull[edu.princeton.arks]
bundle exec rake geocombine:pull[edu.stanford.purl]

bundle exec rake geocombine:index
