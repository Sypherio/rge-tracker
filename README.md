RGE Trends
==============================

This tool records power outages for RGE Monroe

Install `bundler`, and then run 

    bundle install

To start the tool, run

    bin/rge collect

If you want periodic updates on whether your street has power (i.e. 'john st'), run

    bin/rge collect --road 'john st'