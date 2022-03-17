.PHONY: default deploy

default:
	./node_modules/.bin/webpack
	./node_modules/.bin/sass --load-path=node_modules/croppie editor/scss/main.scss > editor/main.css
	./node_modules/.bin/sass assets/scss/styles.scss > assets/css/styles.css

deploy:
	rsync -vrc * root@thestationmaine.com:/var/www/thestationmaine --exclude-from rsync-exclude --delete
