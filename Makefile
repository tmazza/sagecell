sage-root := $(shell [ -n "$$SAGE_ROOT" ] && echo "$$SAGE_ROOT" || sage --root || echo "\$$SAGE_ROOT")
all-min-js = static/embedded_sagecell.js

sagecell-css = static/sagecell.css
all-min-css = build/all.min.css
embed-css = static/sagecell_embed.css

tos-default = templates/tos_default.html
tos = templates/tos.html
tos-static = static/tos.html

all: submodules $(all-min-js) $(all-min-css) $(embed-css) $(tos-static)

.PHONY: submodules $(tos-static)

submodules:
	if git submodule status | grep -q ^[+-]; then git submodule update --init > /dev/null; fi

build:
	-rm -r build
	cp -a $(sage-root)/local/lib/python3.8/site-packages/notebook/static build
	cp static/colorpicker/js/colorpicker.js build
	ln -sfn $(sage-root)/local/share/jupyter/nbextensions/jupyter_jsmol/jsmol static/jsmol
	ln -sfn $(sage-root)/local/share/threejs-sage/r122 static/threejs
	ln -sf $(sage-root)/local/share/jmol/appletweb/SageMenu.mnu static/SageMenu.mnu
	cp static/jsmol/JSmol.min.nojq.js build/JSmol.js
	wget -P build \
		https://raw.githubusercontent.com/sockjs/sockjs-client/master/dist/sockjs.js \
		https://raw.githubusercontent.com/requirejs/domReady/latest/domReady.js \
		https://raw.githubusercontent.com/requirejs/text/latest/text.js
	python3 -c "from matplotlib.backends.backend_webagg_core import FigureManagerWebAgg; f = open('build/mpl.js', 'w'); f.write(FigureManagerWebAgg.get_javascript())"

$(all-min-js): build $(all-min-css) js/*
	# Host standalone jquery for compatibility with old instructions
	cp build/components/jquery/jquery.min.js static
	cp submodules/jquery-ui-touch-punch/jquery.ui.touch-punch.min.js build/jquery-ui-tp.js
	cp -a js/* build
	cd build && r.js -o build.js
	cp build/main_build.js $(all-min-js)

$(all-min-css): build $(sagecell-css)
	cp -a build/components/jquery-ui/themes/smoothness/* static
	r.js -o cssIn=static/main.css out=$(all-min-css)

$(embed-css): $(sagecell-css)
	sed -e 's/;/ !important;/g' < $(sagecell-css) > $(embed-css)

$(tos-static): $(tos-default)
	@[ -e $(tos) ] && cp $(tos) $(tos-static) || cp $(tos-default) $(tos-static)
