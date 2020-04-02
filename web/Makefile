.PHONY: default deploy

default:
	webpack
	sass editor-react/scss/main.scss > editor-react/main.css
	sass assets/scss/styles.scss > assets/css/styles.css

deploy:
	rsync -vrc * tolly@fieldday-web.ad.education.wisc.edu:/var/www/stemports/siftr --exclude-from rsync-exclude
