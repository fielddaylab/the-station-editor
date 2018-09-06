.PHONY: default deploy

default:
	yarn
	gulp

deploy:
	rsync -vrc * .htaccess mli-sft@mli.doit.wisc.edu:/httpdocs --exclude-from rsync-exclude
