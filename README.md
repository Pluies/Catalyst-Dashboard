## Introduction

A [Dashing](http://shopify.github.com/dashing)-based dashboard 

![screenshot](https://github.com/Pluies/Catalyst-Dashboard/blob/master/public/screenshot.png?raw=true)

## Installation

This assumes you have Ruby (1.9+), Git, RubyGems, g++ and a javascript runtime installed. For example on Ubuntu:

    sudo apt-get install ruby1.9.1-full git nodejs g++

Install the required gems (NB: if it gives you a permission error, try sudo):

    gem install bundler dashing

Now to install this dashboard:

    git clone https://github.com/Pluies/Catalyst-Dashboard
    cd Catalyst-Dashboard
    bundle

Check out http://shopify.github.com/dashing for more information.

## Configuration

In order to use the Redmine and WRMS plugins, you will need a configuration file holding your passwords:

    touch ~/.dashing.yaml
    chmod 600 ~/.dashing.yaml # we don't want anyone else to read that!

This file should have the following syntax:

    wrms:
      server: wrms.catalyst.net.nz
      user_id: 2583 # From https://wrms.catalyst.net.nz/whoami.php
      auth_key: 7bb7c5af1491da1a988lce280de67807 # Your 'session_id' from https://wrms.catalyst.net.nz/api2/explorer - NB you might need to log out and log back in again
      password: password # Deprecated, you should use auth_key. However if the auth_key fails, it will try to use user_id/password auth
      max_wrs: 15
      linktoall: https://wrms.catalyst.net.nz/report?r=request&v=5#_f=request_id%2Cstatus_desc%2Cbrief%2Crequester_id_fullname&_o=request_id&_d=desc&_s=200&_p=1&allocated_to=MY_USER_ID&last_status=A%2CB%2CE%2CD%2CI%2CK%2CL%2CN%2CQ%2CP%2CS%2CR%2CU%2CW%2CV%2CZ

    redmine:
      url: https://redmine.catalyst.net.nz
      username: florent
      password: password

Replace the passwords, username and WRMS user_id / auth_key with your own information.

NB: keeping the Redmine password in a plain-text file is not a great solution, but we need it to access the API and I haven't found a better solution yet. Please contact me or submit a pull request if you know of a better way to do it.

## Starting your dashboard    

    dashing start

Your dashboard should now be accessible at: [http://localhost:3030/dashing](http://localhost:3030/dashing)

## License

These modifications, like Dashing itself, are released under the MIT license.

