COMPILED_CSS_DIR=public/css
COMPILED_JS_DIR=public/js
JAVA?=java
YUI_COMPRESSOR=$(JAVA) -jar tools/yuicompressor.jar


js: js-openlayers js-bodo

js-dir:
	# create the diretory if it does not exist
	[ -d $(COMPILED_JS_DIR) ] || mkdir $(COMPILED_JS_DIR)

js-openlayers:
	# for adapting the openlayers build please alter the
	# file at
	# public/js/External/openlayers/build/altlast.cfg
	# or use full.cfg to avoid the horrible js dependency tracking
	# Closure-compiler will break openlayers, yui-compressor works
	rm -f $(COMPILED_JS_DIR)/openlayers.js
	cd public/js/openlayers/build && python build.py full.cfg openlayers.full.js

js-bodo: js-dir js-openlayers
	rm -f $(COMPILED_JS_DIR)/script.js
	cat public/js/jquery.js \
		public/js/openlayers/build/openlayers.full.js \
		public/js/bodo.js \
		public/js/bootstrap.js >/tmp/bodo-script.tmp.js
	$(YUI_COMPRESSOR) -o $(COMPILED_JS_DIR)/script.js /tmp/bodo-script.tmp.js
	rm -f /tmp/bodo-script.tmp.js
	rm -f public/js/openlayers/build/openlayers.full.js

css: css-bodo

css-dir:
	# create the diretory if it does not exist
	[ -d $(COMPILED_CSS_DIR) ] || mkdir $(COMPILED_CSS_DIR)

css-bodo: css-dir
	rm -f $(COMPILED_CSS_DIR)/style.css
	cat public/css/bootstrap.css \
            public/css/bodo.css \
            public/css/openlayers.css >/tmp/css.tmp.css
	$(YUI_COMPRESSOR) -o $(COMPILED_CSS_DIR)/style.css /tmp/css.tmp.css
	rm -f /tmp/css.tmp.css
