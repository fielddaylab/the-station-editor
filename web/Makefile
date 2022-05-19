.PHONY: default deploy

default:
	./node_modules/.bin/webpack
	./node_modules/.bin/sass --load-path=node_modules/croppie editor/scss/main.scss > editor/main.css
	./node_modules/.bin/sass assets/scss/styles.scss > assets/css/styles.css

deploy:
	rsync -vrc * fieldday-web.wcer.wisc.edu:/var/www/station-vanderbilt --exclude-from rsync-exclude --delete
