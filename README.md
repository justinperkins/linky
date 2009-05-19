# linky is a simple yaml list ui

you make a list of stuff in yaml and I display it in html and atom via some PHP

# linky worker scripts, for maintaining your linky

I have included a ruby script in the bin to help create/update your linky file, run it with the --help for help like: ruby ./linky_worker.rb --help

You will want to setup your config file before using it.

# image resizer script

If you make use of the special key, background_image, then you will probably want to utilize this resizer script (Mac only) to auto-resize a bunch of images

# dependencies

linky itself depends on a pure-PHP YAML parsing library called spyc and available here: http://code.google.com/p/spyc/
currently dependent on version 0.4.1

the linky worker script is a ruby script that depends on the following gems: Net::SSH, Net:SFTP

the linky image resizer is an apple script requires a Mac environemnt