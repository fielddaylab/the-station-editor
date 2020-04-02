.PHONY: default deploy

default:
	webpack
	sass editor-react/scss/main.scss > editor-react/main.css
	sass assets/scss/styles.scss > assets/css/styles.css

deploy:
	rsync -vrc * .htaccess mli-sft@mli.doit.wisc.edu:/httpdocs --exclude-from rsync-exclude
