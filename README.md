# Introduction

A [Dashing](http://shopify.github.com/dashing)-based dashboard 

# Installation

This assumes you have Ruby (1.9+) and RubyGems installed.

    gem install dashing
    git clone https://github.com/Pluies/Catalyst-Dashboard
    cd Catalyst-Dashboard
    bundle

Check out http://shopify.github.com/dashing for more information.

# Configuration

In order to use the Redmine and WRMS plugins, you will need a configuration file holding your passwords:

    touch ~/.dashing.yaml
    chmod 600 ~/.dashing.yaml # we don't want anyone else to read that!

This file should have the following syntax:

    wrms:
      user_id: 2583
      password: password
      server: wrms.catalyst.net.nz
      max_wrs: 15
      linktoall: https://wrms.catalyst.net.nz/report?r=request&v=5#_f=request_id%2Cstatus_desc%2Cbrief%2Crequester_id_fullname&_o=request_id&_d=desc&_s=200&_p=1&allocated_to=MY_USER_ID&last_status=A%2CB%2CE%2CD%2CI%2CK%2CL%2CN%2CQ%2CP%2CS%2CR%2CU%2CW%2CV%2CZ

    redmine:
      url: https://redmine.catalyst.net.nz
      username: florent
      password: password

# Starting your dashboard    

    dashing start

Your dashboard should now be accessible at http://localhost:3030/dashing

# License

These modifications, like Dashing itself, are released under the MIT license.

