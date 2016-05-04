#!/usr/local/bin/node

/* µS Build Script */

var closurecompiler = require('closurecompiler'),
	sasscompiler = require('node-sass'),
	fs = require('fs-extra'),
	path = require('path'),
	root = path.join(__dirname, '..'),
	build = path.join(__dirname, 'build'),
	sass = [
		'screen.sass'
	],
	js = [
		'lib.js',
		'setup.js',
		'main.js'
	],
	html = [
		'setup.html',
		'main.html'
	];

fs.removeSync(build);
fs.mkdirsSync(build);

var Hacha = function(contents, breaks, target) {
	var lines = [];
	breaks = breaks || [';', '{', '}'];
	target = target || 228;
	contents = contents.replace(/\n/g, '');
	while(true) {
		if(contents.length <= target) {
			lines.push(contents);
			break;
		}
		var chunk = contents.substr(0, target),
			punctuation = (function() {
				var is = [];
				breaks.forEach(function(p) {
					var i = chunk.lastIndexOf(p);
					i !== -1 && is.push(i);
				});
				is.sort(function(a, b) {
					return b - a;
				});
				return is;
			}())[0] || (chunk.length - 1);

		lines.push(chunk.substr(0, punctuation + 1));
		contents = contents.substr(punctuation + 1);
	}
	return lines.join('\n');
}

var DoSass = function(done) {
	var file = sass.shift();
	if(!file) return done();
	console.log("Compiling: " + file);
	sasscompiler.render({
		file: path.join(root, file),
		outputStyle: 'compressed'
	}, function(err, result) {
		fs.writeFile(path.join(build, file.replace(/\.sass/, '.css')), Hacha(result.css + ''), function() {
			DoSass(done);
		});
	});
};

var DoJS = function(done) {
	var file = js.shift();
	if(!file) return done();
	console.log("Compiling: " + file);
	closurecompiler.compile(path.join(root, file), {
		compilation_level: "SIMPLE_OPTIMIZATIONS"
	}, function(err, js) {
		fs.writeFile(path.join(build, file), Hacha(js), function() {
			DoJS(done);
		});
	});
};

var DoHTML = function(done) {
	var file = html.shift();
	if(!file) return done();
	console.log("Compiling: " + file);
	fs.readFile(path.join(root, file), 'utf-8', function(err, html) {
		fs.writeFile(path.join(build, file), Hacha(html.replace(/\t/g, ''), ['>']), function() {
			DoHTML(done);
		});
	});
};


/*return fs.readFile('/Users/dani/Downloads/CryptoJS v3.1.2/rollups/hmac-sha256.js', 'utf-8', function(err, js) {
	fs.writeFile(path.join(root, 'sha256.js'), Hacha(js), function() {
		console.log('Done!');
	});
});*/

DoSass(function() {
	DoJS(function() {
		DoHTML(function() {
			console.log('Done!');
		});
	});
});
