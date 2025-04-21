JL = julia --project

default: init test

init:
	$(JL) -e 'using Pkg; Pkg.activate(".."); Pkg.update()'

update:
	git pull
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

ksg:
	$(JL) -e 'include("gen_mis.jl"); gen_ksg_and_save(32)'

regular3:
	$(JL) -e 'include("gen_mis.jl"); gen_regular3_and_save(1000)'

renyi:
	$(JL) -e 'include("gen_mis.jl"); gen_renyi_and_save(1000, 0.005)'

ob:
	$(JL) -e 'include("gen_ob.jl"); gen_ob_and_save($n, $(nstrings), 1000, 0.0)'

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init update
