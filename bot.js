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

var exec = require('child_process').exec;
var fs = require('fs');



tweetIt();
setInterval(tweetIt, 1000*60*60*2);

function tweetIt() {
    var cmd = 'processing-java --sketch=/Users/benjaminlock/github/twitterbot --run';
    exec(cmd, processing);
    function processing(){
        var filename = 'output/ww.png';
        var b64content = fs.readFileSync(filename, { encoding: 'base64' })
        T.post('media/upload', { media_data: b64content }, uploaded);
        function uploaded(err, data, response) {
            var id = data.media_id_string;
            var tweet = {
                media_ids: [id]
            }
            T.post('statuses/update', tweet, tweeted);
        }
        console.log('finished');
        function tweeted(err, data, response) {
            if (err) {
                console.log('error');
            } else {
                console.log('success!');
            }
        }
    }
}
