.PHONY: default deploy

default:
	webpack
	sass --load-path=node_modules/croppie editor-react/scss/main.scss > editor-react/main.css
	sass assets/scss/styles.scss > assets/css/styles.css

deploy:
	rsync -vrc * fieldday-web.ad.education.wisc.edu:/var/www/station/init/ --exclude-from rsync-exclude
