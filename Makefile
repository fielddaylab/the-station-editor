.PHONY: default deploy
default:
	cd web/ && make
deploy:
	cd web/ && make deploy
