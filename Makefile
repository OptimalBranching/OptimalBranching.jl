JL = julia --project

default: init test

init:
	$(JL) -e 'using Pkg; Pkg.activate("lib/OptimalBranchingMIS"); Pkg.develop(path="./lib/OptimalBranchingCore"); Pkg.update()'
	$(JL) -e 'using Pkg; Pkg.develop([Pkg.PackageSpec(path = joinpath("lib", pkg)) for pkg in ["OptimalBranchingCore", "OptimalBranchingMIS"]]); Pkg.precompile()'

update:
	git pull
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

test:
	$(JL) -e 'using Pkg; Pkg.test(["OptimalBranching", "OptimalBranchingCore", "OptimalBranchingMIS"])'

coverage:
	$(JL) -e 'using Pkg; Pkg.test(["OptimalBranching", "OptimalBranchingCore", "OptimalBranchingMIS"]; coverage=true)'

init-docs:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); Pkg.develop([Pkg.PackageSpec(path = "."), [Pkg.PackageSpec(path = joinpath("lib", pkg)) for pkg in ["OptimalBranchingCore", "OptimalBranchingMIS"]]...]); Pkg.precompile()'

serve:
	$(JL) -e 'using Pkg; Pkg.activate("docs"); using LiveServer; servedocs(;skip_dirs=["docs/src/assets", "docs/src/generated"], literate_dir="examples")'

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test
