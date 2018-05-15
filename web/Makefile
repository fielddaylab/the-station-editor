.PHONY: default deploy

default:
	npm install
	grunt --no-color
	cp editor-react/js/browserify_out.js editor-react/js/minify_out.js
	# # for production:
	# closure-compiler --language_out=ES5 editor-react/js/browserify_out.js > editor-react/js/minify_out.js
	cp discover/browserify_out.js discover/minify_out.js

deploy:
	rsync -vrc * .htaccess mli-sft@mli.doit.wisc.edu:/httpdocs --exclude-from rsync-exclude
