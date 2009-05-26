# linky is a simple yaml list ui

you make a list of stuff in yaml and I display it in html and atom via some PHP

# linky worker scripts, for maintaining your linky

I have included a ruby script in the bin to help create/update your linky file, run it with the --help for help like: ruby ./linky_worker.rb --help

You will want to setup your config file before using it. An assumption is made that you already have your remote host setup with your public key for authentication, therefore you only provide your remote host and username, not your password

# some gists to help you out

  1. bin/gists/amazon_mp3_music.rb
      Given a URL to an Amazon MP3 Album page, will give you the following: album, artist, URL to album art, referral link for Amazon
  2. bin/gists/image_resizer.rb
      Simple ruby script that breaks out to a dynamic apple script that utilizes Image Events.app (Mac OS X only) to resize image to your desired width

# dependencies

linky itself depends on a pure-PHP YAML parsing library called spyc and available here: http://code.google.com/p/spyc/
currently dependent on version 0.4.1

you'll need ruby in your environment to run the helper scripts, plus the following gems: net-ssh, net-sftp, hpricot

some helper scripts are mac only but platform independent versions are encouraged if you want to write one

# usage

  1. Download the source
  2. Copy configuration file from: bin/config.yml.example to bin/config.yml
  3. Setup the config file for your environemnt, assumes your SSH public keys are already configured
  4. Run the setup script: bin/linky_worker.rb -s
  5. Copy the public directory to your production environment
  6. Copy the linky.yml file that was generated in step 5 to a directory one-level up from the public directory (make sure the linky.yml file is not publicly accessible because there is a secret key in that file that is for your eyes only)
  7. Add items to your linky file (will automatically deploy to your production environment): bin/linky_worker.rb -a
  8. See bin/amazon_music_worker.rb for example of an automated task for updating your linky

# license

linky is freely distributable under the terms of an MIT-style license