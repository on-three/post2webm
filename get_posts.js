var page = require('webpage').create();
var system = require('system');
var fs = require('fs');

var args = system.args

if(args.length < 2)
{
  console.log("Generate a list of post numbers for a single thread.");
  console.log("USAGE: phantomjs get_post.js <image board post URL> [optional post number] [optional output directory]");
  phantom.exit(1);
}


var filter_post = function(str) {
  // remove all (YOU)s
  str = str.replace(/>>[0-9]+/g,'');
  // remove all greentext
  str = str.replace(/>/g,' ');
  // remove all hyperlinks and youtbes
  str = str.replace(/https?:\/\/[^s]+/g,'')

  //expand some common abbreviations so they're better for tts
  str = str.replace(/ tfw /g, ' the feel when ');
  str = str.replace(/ mfw /g, ' my face when ');

  
  return str;
}

var url = args[1];
var thread_num = 0;
var out_dir = ".";

// first arg has to be a basic URL, with our without a post selector at the end (#xxx)
// Archive single post URL signature
//https://archive.4plebs.org/tv/thread/91299237/#91299237
// 4chin aingle post URL signature
//http://boards.4chan.org/tv/thread/91305580#p91305580
var postNumRegex = new RegExp("(.+)(/#|#p)([0-9]+)$")

var post_num_match = url.match(postNumRegex)
if(post_num_match)
{
  url = post_num_match[1];
}

if(args.length > 2)
{
  out_dir = args[2]
}

thread_num = url.match(/([0-9]+)\/?$/, '')[1];

// the path to the textfile we'll write (a simple list of post numbers)
//var text_filepath = 'post_numbers.txt'
var text_filepath = out_dir + '/posts-' + thread_num + '.txt'

var chin_regex = new RegExp("boards.4chan.org");
var is_4chin = chin_regex.test(url);

//console.log("URL: ", url);
//console.log("Output dir: ", out_dir);
//console.log("Thread num:", thread_num);
// TODO: remove this selector
var s = "";

page.open(url, function() {
    // being the actual size of the headless browser
    page.viewportSize = { width: 768, height: 1024 };
    
    // generate a post image
    var post_list = page.evaluate(function(s){
      var _post_list = document.querySelectorAll('.post');
      
      var posts = [];
      for(var i=0; i < _post_list.length; ++i)
      {
        // get the post number
        var _post = _post_list[i];
        var _id = _post.id;
        _id = _id.replace(/^p/,'');
      
        posts.push(_id);
      }
      
      return posts;
      
    },s);

    //console.log("posts: ", post_list);

    //post_list = ["a", "b", "c"];
    //console.log("posts: ", post_list);
    var _txt = post_list.join('\n');
    //console.log(_txt);
    fs.write(text_filepath, _txt, 'w');
    
    phantom.exit();
});

console.log(text_filepath);

//phantom.exit(0);

