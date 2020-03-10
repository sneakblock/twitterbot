console.log('The bot is starting.');

//Import statement using twit package.
var Twit = require('twit');

//Api keys for WeatherWizard app
var T = new Twit({
  consumer_key:         'wtk11zuWRXFmP4iJjeCa8HNzd',
  consumer_secret:      'lRYpMwpja5rxKyVQJW6N2VsMQruJ56lHwGITTbyOLAcCl0aIFh',
  access_token:         '1237512064576282624-n66jbXBR5VnSIi2CX8qtWorv3crKB5',
  access_token_secret:  'jOVmER2z48kEUJxYfmudoUP6LGQmgLoSpb07766ru69sg'
});
