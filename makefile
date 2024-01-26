image=3d-renderer

build:
	docker build -t $(image) .

upload-gltf:
	aws s3 cp ./glb/ s3://jq-staging-matko/gltf/ --recursive --profile jq-staging-sysops

run-server: build
	docker run --memory=1024m \
		--cpus=1 \
		--init \
		-it --rm \
		-p 3030:3030 \
		--entrypoint="" \
		$(image) /bin/sh -c "/app/cmd download && /usr/bin/xvfb-run -a /app/cmd serve"

run-client:
	cd client && go run main.go -all -save -size=2000

vegeta:
	vegeta attack -targets=request.txt -format=http -duration=20s -timeout=60s -rate=2 \
	| tee results.bin \
	| vegeta report

renderer-bash:
	docker run -it --rm -v $(PWD):/app -w /app --entrypoint="" $(image) bash

linux-bash:
	docker run -it --rm -v $(PWD):/app -w /app rust:1.75.0-bookworm bash

request:
	curl -X POST \
	-H "Content-Type: application/json" \
	-d @request.json http://localhost:3030/render \
	-o output.png
