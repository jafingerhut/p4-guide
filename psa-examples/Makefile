compile: psa-example-drop-all.p4
	p4c-bm2-psa $< -o psa-example-drop-all.json

run: psa-example-drop-all.json
	psa_switch --log-console -i 1@veth2 -i 2@veth4 psa-example-drop-all.json

run2: psa-example-drop-all.hand-edited.json
	psa_switch --log-console -i 1@veth2 -i 2@veth4 psa-example-drop-all.hand-edited.json
