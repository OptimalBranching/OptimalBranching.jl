JL = julia --project

default: init test

init:
	$(JL) -e 'using Pkg; Pkg.activate("lib/OptimalBranchingMIS"); Pkg.develop(path="./lib/OptimalBranchingCore"); Pkg.update()'
	$(JL) -e 'using Pkg; Pkg.develop([Pkg.PackageSpec(path = joinpath("lib", pkg)) for pkg in ["OptimalBranchingMIS"]]); Pkg.precompile()'

update:
	$(JL) -e 'using Pkg; Pkg.update(); Pkg.precompile()'

test:
	$(JL) -e 'using Pkg; Pkg.test(["OptimalBranching", "OptimalBranchingCore", "OptimalBranchingMIS"])'

coverage:
	$(JL) -e 'using Pkg; Pkg.test(["OptimalBranching", "OptimalBranchingCore", "OptimalBranchingMIS"]; coverage=true)'

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test
