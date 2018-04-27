var page = require('webpage').create();
var system = require('system');
var fs = require('fs');

var args = system.args
var url = 'http://google.com'
var s = '#hplogo'
var outfile = 'post'

if(args.length > 1)
{
  url = args[1];
}
if(args.length > 2)
{
  s = args[2];
  // escape selectors that start with a number
  var r = new RegExp("^\#[0-9]{1}");
  if(r.test(s))
  {
    s = s.substring(1, s.length);
    var n = s.substring(0, 1);
    s = s.substring(1, s.length);
    s = '#\\3' + n + ' ' + s;
  }
}
if(args.length > 3)
{
  outfile = args[3]
}

console.log("URL: ", url);
console.log("Selector: ", s);
console.log("Outfile: ", outfile);

phantom.addCookie({
  'name': 'foolframe_2q1_theme',
  'value': 'foolz%2Ffoolfuuka-theme-yotsubatwo%2Fyotsuba-b',
  'domain': 'boards.fireden.net'
});

page.open(url, function() {
    // being the actual size of the headless browser
    page.viewportSize = { width: 768, height: 1024 };
    
    // generate a post image
    var clipRect = page.evaluate(function(s){
      return document.querySelector(s).getBoundingClientRect();
    },s);
    
    page.clipRect = {
      top:    clipRect.top,
      left:   clipRect.left,
      width:  clipRect.width,
      height: clipRect.height
    };
    page.render(outfile + '.png');
    
    // extract post text
    var txt = page.evaluate(function(s){
      return document.querySelector(s).textContent;
    },s);
    console.log('TEXT: ', txt);


    if(txt.length > 0)
    {
      var textFilePath = outfile + '.post.txt';
      fs.write(textFilePath, txt, 'w');
    }
    
    phantom.exit();
});

