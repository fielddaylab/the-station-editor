.PHONY: default upload

default:
	npm install
	grunt --no-color

deploy:
	rsync -vrc * .htaccess mli-sft@mli.doit.wisc.edu:/httpdocs --exclude-from rsync-exclude
